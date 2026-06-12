# Road-3 Bump Experiment Report

- Cases: `2`
- Event padding: `0.500 s` before, `3.000 s` after
- Force limits: front `3000 N`, rear `2000 N`

## Summary

| Case | Road peak m | Az event RMS m/s^2 | Az 0-4 Hz RMS | Az 0-15 Hz RMS | AA_P 0-15 RMS | AA_R 0-15 RMS | Max FsExt sat. | Rear L-R peak N | Rot min delta |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `active.csv` | 0.103758 | 3.73341 | 1.66424 | 3.67875 | 3.39557 | 0.0264875 | 0 | 0 | 84.5337 |
| `passive.csv` | 0.103758 | 3.69841 | 1.62653 | 3.64461 | 3.39286 | 0.03568 | 0 | 0 | 84.5346 |

## `active.csv`

- Source: `E:\Scientific_Research\claude\Output\nonlinear\test\active.csv`
- Rows/time: `15001`, `0.000` to `15.000 s`, dt `0.001 s`
- Event window: `0.000` to `15.000 s`, road peak `0.103758 m`
- Final station/speed: `208.126 m`, `49.9533 km/h`
- Heave peak abs from `Zcg_SM`: `0.105023 m`
- Pitch/Roll peak abs: `2.00717 deg` / `0.0384767 deg`
- Front/Rear FsExt L-R peak abs: `114.715 N` / `0 N`

### Band RMS

| Signal | Event RMS | 0-4 Hz RMS | 0-15 Hz RMS |
|---|---:|---:|---:|
| Az_SM m/s^2 | 3.73341 | 1.66424 | 3.67875 |
| AA_P rad/s^2 | 3.44462 | 1.72982 | 3.39557 |
| AA_R rad/s^2 | 0.0309023 | 0.0149812 | 0.0264875 |

### Force Saturation

| Signal | Limit N | Event min N | Event max N | Event RMS N | Full sat. fraction |
|---|---:|---:|---:|---:|---:|
| FsExt_L1 | 3000 | -499.999 | 500.000 | 227.876 | 0 |
| FsExt_R1 | 3000 | -499.999 | 500.000 | 229.725 | 0 |
| FsExt_L2 | 2000 | 0.000 | 0.000 | 0.000 | 0 |
| FsExt_R2 | 2000 | 0.000 | 0.000 | 0.000 | 0 |

Warnings: none.

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
