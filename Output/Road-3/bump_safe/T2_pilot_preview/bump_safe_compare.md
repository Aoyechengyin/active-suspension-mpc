# Road-3 Bump Experiment Report

- Cases: `6`
- Event padding: `0.500 s` before, `3.000 s` after
- Force limits: front `3000 N`, rear `2000 N`

## Summary

| Case | Road peak m | Az event RMS m/s^2 | Az 0-4 Hz RMS | Az 0-15 Hz RMS | AA_P 0-15 RMS | AA_R 0-15 RMS | Max FsExt sat. | Rear L-R peak N | Rot min delta |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `2026-06-06_21.18.39.csv` | 0.0499285 | 1.11471 | 0.634054 | 1.10743 | 1.16219 | 0.00294742 | 0 | 0 | 84.3309 |
| `2026-06-06_21.35.22.csv` | 0.0499285 | 1.53179 | 1.23767 | 1.51233 | 2.13682 | 0.00865053 | 0.0421305 | 63.5094 | 84.3379 |
| `2026-06-06_21.45.00.csv` | 0.0499285 | 1.52902 | 1.23897 | 1.50975 | 2.13923 | 0.00881416 | 0.0419305 | 62.068 | 84.338 |
| `2026-06-07_01.13.06.csv` | 0.0499285 | 1.53696 | 1.25607 | 1.51968 | 2.1376 | 0.00930878 | 0.0414639 | 65.227 | 84.338 |
| `2026-06-07_01.48.32.csv` | 0.0499285 | 1.63365 | 1.39991 | 1.62779 | 2.0924 | 0.0093869 | 0.0337977 | 28.1719 | 84.3372 |
| `2026-06-07_02.22.00.csv` | 0.0499285 | 1.39222 | 0.983129 | 1.38707 | 1.12619 | 0.00323135 | 0 | 9.87934 | 84.331 |

## `2026-06-06_21.18.39.csv`

- Source: `Output/Road-3/T2_passive/2026-06-06_21.18.39.csv`
- Rows/time: `15001`, `0.000` to `15.000 s`, dt `0.001 s`
- Event window: `6.712` to `10.603 s`, road peak `0.0499285 m`
- Final station/speed: `208.179 m`, `49.9628 km/h`
- Heave peak abs from `Zcg_SM`: `0.0220834 m`
- Pitch/Roll peak abs: `1.23098 deg` / `0.00692196 deg`
- Front/Rear FsExt L-R peak abs: `0 N` / `0 N`

### Band RMS

| Signal | Event RMS | 0-4 Hz RMS | 0-15 Hz RMS |
|---|---:|---:|---:|
| Az_SM m/s^2 | 1.11471 | 0.634054 | 1.10743 |
| AA_P rad/s^2 | 1.1696 | 0.951685 | 1.16219 |
| AA_R rad/s^2 | 0.00303657 | 0.00208935 | 0.00294742 |

### Force Saturation

| Signal | Limit N | Event min N | Event max N | Event RMS N | Full sat. fraction |
|---|---:|---:|---:|---:|---:|
| FsExt_L1 | 3000 | 0.000 | 0.000 | 0.000 | 0 |
| FsExt_R1 | 3000 | 0.000 | 0.000 | 0.000 | 0 |
| FsExt_L2 | 2000 | 0.000 | 0.000 | 0.000 | 0 |
| FsExt_R2 | 2000 | 0.000 | 0.000 | 0.000 | 0 |

Warnings: none.

## `2026-06-06_21.35.22.csv`

- Source: `Output/Road-3/T2_no_preview/2026-06-06_21.35.22.csv`
- Rows/time: `15001`, `0.000` to `15.000 s`, dt `0.001 s`
- Event window: `6.712` to `10.604 s`, road peak `0.0499285 m`
- Final station/speed: `208.177 m`, `49.9629 km/h`
- Heave peak abs from `Zcg_SM`: `0.0468488 m`
- Pitch/Roll peak abs: `2.78344 deg` / `0.010619 deg`
- Front/Rear FsExt L-R peak abs: `1360.79 N` / `63.5094 N`

### Band RMS

| Signal | Event RMS | 0-4 Hz RMS | 0-15 Hz RMS |
|---|---:|---:|---:|
| Az_SM m/s^2 | 1.53179 | 1.23767 | 1.51233 |
| AA_P rad/s^2 | 2.14541 | 2.04927 | 2.13682 |
| AA_R rad/s^2 | 0.0244864 | 0.00724109 | 0.00865053 |

### Force Saturation

| Signal | Limit N | Event min N | Event max N | Event RMS N | Full sat. fraction |
|---|---:|---:|---:|---:|---:|
| FsExt_L1 | 3000 | -3000.000 | 3000.000 | 1270.436 | 0.0420639 |
| FsExt_R1 | 3000 | -3000.000 | 3000.000 | 1270.494 | 0.0421305 |
| FsExt_L2 | 2000 | -2000.000 | 2000.000 | 730.729 | 0.0297314 |
| FsExt_R2 | 2000 | -2000.000 | 2000.000 | 730.686 | 0.0296647 |

Warnings: none.

## `2026-06-06_21.45.00.csv`

- Source: `Output/Road-3/T2_pilot_preview/2026-06-06_21.45.00.csv`
- Rows/time: `15001`, `0.000` to `15.000 s`, dt `0.001 s`
- Event window: `6.712` to `10.604 s`, road peak `0.0499285 m`
- Final station/speed: `208.177 m`, `49.9629 km/h`
- Heave peak abs from `Zcg_SM`: `0.0469585 m`
- Pitch/Roll peak abs: `2.7916 deg` / `0.0106059 deg`
- Front/Rear FsExt L-R peak abs: `1819.86 N` / `62.068 N`

### Band RMS

| Signal | Event RMS | 0-4 Hz RMS | 0-15 Hz RMS |
|---|---:|---:|---:|
| Az_SM m/s^2 | 1.52902 | 1.23897 | 1.50975 |
| AA_P rad/s^2 | 2.14727 | 2.05318 | 2.13923 |
| AA_R rad/s^2 | 0.0278654 | 0.00740643 | 0.00881416 |

### Force Saturation

| Signal | Limit N | Event min N | Event max N | Event RMS N | Full sat. fraction |
|---|---:|---:|---:|---:|---:|
| FsExt_L1 | 3000 | -3000.000 | 3000.000 | 1271.794 | 0.0419305 |
| FsExt_R1 | 3000 | -3000.000 | 3000.000 | 1271.392 | 0.0419305 |
| FsExt_L2 | 2000 | -2000.000 | 2000.000 | 738.838 | 0.030598 |
| FsExt_R2 | 2000 | -2000.000 | 2000.000 | 738.811 | 0.0305313 |

Warnings: none.

## `2026-06-07_01.13.06.csv`

- Source: `Output/Road-3/rho5_front_new/T2_pilot_preview/2026-06-07_01.13.06.csv`
- Rows/time: `15001`, `0.000` to `15.000 s`, dt `0.001 s`
- Event window: `6.712` to `10.604 s`, road peak `0.0499285 m`
- Final station/speed: `208.177 m`, `49.9629 km/h`
- Heave peak abs from `Zcg_SM`: `0.0469532 m`
- Pitch/Roll peak abs: `2.79554 deg` / `0.0108156 deg`
- Front/Rear FsExt L-R peak abs: `2087.62 N` / `65.227 N`

### Band RMS

| Signal | Event RMS | 0-4 Hz RMS | 0-15 Hz RMS |
|---|---:|---:|---:|
| Az_SM m/s^2 | 1.53696 | 1.25607 | 1.51968 |
| AA_P rad/s^2 | 2.14497 | 2.05399 | 2.1376 |
| AA_R rad/s^2 | 0.0223028 | 0.00795681 | 0.00930878 |

### Force Saturation

| Signal | Limit N | Event min N | Event max N | Event RMS N | Full sat. fraction |
|---|---:|---:|---:|---:|---:|
| FsExt_L1 | 3000 | -3000.000 | 3000.000 | 1263.572 | 0.0413972 |
| FsExt_R1 | 3000 | -3000.000 | 3000.000 | 1263.568 | 0.0414639 |
| FsExt_L2 | 2000 | -2000.000 | 2000.000 | 739.567 | 0.0306646 |
| FsExt_R2 | 2000 | -2000.000 | 2000.000 | 739.530 | 0.030598 |

Warnings: none.

## `2026-06-07_01.48.32.csv`

- Source: `Output/Road-3/rho5_front1e-4_rear_3e-4/2026-06-07_01.48.32.csv`
- Rows/time: `15001`, `0.000` to `15.000 s`, dt `0.001 s`
- Event window: `6.712` to `10.604 s`, road peak `0.0499285 m`
- Final station/speed: `208.177 m`, `49.9629 km/h`
- Heave peak abs from `Zcg_SM`: `0.0459539 m`
- Pitch/Roll peak abs: `2.7892 deg` / `0.0119488 deg`
- Front/Rear FsExt L-R peak abs: `61.5017 N` / `28.1719 N`

### Band RMS

| Signal | Event RMS | 0-4 Hz RMS | 0-15 Hz RMS |
|---|---:|---:|---:|
| Az_SM m/s^2 | 1.63365 | 1.39991 | 1.62779 |
| AA_P rad/s^2 | 2.09642 | 2.00947 | 2.0924 |
| AA_R rad/s^2 | 0.00969718 | 0.0084951 | 0.0093869 |

### Force Saturation

| Signal | Limit N | Event min N | Event max N | Event RMS N | Full sat. fraction |
|---|---:|---:|---:|---:|---:|
| FsExt_L1 | 3000 | -3000.000 | 3000.000 | 1274.753 | 0.0337977 |
| FsExt_R1 | 3000 | -3000.000 | 3000.000 | 1275.142 | 0.0337977 |
| FsExt_L2 | 2000 | -2000.000 | 2000.000 | 688.015 | 0.0231318 |
| FsExt_R2 | 2000 | -2000.000 | 2000.000 | 688.022 | 0.0231985 |

Warnings: none.

## `2026-06-07_02.22.00.csv`

- Source: `Output/Road-3/bump_safe/T2_pilot_preview/2026-06-07_02.22.00.csv`
- Rows/time: `15001`, `0.000` to `15.000 s`, dt `0.001 s`
- Event window: `6.712` to `10.603 s`, road peak `0.0499285 m`
- Final station/speed: `208.178 m`, `49.9628 km/h`
- Heave peak abs from `Zcg_SM`: `0.0310046 m`
- Pitch/Roll peak abs: `1.43623 deg` / `0.00583579 deg`
- Front/Rear FsExt L-R peak abs: `13.5471 N` / `9.87934 N`

### Band RMS

| Signal | Event RMS | 0-4 Hz RMS | 0-15 Hz RMS |
|---|---:|---:|---:|
| Az_SM m/s^2 | 1.39222 | 0.983129 | 1.38707 |
| AA_P rad/s^2 | 1.13411 | 0.937846 | 1.12619 |
| AA_R rad/s^2 | 0.00332595 | 0.00241682 | 0.00323135 |

### Force Saturation

| Signal | Limit N | Event min N | Event max N | Event RMS N | Full sat. fraction |
|---|---:|---:|---:|---:|---:|
| FsExt_L1 | 3000 | -1197.809 | 1199.996 | 460.394 | 0 |
| FsExt_R1 | 3000 | -1197.599 | 1199.996 | 459.642 | 0 |
| FsExt_L2 | 2000 | -645.973 | 799.999 | 278.640 | 0 |
| FsExt_R2 | 2000 | -643.322 | 799.999 | 279.391 | 0 |

Warnings: none.
