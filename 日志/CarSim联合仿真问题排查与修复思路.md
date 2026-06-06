# CarSim 联合仿真问题排查与修复思路

> 日期: 2026-05-21
> 状态: 方案评估完成，待实施

## 问题描述

CarSim + Simulink 联合仿真跑通后，效果很差：
- **车轮跳震** (wheel hop) 非常严重
- **车身纵向偏移** (pitch oscillation)，车头持续俯仰

## 根因分析

### 根因 1: 俯仰修正缺失 (最关键)

四轮独立 MPC 控制器共用同一个 CG 处的 Vz_SM 和 Az_SM，忽略了俯仰运动。

**影响**:
- 前轮实际垂向速度 ≈ Vz_CG + a × pitch_rate
- 后轮实际垂向速度 ≈ Vz_CG - b × pitch_rate
- 忽略俯仰后，前后轮控制力不匹配，产生破坏性的俯仰力矩 → 纵向持续振荡

**修正方案**:
```
v_z,front = Vz_SM + a × q
v_z,rear  = Vz_SM - b × q

其中: a = 1.18m (前轴到CG距离)
      b = 1.77m (CG到后轴距离)
      q = pitch_rate (俯仰角速率, 由 CarSim Pitch 输出微分+低通滤波得到)
```

**俯仰角速率获取方式**:
- 方案A: Simulink 中对 Pitch 信号做微分 + 低通滤波 (fc≈5Hz)
- 方案B: CarSim 中新增 `DEFINE_OUTPUT` 直接输出俯仰角速率

### 根因 2: 绝对位移积分漂移

`per_corner_mpc.m` 中 `x1 = x1 + vel * dt` 纯积分会漂移。

**影响**:
- x1 漂移 → 轮胎变形估计 x2-w0 = x1 - (x1-x2) - w0 也漂移
- 控制器误判轮胎变形过大 → 输出饱和控制力 (±9000N) → 引发车轮跳震

**修正方案: 互补滤波器**:
```
x1(k) = α·(x1(k-1) + v_z·dt) + (1-α)·(susp_defl + road_now)

其中: α = 0.98 (高频积分 + 低频路面高程参考)
      susp_defl = 悬架压缩量 (CarSim 实测)
      road_now = 当前路面高程 (CarSim 实测)
```

### 根因 3: 状态估计器滤波器 Bug

`carsim_state_estimator.m` 中:
- 高通滤波: `acc_filt = (1 - 0.9937) * acc_body = 0.0063 * acc_body` (衰减 160 倍)
- 低通滤波: `susp_vel = alpha_lp * susp_vel + 0` (衰减 23 倍)

**注意**: 如果 `per_corner_mpc.m` 直接从 CarSim 获取 Vz_SM，则此 Bug 只影响 `carsim_state_estimator.m` 的独立模式。

**修正方案**:
- 速度: 泄漏积分器 `vel_est = α·vel_est_prev + acc_body·dt`
- 悬架速度: 标准低通 `susp_vel_filt = α·susp_vel_filt_prev + (1-α)·susp_vel_raw`

## 修改优先级

| 优先级 | 修复项 | 影响 | 难度 |
|--------|--------|------|------|
| P0 | 俯仰修正 | 消除纵向振荡 | 中 |
| P1 | 互补滤波器消除位移漂移 | 消除车轮跳震 | 低 |
| P2 | 状态估计器滤波器修复 | 提高状态精度 | 低 |

## CarSim 几何参数 (CPAR 提取)

| 参数 | 符号 | 值 | 说明 |
|------|------|-----|------|
| 轴距 | L | 2.95 m | 前后轴距离 |
| 前轴到CG距离 | a | 1.18 m | |
| 后轴到CG距离 | b | 1.77 m | b = L - a |

## 需要注意的细节

1. **CarSim 没有直接输出 Pitch_Rate**，只有 `Pitch` (角度)。需要微分处理
2. **互补滤波中 susp_defl + road_now ≈ x1 - (x2-w0)**，轮胎变形偏置约 1-3mm，可忽略
3. **权重可沿用已有调参**: rho1=500, rho2=1e5, rho3=10, rho4=1e5, rho5=1e-7 (验证过 acc -60%)
4. **dt 必须 = 0.01s**，所有离线矩阵基于此步长

## 下一步

- [ ] 在 `./gemini` 目录中按方案实施改进
- [ ] MATLAB 闭环仿真验证 (不含 CarSim)
- [ ] CarSim + Simulink 联合仿真验证
