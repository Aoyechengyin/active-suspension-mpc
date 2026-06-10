# Road-3 rho5 离线训练工具使用说明

## 目的

本目录用于 Road-3 专用 soft eMPC 参数训练，避免直接覆盖旧的 B3/B4 基准设置。

已保留的基准参数：

- `config_2020.m` 未修改。
- `B3_CONSERVATIVE_BASELINE`: front `rho5=1e-7`, rear `rho5=1e-4`。
- 根目录原有 `prediction_model_*`、`mpc_qp_data_*`、`regionless_mpc_data_*` 不在训练阶段覆盖。

已训练的新 profile：

- `ROAD3_SOFT_F1E5_R1E4`
- front `rho5=1e-5`
- rear `rho5=1e-4`
- 输出目录：`src_2020/road3_rho5_offline/data/ROAD3_SOFT_F1E5_R1E4`

## 目录内容

- `Road3Rho5Profiles_2020.m`: 定义基线和 Road-3 soft rho5 profile。
- `Road3Rho5Config_2020.m`: 基于 `config_2020` 生成内存覆盖配置，不改原文件。
- `TrainRoad3Rho5Offline_2020.m`: 离线生成 prediction model、QP 和 regionless 数据。
- `ActivateRoad3Rho5Profile_2020.m`: 将已训练 profile 激活到 `src_2020` 根目录，并自动备份旧 `.mat`。
- `RestoreRoad3Rho5Backup_2020.m`: 从备份目录恢复旧 `.mat`。
- `test_road3_rho5_offline_2020.m`: 回归测试 profile、dry-run、激活和恢复逻辑。

## 重新训练

```matlab
addpath('src_2020');
addpath('src_2020/road3_rho5_offline');

manifest = TrainRoad3Rho5Offline_2020( ...
    'profileName', 'ROAD3_SOFT_F1E5_R1E4', ...
    'nSamples', 8000);
```

可选的更强 soft profile：

```matlab
manifest = TrainRoad3Rho5Offline_2020( ...
    'profileName', 'ROAD3_SOFT_F1E4_R3E4', ...
    'nSamples', 8000);
```

## 激活到 Simulink/CarSim 入口

训练完成后，如需让 `per_corner_mpc_*_2020.m` 使用新数据，运行：

```matlab
addpath('src_2020');
addpath('src_2020/road3_rho5_offline');

profile_dir = fullfile('src_2020', 'road3_rho5_offline', 'data', 'ROAD3_SOFT_F1E5_R1E4');
backup_dir = ActivateRoad3Rho5Profile_2020(profile_dir);

clear per_corner_mpc_L1_2020 per_corner_mpc_R1_2020 ...
      per_corner_mpc_L2_2020 per_corner_mpc_R2_2020 ...
      per_corner_mpc_state_step_2020
```

激活只复制 8 个 `.mat` 资产，不修改 `config_2020.m` 或控制器 `.m` 文件。

## 恢复旧基准

```matlab
addpath('src_2020');
addpath('src_2020/road3_rho5_offline');

RestoreRoad3Rho5Backup_2020(backup_dir);

clear per_corner_mpc_L1_2020 per_corner_mpc_R1_2020 ...
      per_corner_mpc_L2_2020 per_corner_mpc_R2_2020 ...
      per_corner_mpc_state_step_2020
```

## 推荐下一次仿真

1. 激活 `ROAD3_SOFT_F1E5_R1E4`。
2. 保持 CarSim 车辆模型不变。
3. 保持 `empc_calibration_settings_2020` 的 `B3_CONSERVATIVE` 模式，先只观察 rho5 变化效果。
4. 先跑 `T2 50 mm pilot preview`。
5. 验收重点：`FsExt_*` 饱和比例是否降到 `<1%`，前悬 `Jnc_L1/R1` 是否明显回收，`Az_SM` 和 `AA_P` 是否不再恶化。
