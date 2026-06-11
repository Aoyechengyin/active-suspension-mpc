# Road-3 T2 50 mm Nonlinear Front-Only vs Passive

- Passive CSV: `Output/nonlinear/T2-50mm-passive/2026-06-11_15.14.34.csv`
- Nonlinear front-only CSV: `Output/nonlinear/T2-50mm-preview-front_only/2026-06-11_15.47.01.csv`
- Invalidated earlier active CSV: `Output/nonlinear/T2-50mm-preview/2026-06-11_15.07.05.csv` used `src_2020` wrapper path, so it is not treated as a nonlinear-controller result.
- Road file: `Carsim参数集/3D路况文件/Road3_T2_long_50mm_pilot_210m_0p05m.csv`
- Event window: `6.704 s` to `10.582 s`; road peak `0.050000 m` at `101.25 m`.

## Summary

Rear output is correctly disabled.
Front-only nonlinear reduces pitch and keeps rear active force at zero, but it substantially worsens vertical acceleration and front rebound travel relative to Passive. This points to front-force phase/output shaping as the next issue, not rear-channel coupling alone.

## Main Metrics

| Metric | Passive | Nonlinear front-only | Change |
| --- | ---: | ---: | ---: |
| Az event RMS | 1.1167 | 1.3669 | +22.40% |
| Az 0-4 RMS | 0.6394 | 0.9671 | +51.25% |
| Az 0-15 RMS | 1.1096 | 1.3610 | +22.66% |
| Az peak abs | 5.1443 | 6.4953 | +26.26% |
| AA_P 0-15 RMS | 1.1644 | 1.0840 | -6.91% |
| Zcg heave peak abs | 0.0214 | 0.0272 | +27.27% |
| Pitch peak abs | 1.2310 | 1.0698 | -13.10% |
| Jnc_L1 min | -36.9751 | -47.2093 | -27.68% |
| Jnc_R1 min | -36.8587 | -47.1097 | -27.81% |
| Jnc_L2 min | -14.1084 | -14.6907 | -4.13% |
| Jnc_R2 min | -13.9880 | -14.5661 | -4.13% |

## Az Band RMS

| Band | Passive | Nonlinear front-only | Change |
| --- | ---: | ---: | ---: |
| 0-2 RMS | 0.3590 | 0.5127 | +42.81% |
| 2-4 RMS | 0.5291 | 0.8200 | +54.98% |
| 4-8 RMS | 0.8211 | 0.8763 | +6.73% |
| 8-15 RMS | 0.3849 | 0.3862 | +0.34% |

## Controller Output

| Signal | Peak abs (N) | RMS (N) | >=95% limit | >=99% limit |
| --- | ---: | ---: | ---: | ---: |
| FsExt_L1 | 999.99 | 378.57 | 8.33% | 5.52% |
| FsExt_R1 | 999.99 | 377.56 | 8.33% | 5.52% |
| FsExt_L2 | 0.00 | 0.00 | 0.00% | 0.00% |
| FsExt_R2 | 0.00 | 0.00 | 0.00% | 0.00% |

## Tire Load and Stops

| Metric | Passive | Nonlinear front-only | Change |
| --- | ---: | ---: | ---: |
| Fz_L1 <=0 frac | 0.00% | 0.00% | +0.00 pp |
| Fz_R1 <=0 frac | 0.00% | 0.00% | +0.00 pp |
| Fz_L2 <=0 frac | 2.63% | 2.66% | +0.03 pp |
| Fz_R2 <=0 frac | 2.63% | 2.68% | +0.05 pp |
| FJSt_L1 peak abs | 0.00 | 0.00 | 0.00 |
| FJSt_R1 peak abs | 0.00 | 0.00 | 0.00 |
| FJSt_L2 peak abs | 0.00 | 0.00 | 0.00 |
| FJSt_R2 peak abs | 0.00 | 0.00 | 0.00 |
| FRSt_L1 peak abs | 0.00 | 0.00 | 0.00 |
| FRSt_R1 peak abs | 0.00 | 0.00 | 0.00 |
| FRSt_L2 peak abs | 0.00 | 0.00 | 0.00 |
| FRSt_R2 peak abs | 0.00 | 0.00 | 0.00 |

## Phase Notes

| Signal | Passive peak time/value | Front-only peak time/value |
| --- | ---: | ---: |
| Az_SM | 7.396 s / -5.1443 | 7.674 s / 6.4953 |
| AA_P | 7.464 s / 5.6070 | 7.464 s / 6.0606 |
| FsExt_L1 | 6.704 s / 0.0000 | 7.424 s / 999.9936 |
| FsExt_L2 | 6.704 s / 0.0000 | 6.704 s / 0.0000 |

## Decision

Do not add rear force back yet. The rear channel was not the only cause: with rear force disabled, front-only still increases `Az event RMS` by 22.40% and `Az 0-4 RMS` by 51.25%. The next diagnostic should reduce or gate front output, or compare no-preview/front-output sign before attempting `ROAD3_NONLINEAR_BOTH_REAR400_TIGHT`.