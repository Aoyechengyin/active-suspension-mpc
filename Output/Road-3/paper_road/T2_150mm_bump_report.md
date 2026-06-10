# Road-3 Bump Experiment Report

- Cases: `2`
- Event padding: `0.500 s` before, `3.000 s` after
- Force limits: front `3000 N`, rear `2000 N`

## Summary

| Case | Road peak m | Az event RMS m/s^2 | Az 0-4 Hz RMS | Az 0-15 Hz RMS | AA_P 0-15 RMS | AA_R 0-15 RMS | Max FsExt sat. | Rear L-R peak N | Rot min delta |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `2026-06-07_23.17.21.csv` | 0.149784 | 3.39741 | 2.15439 | 3.12412 | 2.92 | 0.0392557 | 0 | 0 | 84.4979 |
| `2026-06-07_23.23.06.csv` | 0.149784 | 3.43321 | 2.21901 | 3.14948 | 2.95833 | 0.0408193 | 0 | 19.1939 | 84.5062 |

## `2026-06-07_23.17.21.csv`

- Source: `Output/Road-3/paper_road/passive/2026-06-07_23.17.21.csv`
- Rows/time: `15001`, `0.000` to `15.000 s`, dt `0.001 s`
- Event window: `6.711` to `10.613 s`, road peak `0.149784 m`
- Final station/speed: `208.172 m`, `49.963 km/h`
- Heave peak abs from `Zcg_SM`: `0.126351 m`
- Pitch/Roll peak abs: `5.20733 deg` / `0.112909 deg`
- Front/Rear FsExt L-R peak abs: `0 N` / `0 N`

### Band RMS

| Signal | Event RMS | 0-4 Hz RMS | 0-15 Hz RMS |
|---|---:|---:|---:|
| Az_SM m/s^2 | 3.39741 | 2.15439 | 3.12412 |
| AA_P rad/s^2 | 3.08703 | 2.62204 | 2.92 |
| AA_R rad/s^2 | 0.0449439 | 0.0326117 | 0.0392557 |

### Force Saturation

| Signal | Limit N | Event min N | Event max N | Event RMS N | Full sat. fraction |
|---|---:|---:|---:|---:|---:|
| FsExt_L1 | 3000 | 0.000 | 0.000 | 0.000 | 0 |
| FsExt_R1 | 3000 | 0.000 | 0.000 | 0.000 | 0 |
| FsExt_L2 | 2000 | 0.000 | 0.000 | 0.000 | 0 |
| FsExt_R2 | 2000 | 0.000 | 0.000 | 0.000 | 0 |

Warnings: none.

## `2026-06-07_23.23.06.csv`

- Source: `Output/Road-3/paper_road/T2_150mm_preview/2026-06-07_23.23.06.csv`
- Rows/time: `15001`, `0.000` to `15.000 s`, dt `0.001 s`
- Event window: `6.711` to `10.613 s`, road peak `0.149784 m`
- Final station/speed: `208.172 m`, `49.963 km/h`
- Heave peak abs from `Zcg_SM`: `0.128449 m`
- Pitch/Roll peak abs: `5.27912 deg` / `0.117494 deg`
- Front/Rear FsExt L-R peak abs: `170.689 N` / `19.1939 N`

### Band RMS

| Signal | Event RMS | 0-4 Hz RMS | 0-15 Hz RMS |
|---|---:|---:|---:|
| Az_SM m/s^2 | 3.43321 | 2.21901 | 3.14948 |
| AA_P rad/s^2 | 3.1288 | 2.66492 | 2.95833 |
| AA_R rad/s^2 | 0.0487874 | 0.0345877 | 0.0408193 |

### Force Saturation

| Signal | Limit N | Event min N | Event max N | Event RMS N | Full sat. fraction |
|---|---:|---:|---:|---:|---:|
| FsExt_L1 | 3000 | -992.078 | 999.973 | 285.958 | 0 |
| FsExt_R1 | 3000 | -992.584 | 999.976 | 286.497 | 0 |
| FsExt_L2 | 2000 | -500.249 | 649.922 | 196.022 | 0 |
| FsExt_R2 | 2000 | -500.211 | 649.922 | 196.353 | 0 |

Warnings: none.
