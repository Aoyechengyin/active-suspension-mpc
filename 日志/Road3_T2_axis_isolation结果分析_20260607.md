# Road3 T2 axis isolation结果分析 20260607

## 数据

- Passive: `Output/Road-3/T2_passive/2026-06-06_21.18.39.csv`
- Both tight: `Output/Road-3/bump_safe_tight/T2_pilot_preview/2026-06-07_19.48.05.csv`
- Front only tight: `Output/Road-3/T2_Front_Only_Tight/2026-06-07_21.03.50.csv`
- Rear only tight: `Output/Road-3/T2_Rear_Only_Tight/2026-06-07_21.06.37.csv`
- Passive gap report: `Output/Road-3/axis_isolation_tight/t2_axis_isolation_passive_gap.md`

## Passive gap

负值表示优于 Passive，正值表示劣于 Passive。

| Case | Az event gap | Az 0-4 gap | Az 0-15 gap | AA_P 0-15 gap | Heave gap | Pitch gap | Front Jnc min gap | Rear Jnc min gap |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Both tight | +0.219618 | +0.278032 | +0.221518 | -0.046462 | +0.006838 | +0.118999 | -10.662916 | -13.950743 |
| Front only tight | +0.257108 | +0.335184 | +0.259119 | -0.075665 | +0.005684 | -0.154663 | -10.765303 | -0.584363 |
| Rear only tight | -0.018036 | -0.045892 | -0.017851 | +0.018566 | +0.000447 | +0.245787 | +0.090145 | -13.150941 |

## Absolute metrics

| Case | Az event | Az 0-4 | Az 0-15 | AA_P 0-15 | Heave | Pitch | Front Jnc min | Rear Jnc min |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Passive | 1.114713 | 0.634054 | 1.107427 | 1.162193 | 0.022083 | 1.230976 | -36.975142 | -14.108398 |
| Both tight | 1.334331 | 0.912086 | 1.328945 | 1.115731 | 0.028921 | 1.349975 | -47.638058 | -28.059142 |
| Front only tight | 1.371821 | 0.969238 | 1.366547 | 1.086528 | 0.027767 | 1.076313 | -47.740445 | -14.692762 |
| Rear only tight | 1.096677 | 0.588162 | 1.089576 | 1.180759 | 0.022530 | 1.476763 | -36.884997 | -27.259340 |

## Force and stop checks

| Case | Max FsExt abs | Front sat @1000 | Rear sat @650 | FJSt peak | FRSt peak | Rear L-R peak | Front L-R peak |
|---|---:|---:|---:|---:|---:|---:|---:|
| Passive | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Both tight | 999.996 | 0.008866 | 0.013732 | 0 | 0 | 14.326 | 17.362 |
| Front only tight | 999.996 | 0.008733 | 0 | 0 | 0 | 0 | 16.350 |
| Rear only tight | 650.000 | 0 | 0.010199 | 0 | 0 | 14.910 | 0 |

## 判断

- `Rear only tight` 是唯一在 `Az event / Az 0-4 / Az 0-15` 上优于 Passive 的轴向策略。
- `Rear only tight` 的问题是 pitch 恶化明显，rear rebound jounce min 比 Passive 更负约 13.15 mm。
- `Front only tight` 对 pitch 最有利，并且 rear rebound travel 几乎不恶化，但它显著恶化 Az 和 front rebound travel。
- `Both tight` 不是好入口：它叠加了前轴 Az 恶化和后轴 rear rebound travel 恶化。

## 下一步

进入 comfort Q profile 时，不建议继续 both-tight。

优先路线：
1. 以 `ROAD3_T2_REAR_ONLY_TIGHT` 作为 comfort Q profile 的主线，因为它证明 rear active 才能压低 T2 的低频 Az。
2. 同时准备一个 front assist 小幅版本，用于只修 pitch，不承担主 Az 控制。
3. 先跑 `ROAD3_Q_COMFORT_A/B/C + rear-only`。若 pitch 仍明显输给 Passive，再做小前轴辅助或 energy gate。

停止条件仍不变：如果 rear-only comfort 和 gate 都不能同时压过 Passive 的 Az/heave/pitch，则结论应写为当前车辆模型和执行器约束下 Passive 是 T2 pilot 强基线。
