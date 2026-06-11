# Road-3 T2 50 mm Nonlinear Preview vs Passive

- Passive CSV: `Output/nonlinear/T2-50mm-passive/2026-06-11_15.14.34.csv`
- Nonlinear preview CSV: `Output/nonlinear/T2-50mm-preview/2026-06-11_15.07.05.csv`
- Road file: `Carsim参数集/3D路况文件/Road3_T2_long_50mm_pilot_210m_0p05m.csv`
- Event window: `6.712 s` to `10.603 s`
- Road peak: `0.049928 m`

## Summary

The nonlinear preview controller did not beat Passive overall in this T2 50 mm pilot run.

It improved low-frequency vertical acceleration slightly, but worsened total/event acceleration, 0-15 Hz acceleration, pitch peak, heave peak, rear rebound travel, and rear wheel unloading time. Stop forces stayed zero, so the long-travel suspension avoided jounce/rebound stop contact in this pilot case.

## Main Metrics

| Metric | Passive | Nonlinear preview | Change |
| --- | ---: | ---: | ---: |
| Az event RMS (m/s^2) | 1.1147 | 1.1653 | +4.54% |
| Az 0-4 Hz RMS (m/s^2) | 0.6341 | 0.6036 | -4.81% |
| Az 0-15 Hz RMS (m/s^2) | 1.1074 | 1.1585 | +4.61% |
| Az peak abs (m/s^2) | 5.1443 | 5.6406 | +9.65% |
| AA_P 0-15 Hz RMS | 1.1622 | 1.1679 | +0.49% |
| Zcg_SM heave peak abs (m) | 0.02148 | 0.02186 | +1.78% |
| Pitch peak abs (deg) | 1.2310 | 1.3501 | +9.68% |
| Front Jnc min | -36.98 | -37.18 | worse by 0.21 |
| Front Jnc max | 39.85 | 40.48 | worse by 0.63 |
| Rear Jnc min | -14.11 | -23.11 | worse by 9.00 |
| Rear Jnc max | 30.84 | 27.99 | better by 2.85 |
| FJSt peak (N) | 0 | 0 | unchanged |
| FRSt peak (N) | 0 | 0 | unchanged |
| Rear Fz <= 0 fraction, each rear wheel | 2.62% | 2.85% | worse |

## Controller Output

| Signal | Peak abs (N) | RMS (N) | >=99% limit | >=95% limit |
| --- | ---: | ---: | ---: | ---: |
| FsExt_L1 | 997.34 | 208.01 | 0.51% | 1.23% |
| FsExt_R1 | 997.39 | 204.67 | 0.54% | 1.23% |
| FsExt_L2 | 649.27 | 146.60 | 1.16% | 2.06% |
| FsExt_R2 | 649.30 | 146.70 | 1.16% | 2.06% |

The controller is reaching the tight output limits, especially at the rear. Rear left-right force difference is small (`11.65 N` peak), so the issue is not left-right imbalance.

## Phase Notes

| Signal | Passive peak time | Nonlinear preview peak time |
| --- | ---: | ---: |
| Az_SM | 7.396 s | 7.674 s |
| AA_P | 7.464 s | 7.464 s |
| FsExt_L1 | 6.712 s | 7.692 s |
| FsExt_L2 | 6.712 s | 7.682 s |

In the active run, force peaks occur almost together with the active vertical acceleration peak, and after the passive acceleration peak. This suggests the nonlinear preview output is injecting force during the rear-body response rather than suppressing the dominant event energy.

## Decision

Do not proceed to T1 full or T2 150 mm full with this exact nonlinear-preview setup as the candidate final controller.

Recommended next check:

1. Confirm the shadow wrappers are active with `which per_corner_mpc_L1_2020`.
2. Run the same nonlinear trained data with Passive-zero calibration disabled only for a no-preview/low-output diagnostic, or temporarily lower rear output limit to test whether rear rebound worsening is caused by the rear force channel.
3. If keeping this nonlinear branch, tune the output layer before retraining the full region set: rear force timing/limit is now the main suspect, not stop contact.
