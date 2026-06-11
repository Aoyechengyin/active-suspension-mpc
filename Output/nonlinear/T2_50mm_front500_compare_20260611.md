# Road-3 T2 50 mm Nonlinear Front500 Diagnostic

- Passive CSV: `Output/nonlinear/T2-50mm-passive/2026-06-11_15.14.34.csv`
- Front1000-only CSV: `Output/nonlinear/T2-50mm-preview-front_only/2026-06-11_15.47.01.csv`
- Front500-only CSV: `Output/nonlinear/T2-50mm-preview-front500_only/2026-06-11_16.08.22.csv`
- Road file: `Carsim参数集/3D路况文件/Road3_T2_long_50mm_pilot_210m_0p05m.csv`
- Event window: `6.704 s` to `10.582 s`; road peak `0.050000 m` at `101.25 m`.

## Summary

Front500-only reduces the damage caused by Front1000-only, but it still does not beat Passive on the main vertical body metrics. It keeps part of the pitch benefit with smaller Az/heave/front-rebound penalties than 1000 N.

## Main Metrics

| Metric | Passive | Front1000 only | Front500 only | Front500 vs Passive | Front500 vs Front1000 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Az event RMS | 1.1167 | 1.3669 | 1.2331 | +10.42% | -9.79% |
| Az 0-4 RMS | 0.6394 | 0.9671 | 0.7995 | +25.04% | -17.33% |
| Az 0-15 RMS | 1.1096 | 1.3610 | 1.2259 | +10.49% | -9.92% |
| Az peak abs | 5.1443 | 6.4953 | 6.1232 | +19.03% | -5.73% |
| AA_P 0-15 RMS | 1.1644 | 1.0840 | 1.1404 | -2.06% | +5.20% |
| Zcg heave peak abs | 0.0214 | 0.0272 | 0.0249 | +16.65% | -8.34% |
| Pitch peak abs | 1.2310 | 1.0698 | 1.1818 | -4.00% | +10.47% |
| Jnc_L1 min | -36.9751 | -47.2093 | -42.8255 | -15.82% | +9.29% |
| Jnc_R1 min | -36.8587 | -47.1097 | -42.7178 | -15.90% | +9.32% |
| Jnc_L2 min | -14.1084 | -14.6907 | -14.4138 | -2.16% | +1.88% |
| Jnc_R2 min | -13.9880 | -14.5661 | -14.2979 | -2.22% | +1.84% |

## Az Band RMS

| Band | Passive | Front1000 only | Front500 only | Front500 vs Passive | Front500 vs Front1000 |
| --- | ---: | ---: | ---: | ---: | ---: |
| 0-2 RMS | 0.3590 | 0.5127 | 0.4185 | +16.55% | -18.39% |
| 2-4 RMS | 0.5291 | 0.8200 | 0.6812 | +28.76% | -16.92% |
| 4-8 RMS | 0.8211 | 0.8763 | 0.8415 | +2.49% | -3.98% |
| 8-15 RMS | 0.3849 | 0.3862 | 0.3945 | +2.51% | +2.17% |

## Front500 Controller Output

| Signal | Peak abs (N) | RMS (N) | >=95% limit | >=99% limit |
| --- | ---: | ---: | ---: | ---: |
| FsExt_L1 | 500.00 | 215.86 | 11.27% | 8.66% |
| FsExt_R1 | 500.00 | 213.16 | 11.19% | 8.59% |
| FsExt_L2 | 0.00 | 0.00 | 0.00% | 0.00% |
| FsExt_R2 | 0.00 | 0.00 | 0.00% | 0.00% |

## Tire Load and Stops

| Metric | Passive | Front500 only | Change |
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

| Signal | Passive peak time/value | Front500 peak time/value |
| --- | ---: | ---: |
| Az_SM | 7.396 s / -5.1443 | 7.670 s / 6.1232 |
| AA_P | 7.464 s / 5.6070 | 7.464 s / 5.8863 |
| FsExt_L1 | 6.704 s / 0.0000 | 7.431 s / 499.9996 |
| FsExt_L2 | 6.704 s / 0.0000 | 6.704 s / 0.0000 |

## Decision

Front500-only is safer than Front1000-only, but it is still not a candidate for final paper runs because `Az event RMS`, `Az 0-15 RMS`, and heave remain worse than Passive. Since lowering the limit helped but did not solve the phase/energy issue, the next controlled experiment should be `ROAD3_NONLINEAR_FRONT500_GATE_UV_POS` and `ROAD3_NONLINEAR_FRONT500_GATE_UV_NEG` on the same T2 50 mm pilot road.