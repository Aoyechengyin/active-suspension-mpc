# Road3 Q_C energy gate结果分析 20260607

## 数据说明

用户确认本轮 `ROAD3_T2_COMFORT_GATE_UV_POS/UV_NEG` 是在 `ROAD3_Q_COMFORT_C` 离线数据下仿真的。CSV 路径虽然位于 `Output/Road-3/Q_comfort_A/...`，但本记录按 `Q_C + gate` 解释。

- Q_C: `Output/Road-3/Q_comfort_C/2026-06-07_22.13.33.csv`
- Q_C + UV_POS: `Output/Road-3/Q_comfort_A/ROAD3_T2_COMFORT_GATE_UV_POS/2026-06-07_22.27.11.csv`
- Q_C + UV_NEG: `Output/Road-3/Q_comfort_A/ROAD3_T2_COMFORT_GATE_UV_NEG/2026-06-07_22.32.02.csv`
- Report: `Output/Road-3/Q_comfort_A/gate_uv_pos_neg_passive_gap.md`

## Passive gap

负值表示优于 Passive。

| Case | Az event gap | Az 0-4 gap | Az 0-15 gap | AA_P 0-15 gap | Heave gap | Pitch gap | Front Jnc gap | Rear Jnc gap |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Q_C | -0.010851 | -0.041557 | -0.010934 | +0.007203 | +0.000379 | +0.194227 | +0.061782 | -12.010118 |
| Q_C + UV_POS | +0.050564 | -0.030472 | +0.051047 | +0.005657 | +0.000042 | +0.119102 | -0.209759 | -9.001776 |
| Q_C + UV_NEG | +0.199238 | +0.291270 | +0.201231 | -0.054323 | +0.006522 | -0.085908 | -11.162170 | -1.732265 |

## Absolute metrics

| Case | Az event | Az 0-4 | Az 0-15 | AA_P 0-15 | Heave | Pitch | Front Jnc min | Rear Jnc min |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Passive | 1.114713 | 0.634054 | 1.107427 | 1.162193 | 0.022083 | 1.230976 | -36.975142 | -14.108398 |
| Q_C | 1.103862 | 0.592498 | 1.096494 | 1.169396 | 0.022463 | 1.425203 | -36.913360 | -26.118516 |
| Q_C + UV_POS | 1.165277 | 0.603582 | 1.158475 | 1.167850 | 0.022126 | 1.350078 | -37.184901 | -23.110174 |
| Q_C + UV_NEG | 1.313951 | 0.925324 | 1.308658 | 1.107870 | 0.028606 | 1.145068 | -48.137311 | -15.840663 |

## Force and stop checks

| Case | Max FsExt abs | Front sat @1000 | Rear sat @650 | FJSt peak | FRSt peak | Rear L-R peak | Front L-R peak |
|---|---:|---:|---:|---:|---:|---:|---:|
| Passive | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Q_C | 649.998 | 0 | 0.008266 | 0 | 0 | 22.665 | 0 |
| Q_C + UV_POS | 997.389 | 0 | 0.000533 | 0 | 0 | 11.650 | 170.689 |
| Q_C + UV_NEG | 999.984 | 0.004200 | 0.004066 | 0 | 0 | 26.323 | 58.457 |

## 判断

- `UV_POS` 是两个 gate 中更接近目标的方向：
  - 继续保留 `Az 0-4` 优于 Passive。
  - heave 几乎贴近 Passive，仅高约 `0.000042 m`。
  - pitch gap 从 Q_C 的 `+0.194 deg` 降到 `+0.119 deg`。
  - rear jounce gap 从 `-12.01 mm` 改善到 `-9.00 mm`。
  - rear saturation 从 `0.8266%` 降到 `0.0533%`。
- `UV_POS` 的代价：
  - `Az event` 和 `Az 0-15` 已经变差到高于 Passive。
  - front jounce 从略优于 Passive 转为略差于 Passive，差值约 `-0.21 mm`，幅度很小。
- `UV_NEG` 不适合作为主线：
  - pitch 和 AA_P 改善，但 `Az 0-4 / Az 0-15 / heave / front jounce` 明显恶化。
  - 引入 front saturation 约 `0.42%`。

## 下一步

当前已经完成计划中的轴向隔离、Q comfort、energy gate 三阶段。没有任何组合同时满足全部小于 Passive。

若仍要继续逼近，建议只沿 `Q_C + UV_POS` 做小范围输出层微调：

1. 保留 `UV_POS` 方向。
2. 进一步降低前轴参与，避免 `Az event/0-15` 被前轴动作抬高。
3. 将目标从“全指标同时压过 Passive”改成“Q_C + UV_POS 作为折中最优：低频 Az、heave、pitch、rear travel 相对 Q_C 明显改善，但 Az event/0-15 未达 Passive”。

若严格按原停止条件，则应停止继续调参并写结论：当前车辆模型和执行器约束下 Passive 是 T2 pilot 的强基线，active 只能改善部分指标。
