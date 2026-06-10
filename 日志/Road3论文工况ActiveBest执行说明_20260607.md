# Road3论文工况 ActiveBest 执行说明 20260607

## 冻结组合

停止继续调参，论文工况 active 组统一使用当前最佳折中组合：

- Offline profile: `ROAD3_Q_COMFORT_C`
- Control mode: `ROAD3_PAPER_ACTIVE_BEST`
- Output policy: `ROAD3_T2_COMFORT_GATE_UV_POS`
- Front limit/rate: `1000 N / 15000 N/s`
- Rear limit/rate: `650 N / 9000 N/s`
- Energy gate: `u * vel_body >= 0`

说明：

- `ROAD3_PAPER_ACTIVE_BEST` 是 `ROAD3_Q_COMFORT_C + UV_POS` 的冻结别名。
- `empc_calibration_settings_2020.m` 当前默认模式已设为 `ROAD3_PAPER_ACTIVE_BEST`。
- 当前 `src_2020/regionless_mpc_data_rear.mat` 已确认 profile tag 为 `ROAD3_Q_COMFORT_C`。

## 论文工况

本轮只跑 active-best，不再继续调参。

1. Test 1 full
   - Road dataset: `Road3_T1_short_50mm`
   - Bump: `50 mm / 0.4 m`
   - Speed: `30 km/h`
   - Suggested output: `Output/Road-3/paper_active_best/T1_50mm_preview/`

2. Test 2 full
   - Road dataset: `Road3_T2_long_150mm`
   - Bump: `150 mm / 2.5 m`
   - Speed: `50 km/h`
   - Suggested output: `Output/Road-3/paper_active_best/T2_150mm_preview/`

## 每次运行前

确认当前激活 profile：

```matlab
load('src_2020/regionless_mpc_data_rear.mat','road3_rho5_profile')
road3_rho5_profile.name
```

应输出：

```matlab
'ROAD3_Q_COMFORT_C'
```

确认控制模式：

```matlab
[~,~,~,post] = empc_calibration_settings_2020('L1')
post.energy_gate_mode
```

应输出 `1`。

清 persistent：

```matlab
clear per_corner_mpc_L1_2020 per_corner_mpc_R1_2020 ...
      per_corner_mpc_L2_2020 per_corner_mpc_R2_2020 ...
      per_corner_mpc_state_step_2020
```

## 运行后验收

单个 active full 结果先跑：

```matlab
AnalyzeRoad3T2PassiveGap_2020( ...
    'Output/Road-3/T2_passive/2026-06-06_21.18.39.csv', ...
    {'Output/Road-3/paper_active_best/T2_150mm_preview/result.csv'}, ...
    'Output/Road-3/paper_active_best/T2_150mm_preview/passive_gap.md');
```

对于 T1 可先用 `AnalyzeRoad3BumpExperiment_2020` 做单组指标检查；如果后续有 T1 passive baseline，再补 passive-gap 对比。

重点检查：

- `FJSt/FRSt peak` 是否仍为 0 或仅短时很小。
- `FsExt_*` saturation 是否可接受。
- `Az 0-4 / 0-15`、`Pitch`、`Zcg_SM heave`、`Jnc/JncR` 是否出现 T2 pilot 外推后的异常恶化。

## 结论口径

如果论文 full 幅值下 active-best 不能全面超过 Passive，不再继续调参。结论按当前已验证的口径写：

当前 CarSim 车辆模型、悬架行程和执行器约束下，Passive 是 T2 pilot 的强基线；active-best 采用 `Q_C + UV_POS` 作为折中方案，用于展示可改善的低频/姿态/行程指标，同时明确其不能保证所有指标同时优于 Passive。
