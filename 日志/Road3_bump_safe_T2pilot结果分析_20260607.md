# Road-3 bump-safe T2 pilot 结果分析 2026-06-07

## 数据来源

本轮结果：

- CSV：`Output/Road-3/bump_safe/T2_pilot_preview/2026-06-07_02.22.00.csv`
- 对比报告：`Output/Road-3/bump_safe/T2_pilot_preview/bump_safe_compare.md`

对比基准：

- Passive：`Output/Road-3/T2_passive/2026-06-06_21.18.39.csv`
- B3 preview：`Output/Road-3/T2_pilot_preview/2026-06-06_21.45.00.csv`
- rho5 front=1e-4 rear=3e-4：`Output/Road-3/rho5_front1e-4_rear_3e-4/2026-06-07_01.48.32.csv`

当前策略：

```text
ROAD3_BUMP_SAFE
root rho5 profile = ROAD3_SOFT_F1E5_R1E4
front limit = 1200 N
rear  limit = 800 N
front rate limit = 20000 N/s
rear  rate limit = 12000 N/s
```

## 核心结论

`ROAD3_BUMP_SAFE` 方向是有效的，但还没有完全通过 T2 pilot gate。

有效的证据：

1. 垂向加速度明显优于 B3 preview 和两版 rho5 soft profile。
2. 俯仰角加速度 `AA_P` 已经接近 Passive，且优于 B3 preview。
3. 悬架回弹行程明显收回。
4. `FsExt` 左右差被压到很低。
5. `FJSt/FRSt` 仍为 `0 N`，没有证据表明 CarSim stop force 已介入。

未完全通过的原因：

1. 按 bump-safe 自身软限幅 `1200/800 N` 统计，event 饱和仍为 `3.91%`。
2. full saturation 按软限幅统计为 `1.01%`，刚好略高于 pilot `<1%` 目标。
3. `Az_SM` 仍高于 Passive，因此不能说 active 已经优于 passive。

## 关键指标对比

| 工况 | Az event RMS | Az 0-15 Hz RMS | AA_P 0-15 RMS | Heave peak | Pitch peak | front Jnc min | rear Jnc min | cfg sat | soft sat event |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Passive | `1.11471` | `1.10743` | `1.16219` | `0.02208 m` | `1.23098 deg` | `-36.98` | `-14.11` | `0.00%` | `0.00%` |
| B3 preview | `1.52902` | `1.50975` | `2.13923` | `0.04696 m` | `2.79160 deg` | `-73.60` | `-51.39` | `4.19%` | `20.27%` |
| rho5 F1e-4 R3e-4 | `1.63365` | `1.62779` | `2.09240` | `0.04595 m` | `2.78920 deg` | `-73.30` | `-51.29` | `3.38%` | `21.53%` |
| bump-safe | `1.39222` | `1.38707` | `1.12619` | `0.03100 m` | `1.43623 deg` | `-50.34` | `-31.14` | `0.00%` | `3.91%` |

说明：

- `cfg sat` 使用 Road-3 原 configured limit：前轴 `3000 N`，后轴 `2000 N`。
- `soft sat event` 使用 bump-safe 软限幅：前轴 `1200 N`，后轴 `800 N`。

## 输出力检查

本轮 bump-safe 输出峰值：

```text
front FsExt peak = 1200.0 N
rear  FsExt peak = 800.0 N
front L-R peak = 13.55 N
rear  L-R peak = 9.88 N
```

相对 B3 preview：

- front L-R peak 从 `1819.86 N` 降到 `13.55 N`
- rear L-R peak 从 `62.07 N` 降到 `9.88 N`
- configured limit 饱和从 `4.19%` 降到 `0%`

但按 bump-safe 自身软限幅，仍然有轻微限幅接触：

```text
event soft saturation max = 3.91%
full soft saturation max  = 1.01%
```

## 悬架和 stop force

本轮悬架行程明显改善：

```text
B3 preview front Jnc min = -73.60
B3 preview rear  Jnc min = -51.39
bump-safe front Jnc min = -50.34
bump-safe rear  Jnc min = -31.14
```

Stop force：

```text
FJSt max = 0 N
FRSt max = 0 N
```

因此仍不建议优先修改 CarSim 悬架行程限。

## 决策

`ROAD3_BUMP_SAFE` 是目前最有希望的 active 路线，优于继续调 `rho5`。

但当前参数还不建议直接进入 T2 full。建议下一步做一轮小幅收紧：

```text
front limit: 1200 N -> 1000 N
rear  limit: 800 N  -> 650 N
front rate limit: 20000 N/s -> 15000 N/s
rear  rate limit: 12000 N/s -> 9000 N/s
```

## Follow-up executed 2026-06-07

The recommended second-stage tightening has been applied to the active `ROAD3_BUMP_SAFE` default:

```text
front limit = 1000 N
rear  limit = 650 N
front rate limit = 15000 N/s
rear  rate limit = 9000 N/s
```

Next validation run:

```text
Output/Road-3/bump_safe_tight/T2_pilot_preview/
```

目标是把 soft saturation event 从 `3.91%` 压到接近或低于 `1%`，同时观察 `Az_SM` 是否继续靠近 Passive。

如果下一轮 `Az_SM` 反而明显恶化，则不要继续降力限，应回到 `1200/800 N` 并考虑只调整 rate/smoothing。
