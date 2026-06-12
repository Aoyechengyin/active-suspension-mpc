# Road3 nonlinear rear 调试说明

## 当前目标

前轴调试已经得到一个保守候选：`ROAD3_NONLINEAR_FRONT400_GATE_UV_POS`。现在切换到后轴调试，目标是单独判断后轴 nonlinear 控制是否能改善 rear/pitch/heave，还是会继续放大后轴回弹和后轮卸载。

## 当前默认模式

```matlab
ROAD3_NONLINEAR_REAR300_ONLY
```

含义：

- 前轴：`0 N`，完全关闭。
- 后轴：nonlinear region-scheduled eMPC，限幅 `300 N`。
- 输出层：rate limit `9000 N/s`，smooth tau `0.020 s`。
- 当前默认不加 energy gate，先看后轴原始小限幅输出的基本趋势。

## 已新增 rear 模式

在 `src_2020/empc_calibration_settings_2020.m` 中新增：

- `ROAD3_NONLINEAR_REAR300_ONLY`：后轴 `300 N`，无门控。
- `ROAD3_NONLINEAR_REAR300_GATE_UV_POS`：后轴 `300 N`，正向 `u*v` 门控。
- `ROAD3_NONLINEAR_REAR300_GATE_UV_NEG`：后轴 `300 N`，负向 `u*v` 门控。

## 仿真前检查

```matlab
run('src_nonlinear/use_nonlinear_suspension_path_2020.m')

which per_corner_mpc_L1_2020
which empc_calibration_settings_2020
```

期望：

- `per_corner_mpc_L1_2020` 指向 `src_nonlinear`。
- `empc_calibration_settings_2020` 指向 `src_2020`。

## 推荐执行顺序

1. 先跑 `ROAD3_NONLINEAR_REAR300_ONLY`，路面仍用 T2 50 mm pilot。
2. 若 rear300 明显恶化 `Az/heave/rear Jnc/Fz`，不急着加回前轴，继续跑 `ROAD3_NONLINEAR_REAR300_GATE_UV_POS` 和 `ROAD3_NONLINEAR_REAR300_GATE_UV_NEG` 判断门控方向。
3. 若 rear300 在某些 rear 指标上有效，再考虑和前轴保守候选 `ROAD3_NONLINEAR_FRONT400_GATE_UV_POS` 组合，但组合前必须先确认 rear-only 不引入后轮卸载。

## 验收重点

- `Az event RMS`、`Az 0-4 RMS`、`Az 0-15 RMS` 不能明显高于 Passive。
- `Zcg_SM` heave peak 不能明显高于 Passive。
- `Pitch peak`、`AA_P 0-15 RMS` 若有改善，需要同时检查 rear rebound。
- `Jnc_L2/R2 min` 不得比 Passive 明显更负。
- `Fz_L2/R2 <= 0` 时间比例不得高于 Passive。
- `FJSt/FRSt` 应继续保持 `0 N`。

