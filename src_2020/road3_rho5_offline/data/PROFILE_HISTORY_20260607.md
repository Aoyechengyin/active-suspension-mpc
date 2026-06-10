# Road-3 rho5 Offline Profile History

Generated: 2026-06-07

## Active Root Status After This Training

`src_2020` root MPC assets were **not** overwritten by the `ROAD3_SOFT_F1E4_R3E4` training run.

Current active root profile is still:

```text
ROAD3_SOFT_F1E5_R1E4
front rho5 = 1e-5
rear  rho5 = 1e-4
```

## Profiles

| Profile | Directory | front rho5 | rear rho5 | Status | Notes |
|---|---|---:|---:|---|---|
| `ROAD3_SOFT_F1E5_R1E4` | `src_2020/road3_rho5_offline/data/ROAD3_SOFT_F1E5_R1E4` | `1e-5` | `1e-4` | trained, currently active in root | First soft trial; T2 pilot did not pass saturation gate. |
| `ROAD3_SOFT_F1E4_R3E4` | `src_2020/road3_rho5_offline/data/ROAD3_SOFT_F1E4_R3E4` | `1e-4` | `3e-4` | trained, not active yet | Stronger soft trial for next T2 pilot run. |

## Historical Active Snapshot

Before training `ROAD3_SOFT_F1E4_R3E4`, the active root MPC assets were copied to:

```text
src_2020/road3_rho5_offline/data/history/active_ROAD3_SOFT_F1E5_R1E4_before_F1E4_R3E4_20260607_013504
```

This snapshot contains the eight canonical MPC assets:

```text
prediction_model_front.mat
prediction_model_rear.mat
mpc_qp_data_front.mat
mpc_qp_data_rear.mat
regionless_mpc_data_front.mat
regionless_mpc_data_rear.mat
regionless_mpc_data_front_full.mat
regionless_mpc_data_rear_full.mat
```

## Activate The New Stronger Profile

```matlab
addpath('src_2020');
addpath('src_2020/road3_rho5_offline');

profile_dir = fullfile('src_2020', 'road3_rho5_offline', 'data', 'ROAD3_SOFT_F1E4_R3E4');
backup_dir = ActivateRoad3Rho5Profile_2020(profile_dir);

clear per_corner_mpc_L1_2020 per_corner_mpc_R1_2020 ...
      per_corner_mpc_L2_2020 per_corner_mpc_R2_2020 ...
      per_corner_mpc_state_step_2020
```

The activation command will create another `backup_active_*` directory inside the profile directory before copying files into `src_2020`.

## Roll Back

If the new profile is activated and needs to be reverted immediately, use the `backup_dir` returned by `ActivateRoad3Rho5Profile_2020`:

```matlab
RestoreRoad3Rho5Backup_2020(backup_dir);

clear per_corner_mpc_L1_2020 per_corner_mpc_R1_2020 ...
      per_corner_mpc_L2_2020 per_corner_mpc_R2_2020 ...
      per_corner_mpc_state_step_2020
```

If `backup_dir` was lost, the historical snapshot above can also be used as a restore source:

```matlab
RestoreRoad3Rho5Backup_2020( ...
    fullfile('src_2020', 'road3_rho5_offline', 'data', 'history', ...
    'active_ROAD3_SOFT_F1E5_R1E4_before_F1E4_R3E4_20260607_013504'));
```
