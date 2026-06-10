# Road-3 Pilot Preview 结果分析记录

> 2026-06-06 更新：后续补跑的 `Output/Road-3/T2_pilot_preview/2026-06-06_21.45.00.csv` 已加入 `FJSt_*` 和 `FRSt_*`。该 preview 结果与旧 preview 动力学指标一致，但止块力全为 `0 N`。因此本文早先“preview 已触发前悬回弹止块”的表述应修正为：preview/no-preview 均导致前悬回弹动挠度显著增大，`Jnc_L1/R1` 到约 `-73.6 mm`，但当前 CarSim stop-force 输出未确认止块力介入。新的三组决策记录见 `日志/Road3_T2三组对比与悬架行程决策_20260606.md`。

生成日期：2026-06-06

## 数据来源

- T1 pilot preview：`Output/Road-3/T1_pilot_preview/2026-06-06_20.19.19.csv`
- T2 pilot preview：`Output/Road-3/T2_pilot_preview/2026-06-06_20.31.27.csv`
- 详细统计报告：`Output/Road-3/pilot_preview_compare.md`
- 统计 JSON：`Output/Road-3/pilot_preview_compare_fallback.json`

命令行 MATLAB 仍在启动阶段报 `File system inconsistency`，因此本次由 Python fallback 直接读取 CarSim 原始 CSV 统计。该问题不是 `AnalyzeRoadAcceptance_2020.m` 或 `AnalyzeRoad3BumpExperiment_2020.m` 的脚本错误。

## 关键结论

1. T1 pilot preview 这次不是有效的论文 Test 1 pilot：
   - 计划速度：30 km/h。
   - CSV 实际速度：`Vx mean=49.96 km/h`，`VxTarget=50 km/h`。
   - 这次只能作为“10 mm / 0.4 m 短凸包在 50 km/h 下的稳定性检查”。

2. T2 pilot preview 的速度正确，但不满足严格 pilot 门槛：
   - 计划速度：50 km/h。
   - CSV 实际速度：`Vx mean=49.96 km/h`。
   - `W1/W2` 预瞄提前量正确，平均分别约 `10 ms / 20 ms`。
   - 50 mm 长凸包已经引起外力限幅，最大限幅比例 `4.193%`，超过 pilot 计划的 `<1%`。

3. T2 不是左右不对称或高频限幅振荡问题：
   - 后轴左右外力差峰值约 `62.07 N`，远低于 `1000 N`。
   - 主导频率约 `2.3-2.6 Hz`，不是之前担心的 `15-20 Hz` 限幅振荡。
   - 车轮转角 `Rot_*` 连续增加，车辆动力学没有卡死。

4. T2 preview 已经触发前悬回弹止块，但 T2 passive 没有触发：
   - 当前前悬止块设置为 `+70 mm / -50 mm`。
   - T2 pilot preview 中 `Jnc_L1/R1` 最小约 `-73.60 / -73.58 mm`，已经越过前悬回弹止块约 `23.6 mm`。
   - 后悬止块为 `+120 mm / -60 mm`，T2 中 `Jnc_L2/R2` 最小约 `-51.40 / -51.34 mm`，距离后悬回弹止块仍有约 `8.6 mm` 余量。
   - T2 passive 中 `Jnc_L1/R1` 最小约 `-36.98 / -36.86 mm`，仍距离前悬回弹止块约 `13 mm`；`FJSt_*` 和 `FRSt_*` 全为 `0 N`。
   - 因此 50 mm 路面本身不会必然触发止块；更直接的嫌疑是 preview eMPC 外力把前悬推入回弹止块非线性区。

## 主要指标

| 工况 | 速度 | Road peak | Az_SM event peak | Az_SM event RMS | FsExt 最大限幅比例 | 后轴左右差峰值 | 预瞄提前量 |
|---|---:|---:|---:|---:|---:|---:|---:|
| T1 pilot preview | 49.96 km/h | 0.010 m | 0.3405 g | 0.0524 g | 0.2267% | 6.88 N | W1 10 ms / W2 20 ms |
| T2 pilot preview | 49.96 km/h | 0.050 m | 1.0510 g | 0.1558 g | 4.1931% | 62.07 N | W1 10 ms / W2 20 ms |

T2 限幅持续情况：

- `FsExt_L1/R1`：各 629 个 1 ms 样本限幅，最长连续约 `212-213 ms`。
- `FsExt_L2/R2`：约 458-459 个 1 ms 样本限幅，最长连续约 `195-196 ms`。

## 悬架行程止块检查

本次按你提供的 CarSim 设置截图取止块阈值：

- 前悬：压缩 `+70 mm`，回弹 `-50 mm`。
- 后悬：压缩 `+120 mm`，回弹 `-60 mm`。

| 工况 | 车轮 | Jnc 最小值 | Jnc 最大值 | 压缩余量 | 回弹余量 | 判断 |
|---|---|---:|---:|---:|---:|---|
| T1 pilot preview | L1/R1 前轮 | -3.73 / -3.69 mm | 2.01 / 2.05 mm | 约 68 mm | 约 46 mm | 远离止块 |
| T1 pilot preview | L2/R2 后轮 | -2.62 / -2.55 mm | 3.71 / 3.79 mm | 约 116 mm | 约 57 mm | 远离止块 |
| T2 pilot preview | L1/R1 前轮 | -73.60 / -73.58 mm | 51.50 / 51.70 mm | 约 18 mm | 约 -24 mm | 前悬回弹止块已越界 |
| T2 pilot preview | L2/R2 后轮 | -51.40 / -51.34 mm | 56.44 / 56.47 mm | 约 64 mm | 约 9 mm | 接近后悬回弹止块但未越界 |
| T2 passive | L1/R1 前轮 | -36.98 / -36.86 mm | 39.75 / 39.85 mm | 约 30 mm | 约 13 mm | 未触止块 |
| T2 passive | L2/R2 后轮 | -14.11 / -13.99 mm | 30.69 / 30.84 mm | 约 89 mm | 约 46 mm | 未触止块 |

这会影响控制效果，原因是当前 eMPC 的 mp-QP 模型是线性的，没有包含 jounce/rebound stop 的非线性约束和止块力函数。现在 passive 已确认不触止块，而 preview 触止块，所以优先怀疑主动外力策略把前悬拉入回弹止块，而不是单纯路面高度过大。

T2 passive CSV 已导出 `FJSt_*` 和 `FRSt_*`，全程为 `0 N`；T2 preview CSV 没有导出这些变量，所以 preview 的止块介入仍由 `Jnc_*` 位移越界推断。下一轮 eMPC CSV 必须保留：

- `FJSt_L1, FJSt_R1, FJSt_L2, FJSt_R2`
- `FRSt_L1, FRSt_R1, FRSt_L2, FRSt_R2`
- 可选：`VJStL1/VJStR1/VJStL2/VJStR2`、`VRStL1/VRStR1/VRStL2/VRStR2`

## 下一步建议

1. 先重跑 T1 pilot preview：
   - CarSim Constant target speed 改为 `30 km/h`。
   - 路面仍用 `Road3_T1_short_10mm_pilot_210m_0p02m.csv`。
   - VS Command 仍用 preview 版本。

2. T2 不建议马上上 `150 mm` full：
   - Passive 已完成，确认没有止块力。
   - 继续补 T2 50 mm pilot 的 `eMPC no-preview`，并追加止块力输出。
   - 如果 no-preview 不触发前悬回弹止块而 preview 触发，优先排查预瞄路面状态填充和前轴力时序。
   - 如果 no-preview 和 preview 都触发前悬回弹止块，再考虑 Road-3 专用控制参数，例如前轴限幅、前轴控制权重、或对前悬回弹行程加软约束。
   - 不建议现在直接改 CarSim 前悬行程，因为 passive 已说明车辆参数本身能通过 50 mm pilot。

3. full 工况仍按三组输出：
   - `Passive`
   - `eMPC no-preview`
   - `eMPC preview`

4. 每次切换模式后继续清除 persistent：

```matlab
clear per_corner_mpc_L1_2020 per_corner_mpc_R1_2020 ...
      per_corner_mpc_L2_2020 per_corner_mpc_R2_2020 ...
      per_corner_mpc_state_step_2020
```
