# Road-3 rho5 front=1e-4 rear=3e-4 T2 pilot 失败分析 2026-06-07

## 数据来源

本轮结果：

- CSV：`Output/Road-3/rho5_front1e-4_rear_3e-4/2026-06-07_01.48.32.csv`
- 对比报告：`Output/Road-3/rho5_front1e-4_rear_3e-4/rho5_F1E4_R3E4_compare.md`

对比基准：

- Passive：`Output/Road-3/T2_passive/2026-06-06_21.18.39.csv`
- eMPC no-preview：`Output/Road-3/T2_no_preview/2026-06-06_21.35.22.csv`
- eMPC preview B3：`Output/Road-3/T2_pilot_preview/2026-06-06_21.45.00.csv`
- eMPC preview rho5 front=1e-5：`Output/Road-3/rho5_front_new/T2_pilot_preview/2026-06-07_01.13.06.csv`

本轮 profile：

```text
ROAD3_SOFT_F1E4_R3E4
front rho5 = 1e-4
rear  rho5 = 3e-4
```

## 关键结论

本轮结果不建议继续用于 Road-3 full，也不建议沿着单纯继续增大 `rho5` 的方向推进。

原因是 `rho5` 加大以后，控制器没有真正解决 Road-3 T2 pilot 的核心问题：

1. 外力饱和比例仍然远高于 pilot gate。
2. 前后悬回弹行程几乎没有被拉回。
3. 垂向加速度明显恶化。
4. 左右外力差确实大幅下降，但这是以乘坐性恶化为代价换来的。

## 核心指标对比

| 工况 | Az event RMS | Az 0-15 Hz RMS | AA_P 0-15 RMS | full sat max | event sat max | front Jnc min | rear Jnc min | front L-R peak |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Passive | `1.11471` | `1.10743` | `1.16219` | `0.00%` | `0.00%` | `-36.98` | `-14.11` | `0 N` |
| B3 preview | `1.52902` | `1.50975` | `2.13923` | `4.19%` | `16.16%` | `-73.60` | `-51.39` | `1819.86 N` |
| rho5 F1e-5 R1e-4 | `1.53696` | `1.51968` | `2.13760` | `4.15%` | `15.98%` | `-73.64` | `-51.39` | `2087.62 N` |
| rho5 F1e-4 R3e-4 | `1.63365` | `1.62779` | `2.09240` | `3.38%` | `13.02%` | `-73.30` | `-51.29` | `61.50 N` |

## 现象解释

`rho5=1e-4/3e-4` 的主要作用是让左右输出更对称，并略微降低全程饱和比例：

- front L-R peak 从 B3 preview 的 `1819.86 N` 降到 `61.50 N`
- rear L-R peak 从 `62.07 N` 降到 `28.17 N`
- full max saturation 从 `4.19%` 降到 `3.38%`
- event max saturation 从 `16.16%` 降到 `13.02%`

但这些改善没有转化为 Road-3 pilot 需要的效果：

- `Az 0-15 Hz RMS` 从 `1.50975` 增加到 `1.62779`
- `Az event RMS` 从 `1.52902` 增加到 `1.63365`
- front Jnc min 只从 `-73.60` 变到 `-73.30`
- rear Jnc min 只从 `-51.39` 变到 `-51.29`

这说明当前问题不是简单的“悬架行程惩罚不够大”。控制器仍然在 bump 事件中频繁顶到力限幅，只是输出形态变得更对称、更保守；车身垂向响应反而更差。

## 悬架限位判断

本轮 CSV 继续导出了 stop force：

- `FJSt_*`
- `FRSt_*`

本轮 `FJSt_*` 和 `FRSt_*` 峰值仍为 `0 N`，因此不能把本轮失败归因于 CarSim jounce/rebound stop force 已经显著介入。

从当前证据看，不建议先改 CarSim 车辆模型的悬架行程限。原因：

1. Passive 在同一路面下表现最好，说明车辆模型本身可以稳定通过 T2 pilot。
2. Active 组的主要失败特征是控制力饱和和垂向响应恶化。
3. Stop force 没有实际输出，改行程限属于大改模型，但当前没有证据说明它是主因。

## 决策

本轮 `ROAD3_SOFT_F1E4_R3E4` 判定为失败 profile。

建议停止继续单纯增大 `rho5`。下一步优先回到控制输出策略本身：

1. 先回退到 `ROAD3_SOFT_F1E5_R1E4` 或 B3 baseline，避免把失败 profile 混入后续 full。
2. Road-3 T2 pilot 不应进入 full。
3. 下一轮不要继续只改 `rho5`，应改为 Road-3 专用控制力幅值/速率策略，例如降低实际可用外力上限或增加输出平滑/变化率惩罚。
4. 如果要保持论文复现口径，Passive 结果应作为当前最可靠基线；active 结果需要先证明不恶化，再谈 preview 优势。

## 回退建议

如果当前 root 已激活 `ROAD3_SOFT_F1E4_R3E4`，可优先使用激活时返回的 `backup_dir` 回退。

若 `backup_dir` 不方便查找，可使用训练前保存的历史快照：

```matlab
addpath('src_2020');
addpath('src_2020/road3_rho5_offline');

RestoreRoad3Rho5Backup_2020( ...
    fullfile('src_2020', 'road3_rho5_offline', 'data', 'history', ...
    'active_ROAD3_SOFT_F1E5_R1E4_before_F1E4_R3E4_20260607_013504'));

clear per_corner_mpc_L1_2020 per_corner_mpc_R1_2020 ...
      per_corner_mpc_L2_2020 per_corner_mpc_R2_2020 ...
      per_corner_mpc_state_step_2020
```
