# Road3 Gain 与 UV 门控符号复核

## 触发原因

`Output/nonlinear/test/50mm/report_nogain.md` 显示，在同一 T2 50 mm pilot 路面下：

| Case | Az event RMS | Az 0-4 RMS | Az 0-15 RMS | AA_P 0-15 RMS | Heave peak | Pitch peak |
|---|---:|---:|---:|---:|---:|---:|
| Passive | 1.11471 | 0.634054 | 1.10743 | 1.16219 | 0.0220834 | 1.23098 |
| active_gain | 1.13740 | 0.647882 | 1.12997 | 1.15392 | 0.0220906 | 1.20436 |
| active_nogain | 1.11978 | 0.669221 | 1.11226 | 1.18064 | 0.0238584 | 1.33031 |

其中 `active_gain` 与 `active_nogain` 都使用 `ROAD3_NONLINEAR_FRONT500_GATE_UV_POS`，区别是 Simulink 输出端是否保留 `Gain=-1`。

## 关键判断

去掉 `Gain=-1` 后继续使用 `UV_POS`，并不是只改变了执行器符号，还改变了能量门控相对实际 CarSim `IMP_FS/FsExt` 的含义。

当前输出层逻辑：

```matlab
power_sign = u_cmd * vel_body;
UV_POS: power_sign >= 0 时允许输出
UV_NEG: power_sign <= 0 时允许输出
```

若 Simulink 保留 `Gain=-1`：

```text
FsExt_actual = -u_cmd
```

此时 `UV_POS` 对实际力来说等价于：

```text
FsExt_actual * vel_body <= 0
```

若去掉 `Gain=-1`：

```text
FsExt_actual = u_cmd
```

此时 `UV_POS` 对实际力来说等价于：

```text
FsExt_actual * vel_body >= 0
```

因此 `Gain=-1 + UV_POS` 和 `NoGain + UV_POS` 不是同一个物理门控策略。若想在去掉 Gain 后保持原先实际力门控方向，应该优先测试 `NoGain + UV_NEG`。

## 当前实验结论

1. `active_gain` 更像“姿态友好”策略：
   - `AA_P 0-15 RMS` 优于 Passive。
   - `Pitch peak` 优于 Passive。
   - `Heave peak` 基本贴近 Passive。
   - 但 `Az event/0-4/0-15 RMS` 均差于 Passive。

2. `active_nogain` 更像“垂向 RMS 稍接近”但姿态恶化策略：
   - `Az event/0-15 RMS` 比 `active_gain` 小，但仍略差于 Passive。
   - `0-4 Hz`、heave、pitch 明显比 `active_gain` 差。

3. 当前不能简单回答“删 Gain 一定好”或“保留 Gain 一定好”。真正需要统一的是：
   - 训练模型中的 `u` 定义；
   - Simulink 到 CarSim 的实际力方向；
   - `UV_POS/UV_NEG` 相对实际 `FsExt_actual * vel_body` 的门控方向。

## 临时决策

为了继续实验可比性，短期内建议：

- 保留当前表现更稳的 `active_gain` 作为临时经验基线。
- 不把它解释为“模型符号正确”，只解释为“当前外部 Gain + UV_POS 组合下的经验最优候选”。
- 若要走干净的模型一致路线，应去掉 Gain，但必须同步测试 `ROAD3_NONLINEAR_FRONT500_GATE_UV_NEG`，而不是继续沿用 `UV_POS`。

## 下一步最小验证

只增加一个变量：

1. 保持 NoGain。
2. 运行 `ROAD3_NONLINEAR_FRONT500_GATE_UV_NEG`。
3. 与 `active_gain`、`active_nogain`、Passive 同报告比较。

若 `NoGain + UV_NEG` 接近或优于 `Gain + UV_POS`，说明根因是门控方向随 Gain 翻转；后续可以正式去掉 Gain，并把默认 nonlinear 门控改为 `UV_NEG`。

若 `NoGain + UV_NEG` 仍差，说明除了门控外，`u_prev` 反馈或 Simulink Unit Delay 取点也受 Gain 层级影响，需要把 `u_prev` 明确改成实际 `FsExt/IMP_FS` 符号再继续。
