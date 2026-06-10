# Road3 Q comfort A/B/C结果有效性检查 20260607

## 数据

- Rear only tight: `Output/Road-3/T2_Rear_Only_Tight/2026-06-07_21.06.37.csv`
- Q comfort A: `Output/Road-3/Q_comfort_A/2026-06-07_21.26.11.csv`
- Q comfort B: `Output/Road-3/Q_comfort_B/2026-06-07_21.37.24.csv`
- Q comfort C: `Output/Road-3/Q_comfort_C/2026-06-07_21.43.53.csv`
- Passive-gap report: `Output/Road-3/Q_comfort_ABC/q_comfort_abc_passive_gap.md`

## 关键发现

四个 CSV 的 SHA256 完全一致：

`ED69CC221CBEFC1FCDDAC0CBD1CE5A91971030862B62A70773FA694106A30428`

因此 `ROAD3_Q_COMFORT_A/B/C` 当前三组输出与 `ROAD3_T2_REAR_ONLY_TIGHT` 是字节级相同结果，不能作为 comfort Q profile 的有效仿真结论。

## Passive gap结果

`ROAD3_Q_COMFORT_A/B/C` 与 rear-only tight 完全一致：

| Case | Az event gap | Az 0-4 gap | Az 0-15 gap | AA_P 0-15 gap | Heave gap | Pitch gap | Front Jnc gap | Rear Jnc gap |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Rear only tight | -0.018036 | -0.045892 | -0.017851 | +0.018566 | +0.000447 | +0.245787 | +0.090145 | -13.150941 |
| Q comfort A | -0.018036 | -0.045892 | -0.017851 | +0.018566 | +0.000447 | +0.245787 | +0.090145 | -13.150941 |
| Q comfort B | -0.018036 | -0.045892 | -0.017851 | +0.018566 | +0.000447 | +0.245787 | +0.090145 | -13.150941 |
| Q comfort C | -0.018036 | -0.045892 | -0.017851 | +0.018566 | +0.000447 | +0.245787 | +0.090145 | -13.150941 |

## 激活资产检查

当前 `src_2020/regionless_mpc_data_rear.mat` 哈希：

`A550257F2DBC74CCA39347E89490915CA0972447771072CEA5D40A24A7EDBE1C`

已训练 profile 的 rear 哈希：

- `ROAD3_Q_COMFORT_A`: `76C0A8FCA49AD7B33128A66360D1A9B8962BF3AD8D9D96278BD753D29E0717CE`
- `ROAD3_Q_COMFORT_B`: `A7CD5FA7F4593A34F5FD7C4923851BF13A8BBCE48AF2F24C480834269BC2E46B`
- `ROAD3_Q_COMFORT_C`: `F50A1CA7C80D61852131570DE3A175EDBCC991C2FA41FAED2EFA9C11B18DE98E`

当前激活资产不等于 A/B/C 任意一个，因此本轮仿真大概率未使用新 profile，或激活后未清 persistent / 未重启求解链。

## 建议重跑流程

每个 profile 独立执行：

```matlab
addpath('src_2020');
addpath('src_2020/road3_rho5_offline');

profile_dir = fullfile('src_2020','road3_rho5_offline','data','ROAD3_Q_COMFORT_A');
backup_dir = ActivateRoad3Rho5Profile_2020(profile_dir);

clear per_corner_mpc_L1_2020 per_corner_mpc_R1_2020 ...
      per_corner_mpc_L2_2020 per_corner_mpc_R2_2020 ...
      per_corner_mpc_state_step_2020
```

然后重新打开/重启 Simulink 仿真，保持 `ROAD3_T2_REAR_ONLY_TIGHT` 模式运行 T2 pilot preview。

重跑前建议先确认：

```matlab
load('src_2020/regionless_mpc_data_rear.mat','road3_rho5_profile')
road3_rho5_profile.name
```

必须显示目标 profile，例如 `ROAD3_Q_COMFORT_A`。
