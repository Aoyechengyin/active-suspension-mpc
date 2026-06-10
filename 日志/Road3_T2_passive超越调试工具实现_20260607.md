# Road3 T2 passive超越调试工具实现 20260607

## 已实现内容

- 新增诊断脚本：`src_2020/AnalyzeRoad3T2PassiveGap_2020.m`
  - 输入 passive CSV 和一个或多个 active CSV。
  - 输出 Passive gap summary、phase timing、band-split RMS。
  - 分频固定为 `0-2 / 2-4 / 4-8 / 8-15 Hz`，同时保留 `0-4 / 0-15 Hz`。

- 新增 T2 pilot 专用控制模式，不覆盖 `ROAD3_BUMP_SAFE`：
  - `ROAD3_T2_FRONT_ONLY_TIGHT`: front `1000 N / 15000 N/s`，rear `0 N`。
  - `ROAD3_T2_REAR_ONLY_TIGHT`: front `0 N`，rear `650 N / 9000 N/s`。
  - `ROAD3_T2_BOTH_TIGHT`: front `1000 N / 15000 N/s`，rear `650 N / 9000 N/s`。
  - `ROAD3_T2_COMFORT_GATE_UV_POS`: both-tight + `u * vel_body >= 0` 允许输出。
  - `ROAD3_T2_COMFORT_GATE_UV_NEG`: both-tight + `u * vel_body <= 0` 允许输出。

- 离线训练工具保留原 `road3_rho5_offline` 目录和函数名，但 profile 已扩展为完整 `rho1-rho5`：
  - `ROAD3_Q_COMFORT_A`: `rho1=2500, rho2=2e4, rho3=50, rho4=5e4, rho5_front=1e-5, rho5_rear=1e-4`
  - `ROAD3_Q_COMFORT_B`: `rho1=5000, rho2=1e4, rho3=100, rho4=5e4, rho5_front=1e-5, rho5_rear=1e-4`
  - `ROAD3_Q_COMFORT_C`: `rho1=10000, rho2=5e3, rho3=200, rho4=2e4, rho5_front=3e-5, rho5_rear=1e-4`

## 固定执行顺序

1. 把 `empc_calibration_settings_2020.m` 默认模式切到 `ROAD3_T2_FRONT_ONLY_TIGHT`，跑 T2 pilot preview。
2. 切到 `ROAD3_T2_REAR_ONLY_TIGHT`，跑 T2 pilot preview。
3. 用 passive-gap 报告判断 front/rear/both 哪个轴向策略进入 comfort Q profile。
4. 依次离线训练并激活：

```matlab
addpath('src_2020');
addpath('src_2020/road3_rho5_offline');

TrainRoad3Rho5Offline_2020('profileName','ROAD3_Q_COMFORT_A','nSamples',8000);
TrainRoad3Rho5Offline_2020('profileName','ROAD3_Q_COMFORT_B','nSamples',8000);
TrainRoad3Rho5Offline_2020('profileName','ROAD3_Q_COMFORT_C','nSamples',8000);
```

5. 若 best comfort 仍输给 Passive 的 `Az/heave/pitch`，再分别跑：
   - `ROAD3_T2_COMFORT_GATE_UV_POS`
   - `ROAD3_T2_COMFORT_GATE_UV_NEG`

每次切换模式或激活新 profile 后都清 persistent：

```matlab
clear per_corner_mpc_L1_2020 per_corner_mpc_R1_2020 ...
      per_corner_mpc_L2_2020 per_corner_mpc_R2_2020 ...
      per_corner_mpc_state_step_2020
```

## 对比报告调用

```matlab
AnalyzeRoad3T2PassiveGap_2020( ...
    'Output/Road-3/T2_passive/2026-06-06_21.18.39.csv', ...
    { ...
      'Output/Road-3/bump_safe_tight/T2_pilot_preview/2026-06-07_19.48.05.csv', ...
      'Output/Road-3/new_case/result.csv' ...
    }, ...
    'Output/Road-3/new_case/t2_passive_gap.md');
```

## 注意

- energy gate 使用现有 wrapper 输入 `vel_body`，没有改 Simulink 接口顺序。
- `UV_POS/UV_NEG` 只是符号试验；用 T2 pilot 结果决定保留方向，不预设物理结论。
- 不修改 CarSim 悬架行程、止块、阻尼、车身质量、轮胎或道路定义。
