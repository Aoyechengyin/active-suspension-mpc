# Road-3 T2 50 mm Front400 UV_POS Diagnostic

- Front400 CSV: `Output/nonlinear/T2-50mm-preview-front400_only_UV_POS/2026-06-11_16.43.43.csv`
- Front500 CSV: `Output/nonlinear/T2-50mm-preview-front500_only_UV_POS/2026-06-11_16.26.25.csv`
- Event window: `6.704 s` to `10.582 s`.

## Summary

Front400 UV_POS is closer to Passive in vertical acceleration than Front500 UV_POS, but it gives back most of the pitch improvement. It is currently the best comfort-safe candidate among nonlinear active runs for T2 50 mm pilot.

## Main Metrics

| Metric | Passive | UV_POS 500 | UV_POS 400 | 400 vs Passive | 400 vs 500 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Az event RMS | 1.1167 | 1.1395 | 1.1327 | +1.43% | -0.59% |
| Az 0-4 RMS | 0.6394 | 0.6534 | 0.6530 | +2.12% | -0.06% |
| Az 0-15 RMS | 1.1096 | 1.1321 | 1.1253 | +1.42% | -0.60% |
| Az peak abs | 5.1443 | 5.3280 | 5.2770 | +2.58% | -0.96% |
| AA_P 0-15 RMS | 1.1644 | 1.1561 | 1.1598 | -0.40% | +0.32% |
| Zcg heave peak abs | 0.0214 | 0.0218 | 0.0219 | +2.36% | +0.06% |
| Pitch peak abs | 1.2310 | 1.2044 | 1.2088 | -1.80% | +0.36% |
| Jnc_L1 min | -36.9751 | -37.1849 | -37.2119 | -0.64% | -0.07% |
| Jnc_R1 min | -36.8587 | -37.0779 | -37.0869 | -0.62% | -0.02% |
| Jnc_L2 min | -14.1084 | -14.1392 | -14.1223 | -0.10% | +0.12% |
| Jnc_R2 min | -13.9880 | -14.0119 | -14.0200 | -0.23% | -0.06% |

## Az Band RMS

| Band | Passive | UV_POS 500 | UV_POS 400 | 400 vs Passive | 400 vs 500 |
| --- | ---: | ---: | ---: | ---: | ---: |
| 0-2 RMS | 0.3590 | 0.3401 | 0.3428 | -4.51% | +0.80% |
| 2-4 RMS | 0.5291 | 0.5579 | 0.5557 | +5.03% | -0.38% |
| 4-8 RMS | 0.8211 | 0.8375 | 0.8293 | +1.01% | -0.97% |
| 8-15 RMS | 0.3849 | 0.3917 | 0.3901 | +1.37% | -0.40% |

## Front400 Output

| Signal | Peak abs (N) | RMS (N) | Nonzero | >=95% limit |
| --- | ---: | ---: | ---: | ---: |
| FsExt_L1 | 399.99 | 132.37 | 100.0% | 2.91% |
| FsExt_R1 | 399.99 | 127.02 | 100.0% | 2.94% |
| FsExt_L2 | 0.00 | 0.00 | 0.0% | 0.00% |
| FsExt_R2 | 0.00 | 0.00 | 0.0% | 0.00% |

## Tire Load and Stops

| Metric | Passive | UV_POS 400 | Change |
| --- | ---: | ---: | ---: |
| Fz_L1 <=0 frac | 0.00% | 0.00% | +0.00 pp |
| Fz_R1 <=0 frac | 0.00% | 0.00% | +0.00 pp |
| Fz_L2 <=0 frac | 2.63% | 2.63% | +0.00 pp |
| Fz_R2 <=0 frac | 2.63% | 2.63% | +0.00 pp |
| FJSt_L1 peak abs | 0.00 | 0.00 | 0.00 |
| FJSt_R1 peak abs | 0.00 | 0.00 | 0.00 |
| FJSt_L2 peak abs | 0.00 | 0.00 | 0.00 |
| FJSt_R2 peak abs | 0.00 | 0.00 | 0.00 |
| FRSt_L1 peak abs | 0.00 | 0.00 | 0.00 |
| FRSt_R1 peak abs | 0.00 | 0.00 | 0.00 |
| FRSt_L2 peak abs | 0.00 | 0.00 | 0.00 |
| FRSt_R2 peak abs | 0.00 | 0.00 | 0.00 |

## Decision

Keep `ROAD3_NONLINEAR_FRONT400_GATE_UV_POS` as the current best T2 50 mm nonlinear candidate if the priority is not worsening Passive comfort. If the priority is visible active improvement, 500 N UV_POS has slightly better pitch but worse Az/heave. Before moving to 150 mm, run one intermediate `ROAD3_NONLINEAR_FRONT450_GATE_UV_POS` or accept 400 N as the conservative candidate.