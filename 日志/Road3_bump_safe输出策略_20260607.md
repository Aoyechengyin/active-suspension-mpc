# Road-3 bump-safe 输出策略 2026-06-07

## 目的

`rho5_front=1e-4, rho5_rear=3e-4` 的 T2 pilot 结果显示：

- 左右外力差显著下降；
- 但 `Az_SM` RMS 明显恶化；
- 前后悬行程几乎没有改善；
- `FJSt/FRSt` 仍为 `0 N`，暂不支持先改 CarSim 悬架行程限。

因此本轮停止继续单纯增大 `rho5`，改为 Road-3 专用输出策略。

## 当前策略

新增控制模式：

```text
ROAD3_BUMP_SAFE
front limit = 1000 N
rear  limit = 650 N
```

并在四角 wrapper 的最终输出处增加后处理：

- 软模式硬限幅：前轴 `1200 N`，后轴 `800 N`
- 变化率限制：前轴 `20000 N/s`，后轴 `12000 N/s`
- 一阶平滑：前轴 `tau=0.015 s`，后轴 `tau=0.020 s`

此策略不改变：

- CarSim 车辆模型；
- Simulink Mux/Demux 接口；
- VS Command 预瞄表达式；
- 离线 QP 数据格式。

## 激活状态

`empc_calibration_settings_2020.m` 的默认模式已临时切换为：

```matlab
default_mode = 'ROAD3_BUMP_SAFE';
```

显式调用 `B3_CONSERVATIVE` 仍保持：

```text
front 3000 N
rear  2000 N
```

失败的 `ROAD3_SOFT_F1E4_R3E4` 已从 root active 资产中回退。当前 `src_2020` root 的离线 MPC 资产验证为：

```text
profile = ROAD3_SOFT_F1E5_R1E4
front rho5 = 1e-5
rear  rho5 = 1e-4
```

## persistent 清理

每次切换模式或重新运行 Road-3 pilot 前，仍需执行：

```matlab
clear per_corner_mpc_L1_2020 per_corner_mpc_R1_2020 ...
      per_corner_mpc_L2_2020 per_corner_mpc_R2_2020 ...
      per_corner_mpc_state_step_2020
```

## 下一轮建议

先只跑：

```text
Output/Road-3/bump_safe/T2_pilot_preview/
```

验收重点：

- `Az_SM` 不应继续高于 B3 preview；
- event saturation 应明显低于 `13%`；
- front/rear `Jnc` 不应比 B3 更差；
- `FJSt/FRSt` 继续确认是否为 `0 N`；
- 如果仍不如 Passive，则 Road-3 T2 应暂时以 Passive 作为论文复现实验基线。

## T2 pilot 初次结果

初次结果文件：

```text
Output/Road-3/bump_safe/T2_pilot_preview/2026-06-07_02.22.00.csv
```

结果判断：

- 比 B3 preview 明显改善；
- 比两版 rho5 soft profile 明显改善；
- 仍未完全优于 Passive；
- 按 bump-safe 自身 `1200/800 N` 软限幅统计，event 饱和仍为 `3.91%`，full 饱和为 `1.01%`。

详细分析见：

```text
日志/Road3_bump_safe_T2pilot结果分析_20260607.md
```

## 验证记录

已运行：

```matlab
addpath('src_2020');
test_calibration_tools_2020;
test_road3_tools_2020;
self_check_2020;
```

结果：

```text
test_calibration_tools_2020 passed.
test_road3_tools_2020 passed.
self_check_2020 passed structural checks.
```

四角 wrapper 烟测：

```text
per_corner_mpc_L1_2020 = 0
per_corner_mpc_R1_2020 = 0
per_corner_mpc_L2_2020 = 0
per_corner_mpc_R2_2020 = 0
```

## Second-stage tightening 2026-06-07

The first bump-safe T2 pilot result still touched the soft limits. The active default `ROAD3_BUMP_SAFE` parameters have now been tightened for the next run:

```text
front limit = 1000 N
rear  limit = 650 N
front rate limit = 15000 N/s
rear  rate limit = 9000 N/s
```

Use this output directory for the next validation run:

```text
Output/Road-3/bump_safe_tight/T2_pilot_preview/
```

## Tight result 2026-06-07

Tight validation result:

```text
Output/Road-3/bump_safe_tight/T2_pilot_preview/2026-06-07_19.48.05.csv
```

Report:

```text
Output/Road-3/bump_safe_tight/T2_pilot_preview/bump_safe_tight_compare.md
日志/Road3_bump_safe_tight_T2pilot结果分析_20260607.md
```

Decision:

```text
Keep ROAD3_BUMP_SAFE at front=1000 N, rear=650 N.
Do not tighten force limits further.
Use this profile as the conservative active Road-3 profile.
```

零输入输出为有限值，且满足 Road-3 bump-safe 软限幅。
