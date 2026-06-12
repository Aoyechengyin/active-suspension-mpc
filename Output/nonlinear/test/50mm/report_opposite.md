# Road-3 Bump Experiment Report

- Cases: `2`
- Event padding: `0.500 s` before, `3.000 s` after
- Force limits: front `3000 N`, rear `2000 N`

## Summary

| Case | Road peak m | Az event RMS m/s^2 | Az 0-4 Hz RMS | Az 0-15 Hz RMS | AA_P 0-15 RMS | AA_R 0-15 RMS | Max FsExt sat. | Rear L-R peak N | Rot min delta |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `active_opposite.csv` | 0.0499285 | 1.11978 | 0.669221 | 1.11226 | 1.18064 | 0.00352894 | 0 | 0 | 84.3312 |
| `passive.csv` | 0.0499285 | 1.11471 | 0.634054 | 1.10743 | 1.16219 | 0.00294742 | 0 | 0 | 84.3309 |

## `active_opposite.csv`

- Source: `E:\Scientific_Research\claude\Output\nonlinear\test\50mm\active_opposite.csv`
- Rows/time: `15001`, `0.000` to `15.000 s`, dt `0.001 s`
- Event window: `6.712` to `10.603 s`, road peak `0.0499285 m`
- Final station/speed: `208.179 m`, `49.9628 km/h`
- Heave peak abs from `Zcg_SM`: `0.0238584 m`
- Pitch/Roll peak abs: `1.33031 deg` / `0.00705892 deg`
- Front/Rear FsExt L-R peak abs: `75 N` / `0 N`

### Band RMS

| Signal | Event RMS | 0-4 Hz RMS | 0-15 Hz RMS |
|---|---:|---:|---:|
| Az_SM m/s^2 | 1.11978 | 0.669221 | 1.11226 |
| AA_P rad/s^2 | 1.18773 | 0.965896 | 1.18064 |
| AA_R rad/s^2 | 0.00380569 | 0.00187464 | 0.00352894 |

### Force Saturation

| Signal | Limit N | Event min N | Event max N | Event RMS N | Full sat. fraction |
|---|---:|---:|---:|---:|---:|
| FsExt_L1 | 3000 | -499.992 | 500.000 | 341.614 | 0 |
| FsExt_R1 | 3000 | -499.993 | 500.000 | 341.828 | 0 |
| FsExt_L2 | 2000 | 0.000 | 0.000 | 0.000 | 0 |
| FsExt_R2 | 2000 | 0.000 | 0.000 | 0.000 | 0 |

Warnings: none.

## `passive.csv`

- Source: `E:\Scientific_Research\claude\Output\nonlinear\test\50mm\passive.csv`
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
