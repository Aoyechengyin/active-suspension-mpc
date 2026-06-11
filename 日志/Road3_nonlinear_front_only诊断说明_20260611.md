# Road3 nonlinear front-only 诊断说明

## 当前目的

T2 50 mm pilot 的 nonlinear preview 已经消除了止块力，但相对 Passive 在 `Az event RMS`、`Az 0-15 RMS`、`Pitch peak` 和后轴回弹行程上仍然变差。

当前诊断先验证“后轴主动输出是否是主要恶化源”，随后验证“前轴输出是否过强或相位不合适”。当前默认控制模式切到：

```matlab
ROAD3_NONLINEAR_FRONT400_GATE_UV_POS
```

该模式含义：

- 前轴：启用 nonlinear region-scheduled eMPC，限幅 `400 N`，rate limit `15000 N/s`，启用正向 `u*v` 门控。
- 后轴：主动力输出 `0 N`。
- 仍使用 `src_nonlinear` 中已激活的 `ROAD3_NONLINEAR_QC_LONGTRAVEL_V1` 控制律资产。

## 已加入的模式

在 `src_2020/empc_calibration_settings_2020.m` 中新增：

- `ROAD3_NONLINEAR_FRONT_ONLY_TIGHT`：前轴 `1000 N`，后轴 `0 N`。
- `ROAD3_NONLINEAR_BOTH_REAR400_TIGHT`：前轴 `1000 N`，后轴 `400 N`。
- `ROAD3_NONLINEAR_FRONT500_ONLY`：前轴 `500 N`，后轴 `0 N`。
- `ROAD3_NONLINEAR_FRONT500_GATE_UV_POS`：前轴 `500 N`，后轴 `0 N`，正向 `u*v` 门控。
- `ROAD3_NONLINEAR_FRONT500_GATE_UV_NEG`：前轴 `500 N`，后轴 `0 N`，负向 `u*v` 门控。
- `ROAD3_NONLINEAR_FRONT450_GATE_UV_POS`：前轴 `450 N`，后轴 `0 N`，正向 `u*v` 门控。

当前默认模式已设为：

```matlab
default_mode = 'ROAD3_NONLINEAR_FRONT400_GATE_UV_POS';
```

## 仿真前检查

先执行路径切换脚本：

```matlab
run('src_nonlinear/use_nonlinear_suspension_path_2020.m')
```

该脚本会把 `src_nonlinear` 放到 `src_2020` 前面，并清除控制器 persistent 状态。

然后检查：

```matlab
which per_corner_mpc_L1_2020
which empc_calibration_settings_2020
```

期望：

- `per_corner_mpc_L1_2020` 指向 `src_nonlinear`。
- `empc_calibration_settings_2020` 指向 `src_2020`。

如果 `per_corner_mpc_L1_2020` 指向 `src_2020`，说明 nonlinear shadow wrapper 未生效；此时跑出的主动结果应按旧线性 wrapper 处理，不能作为 nonlinear 控制律结果。

每次切换模式后清 persistent：

```matlab
clear per_corner_mpc_L1_2020 per_corner_mpc_R1_2020 ...
      per_corner_mpc_L2_2020 per_corner_mpc_R2_2020 ...
      per_corner_mpc_nonlinear_step_2020 ...
      per_corner_mpc_state_step_2020
```

## Road-3 T2 路面 CSV 位置

T2 50 mm pilot：

```text
Carsim参数集/3D路况文件/Road3_T2_long_50mm_pilot_210m_0p05m.csv
```

T2 150 mm full：

```text
Carsim参数集/3D路况文件/Road3_T2_long_150mm_210m_0p05m.csv
```

## 推荐执行顺序

1. 先在 `Road3_T2_long_50mm_pilot_210m_0p05m.csv` 上跑 `ROAD3_NONLINEAR_FRONT500_ONLY` preview。
2. 若 `Az event/0-4/0-15 RMS` 相对 `ROAD3_NONLINEAR_FRONT_ONLY_TIGHT` 明显下降，但仍输给 Passive，再分别测试 `ROAD3_NONLINEAR_FRONT500_GATE_UV_POS` 和 `ROAD3_NONLINEAR_FRONT500_GATE_UV_NEG`。
3. 当前保守候选为 `ROAD3_NONLINEAR_FRONT400_GATE_UV_POS`。`450 N` 可作为更主动的备选，但不作为默认。
4. 只有 T2 50 mm pilot 稳定且不劣于 Passive 后，再进入 T2 150 mm full。

## 已知诊断结论

`ROAD3_NONLINEAR_FRONT_ONLY_TIGHT` 已验证后轴输出能正确归零，但前轴 `1000 N` 单独控制会显著恶化垂向响应：

- `Az event RMS` 相对 Passive 增加约 `22.40%`。
- `Az 0-4 RMS` 相对 Passive 增加约 `51.25%`。
- `Pitch peak` 改善约 `13.10%`。
- 前悬回弹行程明显加深。

因此当前优先方向不是立刻加回后轴，而是先降低前轴输出或加前轴门控。

`ROAD3_NONLINEAR_FRONT500_ONLY` 相对前轴 `1000 N` 有明显收敛，但仍未超过 Passive：

- `Az event RMS` 相对 Passive 增加约 `10.42%`，但相对 `1000 N` 降低约 `9.79%`。
- `Az 0-4 RMS` 相对 Passive 增加约 `25.04%`，但相对 `1000 N` 降低约 `17.33%`。
- `Pitch peak` 相对 Passive 改善约 `4.00%`。
- 前悬回弹行程仍比 Passive 更深。

因此下一步默认切到 `ROAD3_NONLINEAR_FRONT500_GATE_UV_POS`，先判断正向门控能否消除错误相位/能量注入。

`ROAD3_NONLINEAR_FRONT500_GATE_UV_POS` 已显示明显有效，但仍未完全超过 Passive：

- `Az event RMS` 相对 Passive 增加约 `2.04%`，相对无门控 `Front500` 降低约 `7.59%`。
- `Az 0-4 RMS` 相对 Passive 增加约 `2.19%`，相对无门控降低约 `18.27%`。
- `Zcg` heave peak 相对 Passive 增加约 `2.30%`，相对无门控降低约 `12.31%`。
- `Pitch peak` 相对 Passive 改善约 `2.16%`。
- 前悬回弹基本回到 Passive 附近。

因此下一步默认切到 `ROAD3_NONLINEAR_FRONT500_GATE_UV_NEG`，用于确认门控符号。如果 UV_NEG 变差，应保留 UV_POS 作为当前最佳 nonlinear 输出策略。

`ROAD3_NONLINEAR_FRONT500_GATE_UV_NEG` 已验证明显差于 UV_POS，因此不继续使用。

`ROAD3_NONLINEAR_FRONT400_GATE_UV_POS` 是当前最稳的 conservative candidate：

- `Az event RMS` 相对 Passive 增加约 `1.43%`，相对 `500 N UV_POS` 降低约 `0.59%`。
- `Az 0-15 RMS` 相对 Passive 增加约 `1.42%`，相对 `500 N UV_POS` 降低约 `0.60%`。
- `Pitch peak` 相对 Passive 改善约 `1.80%`。
- 前/后悬回弹行程基本贴近 Passive。
- 后轴主动力保持 `0 N`。

后续如果追求更积极的主动效果，可尝试 `450 N UV_POS`；如果追求稳健复现和避免恶化，优先使用 `400 N UV_POS`。

`ROAD3_NONLINEAR_FRONT450_GATE_UV_POS` 已完成验证：

- `Az event RMS` 相对 Passive 增加约 `1.69%`，略差于 400 N 的 `1.43%`。
- `Az 0-15 RMS` 相对 Passive 增加约 `1.68%`，略差于 400 N 的 `1.42%`。
- `Pitch peak` 相对 Passive 改善约 `1.96%`，略优于 400 N 的 `1.80%`。

450 N 的优势不足以替代 400 N 作为保守默认；若汇报时强调主动 pitch 收益，可把 450 N 作为备选结果展示。
