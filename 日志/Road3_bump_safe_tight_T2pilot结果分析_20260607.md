# Road-3 bump-safe tight T2 pilot 结果分析 2026-06-07

## 数据来源

本轮 tight 结果：

```text
Output/Road-3/bump_safe_tight/T2_pilot_preview/2026-06-07_19.48.05.csv
```

对比报告：

```text
Output/Road-3/bump_safe_tight/T2_pilot_preview/bump_safe_tight_compare.md
```

对比基线：

```text
Passive:          Output/Road-3/T2_passive/2026-06-06_21.18.39.csv
B3 preview:       Output/Road-3/T2_pilot_preview/2026-06-06_21.45.00.csv
bump-safe 1200/800: Output/Road-3/bump_safe/T2_pilot_preview/2026-06-07_02.22.00.csv
```

当前策略：

```text
ROAD3_BUMP_SAFE
front limit = 1000 N
rear  limit = 650 N
front rate limit = 15000 N/s
rear  rate limit = 9000 N/s
root rho5 profile = ROAD3_SOFT_F1E5_R1E4
```

## 核心结论

第二阶段 tight 是有效的，但不应继续往下收紧。

相对上一版 bump-safe `1200/800 N`：

| 指标 | 1200/800 | tight 1000/650 | 趋势 |
|---|---:|---:|---|
| `Az_SM` event RMS | `1.39222` | `1.33433` | 改善 |
| `Az_SM` 0-15 Hz RMS | `1.38707` | `1.32894` | 改善 |
| `AA_P` 0-15 Hz RMS | `1.12619` | `1.11573` | 小幅改善 |
| `Zcg_SM` heave peak | `0.03100 m` | `0.02892 m` | 改善 |
| `Pitch` peak | `1.43623 deg` | `1.34998 deg` | 改善 |
| front `Jnc` min | `-50.34` | `-47.64` | 改善 |
| rear `Jnc` min | `-31.14` | `-28.06` | 改善 |
| soft sat event | `3.91%` | `5.29%` | 变差 |
| soft sat full | `1.01%` | `1.37%` | 变差 |

解释：

- 动力学响应继续改善，说明输出收紧方向本身是对的。
- 软限幅接触比例上升，是因为阈值从 `1200/800 N` 降到 `1000/650 N` 后，控制输出更频繁贴到新边界。
- 这不是数值失控；`cfg sat` 按 CarSim 原配置 `3000/2000 N` 仍为 `0%`。
- 但它说明继续降低 force limit 的边际收益已经变小，且会让控制器更像限幅器。

## 与 Passive 的关系

tight 结果仍没有在垂向加速度和 heave 上超过 Passive：

| 指标 | Passive | tight |
|---|---:|---:|
| `Az_SM` event RMS | `1.11471` | `1.33433` |
| `Az_SM` 0-15 Hz RMS | `1.10743` | `1.32894` |
| `Zcg_SM` heave peak | `0.02208 m` | `0.02892 m` |
| `Pitch` peak | `1.23098 deg` | `1.34998 deg` |
| `AA_P` 0-15 Hz RMS | `1.16219` | `1.11573` |

因此不能把 tight 版表述为“全面优于 Passive”。更准确的表述是：

```text
Road-3 T2 pilot 下，bump-safe tight 显著优于原 B3 preview，
并在 pitch acceleration 上略优于 Passive；
但在垂向加速度、heave 和 pitch peak 上仍不如 Passive。
```

## 悬架行程和止块力

本轮没有看到 CarSim stop force 介入：

```text
FJSt/FRSt peak = 0 N
```

悬架动挠度相对 B3 preview 和上一版 bump-safe 均有改善：

```text
B3 preview front Jnc min = -73.60
bump-safe 1200/800 front Jnc min = -50.34
bump-safe tight front Jnc min = -47.64

B3 preview rear Jnc min = -51.39
bump-safe 1200/800 rear Jnc min = -31.14
bump-safe tight rear Jnc min = -28.06
```

因此当前仍不建议优先修改 CarSim 车辆模型的悬架行程限。模型行程限可以作为论文讨论中的系统约束说明，但不作为下一步主要修改项。

## 决策

保留当前 tight 参数：

```text
front limit = 1000 N
rear  limit = 650 N
front rate limit = 15000 N/s
rear  rate limit = 9000 N/s
```

不再继续降低 force limit。继续降限大概率只能增加限幅接触比例，未必能进一步改善 `Az_SM`。

下一步建议：

1. 如果目标是推进 Road-3 全流程，先用 tight profile 跑 `T1 full 50 mm` 的三组对照。
2. `T2 full 150 mm` 不建议直接用 active 先跑；应先确认 Passive full 可视化和数据稳定。
3. 如果必须跑 T2 active full，优先使用当前 tight profile，并把验收口径改成“安全通过/不过度恶化”，不要预期它全面优于 Passive。
