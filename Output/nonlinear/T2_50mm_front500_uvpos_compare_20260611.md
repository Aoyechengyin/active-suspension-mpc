# Road-3 T2 50 mm Front500 UV_POS Diagnostic

- Passive CSV: `Output/nonlinear/T2-50mm-passive/2026-06-11_15.14.34.csv`
- Front500 CSV: `Output/nonlinear/T2-50mm-preview-front500_only/2026-06-11_16.08.22.csv`
- UV_POS CSV: `Output/nonlinear/T2-50mm-preview-front500_only_UV_POS/2026-06-11_16.26.25.csv`
- Event window: `6.704 s` to `10.582 s`.

## Summary

UV_POS improves the ungated Front500 result on event vertical acceleration, but it must still be compared against Passive before being promoted.

## Main Metrics

| Metric | Passive | Front500 | UV_POS | UV_POS vs Passive | UV_POS vs Front500 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Az event RMS | 1.1167 | 1.2331 | 1.1395 | +2.04% | -7.59% |
| Az 0-4 RMS | 0.6394 | 0.7995 | 0.6534 | +2.19% | -18.27% |
| Az 0-15 RMS | 1.1096 | 1.2259 | 1.1321 | +2.03% | -7.65% |
| Az peak abs | 5.1443 | 6.1232 | 5.3280 | +3.57% | -12.99% |
| AA_P 0-15 RMS | 1.1644 | 1.1404 | 1.1561 | -0.71% | +1.38% |
| Zcg heave peak abs | 0.0214 | 0.0249 | 0.0218 | +2.30% | -12.31% |
| Pitch peak abs | 1.2310 | 1.1818 | 1.2044 | -2.16% | +1.91% |
| Jnc_L1 min | -36.9751 | -42.8255 | -37.1849 | -0.57% | +13.17% |
| Jnc_R1 min | -36.8587 | -42.7178 | -37.0779 | -0.59% | +13.20% |
| Jnc_L2 min | -14.1084 | -14.4138 | -14.1392 | -0.22% | +1.91% |
| Jnc_R2 min | -13.9880 | -14.2979 | -14.0119 | -0.17% | +2.00% |

## Az Band RMS

| Band | Passive | Front500 | UV_POS | UV_POS vs Passive | UV_POS vs Front500 |
| --- | ---: | ---: | ---: | ---: | ---: |
| 0-2 RMS | 0.3590 | 0.4185 | 0.3401 | -5.26% | -18.72% |
| 2-4 RMS | 0.5291 | 0.6812 | 0.5579 | +5.44% | -18.11% |
| 4-8 RMS | 0.8211 | 0.8415 | 0.8375 | +2.00% | -0.47% |
| 8-15 RMS | 0.3849 | 0.3945 | 0.3917 | +1.78% | -0.72% |

## UV_POS Controller Output

| Signal | Peak abs (N) | RMS (N) | Nonzero fraction | >=95% limit |
| --- | ---: | ---: | ---: | ---: |
| FsExt_L1 | 499.98 | 148.93 | 100.00% | 2.76% |
| FsExt_R1 | 499.98 | 143.96 | 100.00% | 2.76% |
| FsExt_L2 | 0.00 | 0.00 | 0.00% | 0.00% |
| FsExt_R2 | 0.00 | 0.00 | 0.00% | 0.00% |

## Tire Load and Stops

| Metric | Passive | UV_POS | Change |
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

If UV_POS is still worse than Passive and worse than Front500, switch to `ROAD3_NONLINEAR_FRONT500_GATE_UV_NEG`. If UV_POS improves Front500 but still loses to Passive, keep the better gate direction and then tune front limit below 500 N.