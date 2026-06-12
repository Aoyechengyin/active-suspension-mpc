# Road-3 Bump Experiment Report

- Cases: `2`
- Event padding: `0.500 s` before, `3.000 s` after
- Force limits: front `3000 N`, rear `2000 N`

## Summary

| Case | Road peak m | Az event RMS m/s^2 | Az 0-4 Hz RMS | Az 0-15 Hz RMS | AA_P 0-15 RMS | AA_R 0-15 RMS | Max FsExt sat. | Rear L-R peak N | Rot min delta |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `passive.csv` | 0.103758 | 3.69841 | 1.62653 | 3.64461 | 3.39286 | 0.03568 | 0 | 0 | 84.5346 |
| `active_opposite.csv` | 0.103758 | 3.65705 | 1.59066 | 3.60375 | 3.40136 | 0.0236945 | 0 | 0 | 84.5342 |

## `passive.csv`

- Source: `E:\Scientific_Research\claude\Output\nonlinear\test\passive.csv`
- Rows/time: `15001`, `0.000` to `15.000 s`, dt `0.001 s`
- Event window: `0.000` to `15.000 s`, road peak `0.103758 m`
- Final station/speed: `208.126 m`, `49.9534 km/h`
- Heave peak abs from `Zcg_SM`: `0.105023 m`
- Pitch/Roll peak abs: `2.01264 deg` / `0.0418313 deg`
- Front/Rear FsExt L-R peak abs: `0 N` / `0 N`

### Band RMS

| Signal | Event RMS | 0-4 Hz RMS | 0-15 Hz RMS |
|---|---:|---:|---:|
| Az_SM m/s^2 | 3.69841 | 1.62653 | 3.64461 |
| AA_P rad/s^2 | 3.4427 | 1.72486 | 3.39286 |
| AA_R rad/s^2 | 0.0392188 | 0.0230696 | 0.03568 |

### Force Saturation

| Signal | Limit N | Event min N | Event max N | Event RMS N | Full sat. fraction |
|---|---:|---:|---:|---:|---:|
| FsExt_L1 | 3000 | 0.000 | 0.000 | 0.000 | 0 |
| FsExt_R1 | 3000 | 0.000 | 0.000 | 0.000 | 0 |
| FsExt_L2 | 2000 | 0.000 | 0.000 | 0.000 | 0 |
| FsExt_R2 | 2000 | 0.000 | 0.000 | 0.000 | 0 |

Warnings: none.

## `active_opposite.csv`

- Source: `E:\Scientific_Research\claude\Output\nonlinear\test\active_opposite.csv`
- Rows/time: `15001`, `0.000` to `15.000 s`, dt `0.001 s`
- Event window: `0.000` to `15.000 s`, road peak `0.103758 m`
- Final station/speed: `208.126 m`, `49.9534 km/h`
- Heave peak abs from `Zcg_SM`: `0.105023 m`
- Pitch/Roll peak abs: `2.02228 deg` / `0.0383525 deg`
- Front/Rear FsExt L-R peak abs: `76.9148 N` / `0 N`

### Band RMS

| Signal | Event RMS | 0-4 Hz RMS | 0-15 Hz RMS |
|---|---:|---:|---:|
| Az_SM m/s^2 | 3.65705 | 1.59066 | 3.60375 |
| AA_P rad/s^2 | 3.4518 | 1.73152 | 3.40136 |
| AA_R rad/s^2 | 0.0271462 | 0.0127591 | 0.0236945 |

### Force Saturation

| Signal | Limit N | Event min N | Event max N | Event RMS N | Full sat. fraction |
|---|---:|---:|---:|---:|---:|
| FsExt_L1 | 3000 | -500.000 | 500.000 | 254.869 | 0 |
| FsExt_R1 | 3000 | -500.000 | 500.000 | 255.536 | 0 |
| FsExt_L2 | 2000 | 0.000 | 0.000 | 0.000 | 0 |
| FsExt_R2 | 2000 | 0.000 | 0.000 | 0.000 | 0 |

Warnings: none.
