# Road-3 T2 50 mm Front500 Gate Direction Compare

- UV_NEG CSV: `Output/nonlinear/T2-50mm-preview-front500_only_UV_ENG/2026-06-11_16.37.18.csv`
- UV_POS CSV: `Output/nonlinear/T2-50mm-preview-front500_only_UV_POS/2026-06-11_16.26.25.csv`
- Event window: `6.704 s` to `10.582 s`.

## Summary

UV_NEG is worse than UV_POS on the main vertical metrics. The correct gate direction for the current sign convention is UV_POS.

## Main Metrics

| Metric | Passive | Front500 | UV_POS | UV_NEG | UV_NEG vs UV_POS |
| --- | ---: | ---: | ---: | ---: | ---: |
| Az event RMS | 1.1167 | 1.2331 | 1.1395 | 1.1945 | +4.83% |
| Az 0-4 RMS | 0.6394 | 0.7995 | 0.6534 | 0.7723 | +18.20% |
| Az 0-15 RMS | 1.1096 | 1.2259 | 1.1321 | 1.1885 | +4.97% |
| Az peak abs | 5.1443 | 6.1232 | 5.3280 | 5.8812 | +10.38% |
| AA_P 0-15 RMS | 1.1644 | 1.1404 | 1.1561 | 1.1714 | +1.32% |
| Zcg heave peak abs | 0.0214 | 0.0249 | 0.0218 | 0.0250 | +14.65% |
| Pitch peak abs | 1.2310 | 1.1818 | 1.2044 | 1.2415 | +3.09% |
| Jnc_L1 min | -36.9751 | -42.8255 | -37.1849 | -43.2834 | -16.40% |
| Jnc_R1 min | -36.8587 | -42.7178 | -37.0779 | -43.1671 | -16.42% |
| Jnc_L2 min | -14.1084 | -14.4138 | -14.1392 | -14.3835 | -1.73% |
| Jnc_R2 min | -13.9880 | -14.2979 | -14.0119 | -14.2636 | -1.80% |

## Gate Output

| Signal | UV_POS peak/RMS/nonzero | UV_NEG peak/RMS/nonzero |
| --- | ---: | ---: |
| FsExt_L1 | 499.98 / 148.93 / 100.0% | 500.00 / 171.37 / 44.8% |
| FsExt_R1 | 499.98 / 143.96 / 100.0% | 500.00 / 170.95 / 44.9% |
| FsExt_L2 | 0.00 / 0.00 / 0.0% | 0.00 / 0.00 / 0.0% |
| FsExt_R2 | 0.00 / 0.00 / 0.0% | 0.00 / 0.00 / 0.0% |

## Decision

Keep `ROAD3_NONLINEAR_FRONT500_GATE_UV_POS` as the current best nonlinear output strategy. Do not use UV_NEG. The remaining gap to Passive is small in Az/heave, while pitch remains slightly better, so the next low-risk refinement is to keep UV_POS and test a lower front limit such as 400 N or 350 N before considering any rear force.