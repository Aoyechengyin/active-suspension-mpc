# B4 Flat-Road MPC Baseline Manifest

Generated: 2026-06-06

## Baseline Files

- Baseline CSV: `Output/CaseB4/2026-06-06_00.28.33.csv`
  - Size: `977633` bytes
  - Last write time: `2026/6/6 0:28:42`
- Flat-pose report: `Output/CaseB4/flat_pose_report_compare_B4_real.md`
  - Size: `7253` bytes
  - Last write time: `2026/6/6 0:31:39`
- Road diagnostic baseline report: `Output/CaseB4/road_experiment_report_B4_baseline.md`
  - Size: `3319` bytes
  - Last write time: `2026/6/6 0:59:40`

## MPC Data Files

| File | Size (bytes) | Last write time |
|---|---:|---|
| `src_2020/prediction_model_front.mat` | 2732 | 2026/6/6 0:22:43 |
| `src_2020/prediction_model_rear.mat` | 2727 | 2026/6/6 0:22:43 |
| `src_2020/mpc_qp_data_front.mat` | 143476 | 2026/6/6 0:22:44 |
| `src_2020/mpc_qp_data_rear.mat` | 143081 | 2026/6/6 0:22:44 |
| `src_2020/regionless_mpc_data_front.mat` | 505718 | 2026/6/6 0:23:10 |
| `src_2020/regionless_mpc_data_rear.mat` | 328147 | 2026/6/6 0:23:35 |

## Frozen Interface

- CarSim Import order: `[IMP_FS_L1, IMP_FS_L2, IMP_FS_R1, IMP_FS_R2]`
- Simulink Mux order: `[L1, L2, R1, R2]`
- CarSim Export preview order starts with:
  - `[W1_L1, W1_R1, W1_L2, W1_R2, W2_L1, W2_R1, W2_L2, W2_R2]`

## Frozen Controller Settings

- Default calibration mode: `B3_CONSERVATIVE`
- Front force limit: `3000 N`
- Rear force limit: `2000 N`
- `rho5_front = 1e-7`
- `rho5_rear = 1e-4`
- Rear force direction: not reversed

## Baseline Diagnostic Summary

From `Output/CaseB4/road_experiment_report_B4_baseline.md`:

- Warnings: `0`
- Missing diagnostics: `0`
- Rows: `601`
- Time span: `0` to `15 s`
- Sample dt estimate: `0.025 s`
- Road event window: none detected
- Road peak abs across `Zgnd_*`: `5.55112e-17 m`
- `Az_SM` peak: `0.00430439 g`
- `Az_SM` RMS over full run: `0.000349105 g`
- Final Roll mean: `0.00199958 deg`
- Final Yaw mean: `-0.0127874 deg`
- Final Yo mean: `-0.0204456 m`
- Front `FsExt` L-R peak abs: `13.1099 N`
- Rear `FsExt` L-R peak abs: `6.87876 N`
- Configured `FsExt` saturation fraction: `0`
- Hard `9000 N` saturation fraction: `0`
- Minimum wheel rotation delta: `84.3278 rev`

## Usage

Use this manifest as the reference point before Road-0/Road-1/Road-2 experiments. If a later run changes the interface order, controller limits, QP data timestamps, or B4 flat-road diagnostic summary, treat it as a new baseline and create a new manifest instead of overwriting this one.
