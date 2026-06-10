# Road3 Q comfort A/B/C重跑结果分析 20260607

## 数据

- Passive: `Output/Road-3/T2_passive/2026-06-06_21.18.39.csv`
- Rear only tight: `Output/Road-3/T2_Rear_Only_Tight/2026-06-07_21.06.37.csv`
- Q comfort A: `Output/Road-3/Q_comfort_A/2026-06-07_21.59.19.csv`
- Q comfort B: `Output/Road-3/Q_comfort_B/2026-06-07_22.11.19.csv`
- Q comfort C: `Output/Road-3/Q_comfort_C/2026-06-07_22.13.33.csv`
- Report: `Output/Road-3/Q_comfort_ABC/q_comfort_abc_rerun_passive_gap.md`

本轮 CSV hash 已不同，A/B/C 结果有效。

## Passive gap

负值表示优于 Passive。

| Case | Az event gap | Az 0-4 gap | Az 0-15 gap | AA_P 0-15 gap | Heave gap | Pitch gap | Front Jnc gap | Rear Jnc gap |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Rear only tight | -0.018036 | -0.045892 | -0.017851 | +0.018566 | +0.000447 | +0.245787 | +0.090145 | -13.150941 |
| Q comfort A | -0.012414 | -0.042542 | -0.012279 | +0.015454 | +0.000483 | +0.229309 | +0.087133 | -12.790678 |
| Q comfort B | -0.011451 | -0.036862 | -0.011399 | +0.011542 | +0.000430 | +0.214278 | +0.073612 | -12.456349 |
| Q comfort C | -0.010851 | -0.041557 | -0.010934 | +0.007203 | +0.000379 | +0.194227 | +0.061782 | -12.010118 |

## Absolute metrics

| Case | Az event | Az 0-4 | Az 0-15 | AA_P 0-15 | Heave | Pitch | Front Jnc min | Rear Jnc min |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Passive | 1.114713 | 0.634054 | 1.107427 | 1.162193 | 0.022083 | 1.230976 | -36.975142 | -14.108398 |
| Rear only tight | 1.096677 | 0.588162 | 1.089576 | 1.180759 | 0.022530 | 1.476763 | -36.884997 | -27.259340 |
| Q comfort A | 1.102299 | 0.591512 | 1.095149 | 1.177647 | 0.022567 | 1.460285 | -36.888009 | -26.899077 |
| Q comfort B | 1.103261 | 0.597192 | 1.096028 | 1.173735 | 0.022513 | 1.445254 | -36.901530 | -26.564747 |
| Q comfort C | 1.103862 | 0.592498 | 1.096494 | 1.169396 | 0.022463 | 1.425203 | -36.913360 | -26.118516 |

## Force and stop checks

| Case | Max FsExt abs | Front sat @1000 | Rear sat @650 | FJSt peak | FRSt peak | Rear L-R peak | Front L-R peak |
|---|---:|---:|---:|---:|---:|---:|---:|
| Passive | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Rear only tight | 649.999504 | 0 | 0.010199 | 0 | 0 | 14.910 | 0 |
| Q comfort A | 649.999246 | 0 | 0.009599 | 0 | 0 | 14.147 | 0 |
| Q comfort B | 649.998816 | 0 | 0.008999 | 0 | 0 | 20.808 | 0 |
| Q comfort C | 649.997915 | 0 | 0.008266 | 0 | 0 | 22.665 | 0 |

## 判断

- 三个 comfort profile 都保持 `Az event / 0-4 / 0-15` 优于 Passive。
- `Q comfort C` 对 pitch、AA_P、heave、front/rear jounce、rear saturation 的综合改善最好。
- 但 `Q comfort C` 仍未达到全方位超过 Passive：
  - pitch peak 仍比 Passive 高约 `0.194 deg`。
  - rear jounce min 仍比 Passive 更负约 `12.01 mm`。
  - heave peak 仍略高约 `0.00038 m`。
  - AA_P 0-15 仍略高约 `0.0072`。
- `FJSt/FRSt peak = 0`，说明当前还不是硬止块力问题，而是后轴回弹行程和低频姿态问题。

## 下一步

按原调试计划，comfort profile 中最佳仍未压过 Passive 的 `Az/heave/pitch`，应进入 energy gate 阶段。

建议使用 `ROAD3_Q_COMFORT_C` 的离线数据作为激活 profile，然后分别跑：

1. `ROAD3_T2_COMFORT_GATE_UV_POS`
2. `ROAD3_T2_COMFORT_GATE_UV_NEG`

目标是保留 Q_C 的低频 Az 优势，同时削弱后段回弹时的 pitch/heave 能量注入。
