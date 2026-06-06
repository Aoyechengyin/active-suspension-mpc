# 平路 eMPC 车身姿态校正 v3 执行说明

## 当前结论

- `FsExt_*` 是 Simulink/eMPC 送入 CarSim 的外部悬架力，后续用它判断控制力、饱和和左右差。
- `Fs_*` 是 CarSim 内置悬架弹簧力，只作为车辆悬架响应参考，不再当作 eMPC 实际输入力。
- 当前接口保持不变：
  - CarSim Import: `[IMP_FS_L1, IMP_FS_L2, IMP_FS_R1, IMP_FS_R2]`
  - Simulink Mux: `[L1, L2, R1, R2]`
- 诊断脚本按 CSV 列名读取，不要求 CSV 列顺序。

## 代码开关

校准模式集中在 `src_2020/empc_calibration_settings_2020.m`：

```matlab
default_mode = 'B2_REAR_LOW';
```

每次只改这一行，然后重新运行 Simulink/CarSim 联合仿真。

切换模式后，建议在 MATLAB 命令行执行一次：

```matlab
clear per_corner_mpc_L1_2020 per_corner_mpc_R1_2020 per_corner_mpc_L2_2020 per_corner_mpc_R2_2020 empc_calibration_settings_2020
```

这样可以避免四个控制器 wrapper 的 `persistent` 初始化状态沿用上一轮仿真。

可选模式：

| 模式 | 前轴 | 后轴 | 用途 |
|---|---:|---:|---|
| `FULL_CURRENT` | 9000 N | 9000 N | 复现原始 MPC 异常，不建议作为下一步默认 |
| `B1_FRONT_ONLY` | 9000 N | 0 N | 验证后轴是否为主因 |
| `B2_REAR_LOW` | 0 N | 1000 N | 验证后轴低限幅和当前力方向 |
| `B2_REAR_LOW_REV` | 0 N | 1000 N，反号 | 若 B2 仍明显振荡，用于验证后轴力方向 |
| `B3_CONSERVATIVE` | 3000 N | 2000 N | 方向确认后的保守全车 MPC |

## 推荐顺序

1. Case B1: `B1_FRONT_ONLY`
   - 目标：如果姿态接近 CaseA，说明异常主要来自后轴控制。

2. Case B2: `B2_REAR_LOW`
   - 目标：后轴只给 `1000 N` 限幅，观察是否还激发明显 `Az_SM/JncR/Roll`。
   - 当前代码默认模式已经切到这一项。

3. Case B2-rev: `B2_REAR_LOW_REV`
   - 只在 B2 仍振荡时运行。
   - 目标：判断后轴外力方向是否需要反号。

4. Case B3: `B3_CONSERVATIVE`
   - 目标：确认前后轴同时启用时不再出现后轴长期饱和和左右反向力。

5. Case B4: 重生成 rear QP
   - 若 B3 后轴饱和仍超过 5%，将 `config_2020.m` 中 `cfg.rho5_rear` 从 `cfg.rho5` 改为 `1e-4` 后重新运行 Step1/Step2/Step3。
   - 若仍超过 5%，再试 `1e-3`。

6. Case B5: 后轴差动力限制
   - 仅当 B4 后 `FsExt_L2 - FsExt_R2` 仍明显过大时使用。
   - 已提供无状态函数 `src_2020/rear_diff_limiter_2020.m`：

```matlab
[u_L2, u_R2] = rear_diff_limiter_2020(u_L2_raw, u_R2_raw, 500);
```

   - 它限制 `abs((u_L2-u_R2)/2) <= 500 N`，同时保留后轴平均力。
   - 目前没有自动接入 `untitled_2020.slx`；需要 B5 时，应在 Simulink 后轴两路输出汇合到 Mux 前插入，避免把跨角状态放进 per-corner 控制器。

## CSV 必需诊断变量

```text
Time
Pitch
Roll
Yaw
Xo
Yo
Vx 或 Vxz_Fwd
Steer_SW
Az_SM
Vz_SM
Ay_SM
FsExt_L1
FsExt_R1
FsExt_L2
FsExt_R2
Fs_L1
Fs_R1
Fs_L2
Fs_R2
Jnc_L1
Jnc_R1
Jnc_L2
Jnc_R2
JncR_L1
JncR_R1
JncR_L2
JncR_R2
Zgnd_L1
Zgnd_R1
Zgnd_L2
Zgnd_R2
Rot_L1
Rot_R1
Rot_L2
Rot_R2
```

## 分析命令

```matlab
addpath('src_2020');
AnalyzeFlatPose_2020({ ...
    'Output/平直零力/2026-06-05_21.33.39.csv', ...
    'Output/平直_MPC/20260605.csv' ...
}, 'Output/flat_pose_report_compare.md');
```

脚本会输出：

- `FsExt_*` 总饱和比例和单轮饱和比例。
- 前/后轴 `FsExt` 左右差均值和峰值。
- `Az_SM` 峰值。
- 后轴 `JncR_*` 峰值。
- `Rot_*` 全程增量。
- `Zgnd_*` 平路高度峰值。
- `Steer_SW` 是否保持零。

## 平路验收口径

- `max(abs(Zgnd_*)) < 1e-6 m`
- `Steer_SW = 0`
- 四角 `FsExt_*` 饱和比例 `< 1%`
- 后轴 `FsExt_L2 - FsExt_R2` 峰值 `< 1000 N`
- `Roll` final mean `< 0.02 deg`
- `Yaw` 终值或 final mean 相对 CaseA 不明显恶化
- `Yo` 相对 CaseA 增量 `< 0.1 m`
- `Az_SM` 峰值 `< 0.05 g`
- 后轴 `JncR_*` 峰值 `< 50 mm/s`
- `Rot_*` 均连续增加
