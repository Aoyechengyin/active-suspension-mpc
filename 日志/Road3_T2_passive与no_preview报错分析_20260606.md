# Road-3 T2 Passive 结果与 no-preview 报错分析

> 2026-06-06 更新：no-preview 已成功跑完，CSV 为 `Output/Road-3/T2_no_preview/2026-06-06_21.35.22.csv`；preview 也补跑了带 `FJSt_*` / `FRSt_*` 的版本，CSV 为 `Output/Road-3/T2_pilot_preview/2026-06-06_21.45.00.csv`。两组 eMPC 的动力学响应几乎一致，且 `FJSt_*` / `FRSt_*` 全为 `0 N`。因此后续结论以 `日志/Road3_T2三组对比与悬架行程决策_20260606.md` 为准：当前主要问题是主动控制导致前悬回弹动挠度过大，而不是已确认的 CarSim 止块力介入。

生成日期：2026-06-06

## 输入

- Passive CSV：`Output/Road-3/T2_passive/2026-06-06_21.18.39.csv`
- Preview CSV：`Output/Road-3/T2_pilot_preview/2026-06-06_20.31.27.csv`
- no-preview VS Command 文件：`Carsim参数集/VSCommand/Road3_no_preview_exports_2020.txt`

## Passive 结果

T2 50 mm 路面在 passive/零外力下没有触发悬架止块：

| 指标 | Passive |
|---|---:|
| `Vx mean` | 49.96 km/h |
| `Road peak` | 0.04993 m |
| `Az_SM` event peak | 0.524 g |
| `Az_SM` event RMS | 0.1136 g |
| `Pitch` event peak | 1.231 deg |
| `FsExt_*` | 0 N |
| `FJSt_*` | 0 N |
| `FRSt_*` | 0 N |

行程余量：

| 车轮 | Passive `Jnc_min` | Passive `Jnc_max` | 结论 |
|---|---:|---:|---|
| L1/R1 前轮 | -36.98 / -36.86 mm | 39.75 / 39.85 mm | 距前悬回弹止块仍约 13 mm |
| L2/R2 后轮 | -14.11 / -13.99 mm | 30.69 / 30.84 mm | 距后悬回弹止块仍约 46 mm |

这说明 50 mm T2 pilot 路面本身不会必然触发止块。此前 preview 模式中前轮 `Jnc_L1/R1≈-73.6 mm`，更像是主动控制力把前悬拉进回弹止块。

## no-preview 报错原因

报错信息：

```text
Failed to start Solver: a symbolic expression contains the symbol "X_" and it is not recognized.
```

仓库里的 `Carsim参数集/VSCommand/Road3_no_preview_exports_2020.txt` 没有 `X_*` 占位符，使用的是正确的 `X_L1/Y_L1` 等变量。因此这次报错最可能来自把执行说明里的通配写法 `road_z(X_*, Y_*)` 直接复制进了 CarSim VS Command。

`X_*` / `Y_*` 只能作为说明文档里的“任意车轮”占位符，不能作为 CarSim 表达式运行。CarSim 会把它解析成未定义符号 `X_`。

## no-preview 正确命令

```text
EQ_OUT W1_L1 = road_z(X_L1, Y_L1)
EQ_OUT W1_R1 = road_z(X_R1, Y_R1)
EQ_OUT W1_L2 = road_z(X_L2, Y_L2)
EQ_OUT W1_R2 = road_z(X_R2, Y_R2)

EQ_OUT W2_L1 = road_z(X_L1, Y_L1)
EQ_OUT W2_R1 = road_z(X_R1, Y_R1)
EQ_OUT W2_L2 = road_z(X_L2, Y_L2)
EQ_OUT W2_R2 = road_z(X_R2, Y_R2)
```

如果 CarSim Additional Data 中已经存在旧的 `EQ_OUT W1_*` / `EQ_OUT W2_*` 行，需要先替换掉旧行，避免同名输出重复定义或仍残留 `X_*`。

## 下一步

1. 用上述 no-preview 命令重跑 T2 50 mm pilot。
2. CSV 保留 `FJSt_*`、`FRSt_*`、`Jnc_*`、`JncR_*`、`FsExt_*`。
3. 若 no-preview 不触止块而 preview 触止块，优先排查预瞄路面状态填充和前轴控制时序。
4. 若 no-preview 和 preview 都触止块，再考虑对 Road-3 单独降低前轴限幅、提高前轴控制权重，或加入前悬回弹行程保护。
