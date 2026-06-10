# Road-3 rho5 front=1e-5 T2 pilot 结果分析 2026-06-07

## 数据来源

新结果：

- CSV：`Output/Road-3/rho5_front_new/T2_pilot_preview/2026-06-07_01.13.06.csv`
- MAT：`Output/Road-3/rho5_front_new/T2_pilot_preview/2026-06-07_01.13.06.mat`

对比基准：

- Passive：`Output/Road-3/T2_passive/2026-06-06_21.18.39.csv`
- eMPC no-preview：`Output/Road-3/T2_no_preview/2026-06-06_21.35.22.csv`
- eMPC preview B3：`Output/Road-3/T2_pilot_preview/2026-06-06_21.45.00.csv`

正式 Road-3 对比报告：

- `Output/Road-3/rho5_front_new/T2_pilot_preview/rho5_front_new_compare.md`

## 当前 profile

已激活并用于本次仿真的 profile：

```text
ROAD3_SOFT_F1E5_R1E4
front rho5 = 1e-5
rear  rho5 = 1e-4
```

也就是只把前轴控制惩罚从 `1e-7` 提高到 `1e-5`，后轴保持原 B3 值。

## 核心结论

本轮 `rho5_front=1e-5` 不足以通过 T2 50 mm pilot gate。

主要原因：

1. `FsExt_*` 仍然频繁打到限幅。
   - B3 preview 最大全程饱和比例：`4.193%`
   - 新 rho5 preview 最大全程饱和比例：`4.146%`
   - 按 event window 统计，新 rho5 preview 最大饱和比例仍约 `15.89%`
   - 相比旧 B3 只有很小下降，远未达到 pilot 目标 `<1%`。
2. 乘坐/姿态指标没有改善。
   - B3 preview `Az 0-15 Hz RMS = 1.50975 m/s^2`
   - 新 rho5 preview `Az 0-15 Hz RMS = 1.51968 m/s^2`
   - B3 preview `Az event RMS = 1.52902 m/s^2`
   - 新 rho5 preview `Az event RMS = 1.53696 m/s^2`
   - `AA_P 0-15 Hz RMS` 基本持平，略小但不足以抵消垂向加速度恶化。
3. 前悬动挠度没有收敛。
   - B3 preview front `Jnc` 最小约 `-73.60 mm`
   - 新 rho5 preview front `Jnc` 最小约 `-73.64 mm`
   - 这说明前轴 `rho5=1e-5` 没有把回弹动挠度拉回安全范围。
4. 前轴左右外力差反而更大。
   - B3 preview front L-R peak：`1819.86 N`
   - 新 rho5 preview front L-R peak：`2087.62 N`
   - 这对横摆/侧倾扰动不是好趋势。

## 三组关键指标

| 工况 | Az event RMS | Az 0-15 Hz RMS | AA_P 0-15 Hz RMS | Max FsExt sat. all | Max FsExt sat. event | Front L-R peak | Front Jnc min | Rear Jnc min |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Passive | `1.11471 m/s^2` | `1.10743 m/s^2` | `1.16219` | `0%` | `0%` | `0 N` | `-36.98 mm` | `-14.11 mm` |
| Preview B3 | `1.52902 m/s^2` | `1.50975 m/s^2` | `2.13923` | `4.193%` | `16.071%` | `1819.86 N` | `-73.60 mm` | `-51.39 mm` |
| Preview rho5F1e-5 | `1.53696 m/s^2` | `1.51968 m/s^2` | `2.13760` | `4.146%` | `15.892%` | `2087.62 N` | `-73.64 mm` | `-51.39 mm` |

## Stop force / stop compression

新 CSV 已额外导出：

- `FJSt_*`
- `FRSt_*`
- `CmpJSt*`
- `CmpRSt*`

本次 `FJSt_*` 和 `FRSt_*` 峰值仍为 `0 N`，因此仍不能说 CarSim stop force 已经介入。

注意：`CmpJSt* / CmpRSt*` 在 CSV 中表现为带正负号的 travel-like 量，并且与 `FJSt/FRSt=0` 并存。因此本轮仍以 `FJSt/FRSt` 作为是否真正产生 stop force 的决定性证据；`Cmp*` 只作为后续排查 CarSim stop transform 的辅助变量。

## MAT 文件

`2026-06-07_01.13.06.mat` 可读，包含 `51` 个变量，例如：

- `Time`
- `Fs_*`
- `FsExt_*`
- `Jnc_*`
- `JncR_*`
- `Az_SM`
- `Vx`

CSV 包含 `141` 列，诊断变量更完整；本次定量判断以 CSV 为主，MAT 作为备份和复核数据源。

## 决策

不建议基于 `rho5_front=1e-5` 进入 T2 full。

建议下一步二选一：

1. 继续控制惩罚路线，训练并激活更强 soft profile：
   - `ROAD3_SOFT_F1E4_R3E4`
   - front `rho5=1e-4`
   - rear `rho5=3e-4`
2. 如果 `rho5=1e-4 / 3e-4` 仍然饱和明显，则不要继续盲目加 `rho5`，改为 Road-3 专用输出缩放/限幅：
   - front `1500-2000 N`
   - rear `1000-1500 N`
   - 同时保留 profile 名称和备份记录，避免和 B3 基准混淆。

当前更推荐先跑 `ROAD3_SOFT_F1E4_R3E4`，因为它仍然只改变 MPC 权重，不改变 CarSim 车辆模型和 Simulink 接口。
