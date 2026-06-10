# Road-3 Pilot Preview Result Analysis

Generated from raw CarSim CSVs using Python fallback because command-line MATLAB still exits at startup with `File system inconsistency`.

## Executive Conclusion

- `T1_pilot_preview` is dynamically stable, but it is **not a valid Road-3 Test 1 pilot** because the CSV speed is `49.96 km/h` while the plan requires `30 km/h`.
- `T2_pilot_preview` needs attention before full-amplitude escalation; see failed flags below.
- `T2_passive` has now been checked: the same 50 mm road has zero `FJSt_*` / `FRSt_*` stop force when external forces are zero.
- A newer `T2_pilot_preview` export with stop-force columns (`2026-06-06_21.45.00.csv`) shows `FJSt_* = 0 N` and `FRSt_* = 0 N` as well. The earlier `Jnc`-only stop-contact conclusion should be corrected to: active eMPC drives very large front rebound travel, but CarSim stop-force output does not confirm stop-force engagement.
- `T2_no_preview` and `T2_pilot_preview` are nearly identical in T2 50 mm pilot response, so preview timing is not the main cause; the active force strategy is too aggressive for this Road-3 pilot.

## Case Summary

| Case | Speed mean km/h | Expected km/h | Event window s | Road peak m | Az peak g | Az event RMS g | FsExt max abs N | Sat max % | Rear L-R peak N | W1 lead ms | W2 lead ms | Status |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| T1_pilot_preview | 49.96 | 30 | 3.829-7.575 | 0.01000 | 0.3405 | 0.0524 | 3000.0 | 0.227 | 6.88 | 10.00 | 20.00 | STABLE_SPEED_MISMATCH |
| T2_pilot_preview | 49.96 | 50 | 6.711-10.606 | 0.05000 | 1.0510 | 0.1558 | 3000.0 | 4.193 | 62.07 | 10.00 | 20.00 | CHECK |

## Detailed Metrics

### T1_pilot_preview

- Source: `Output/Road-3/T1_pilot_preview/2026-06-06_20.19.19.csv`
- Rows/columns: `15001` / `125`, `dt=0.001000 s`, time `0.000-15.000 s`.
- Speed: `Vx mean=49.963 km/h`, `VxTarget mean=50.000 km/h`, plan `30.0 km/h`.
- Station/Xo end: `Station=208.179 m`, `Xo=208.179 m`, `Yo end=-0.02239 m`.
- Road peak: `max Zgnd/W1/W2=0.010000 m`; event window `3.829-7.575 s`.
- Preview lead by peak time: `W1 mean=10.00 ms`, `W2 mean=20.00 ms`.
- Az_SM: `peak=0.34046 g` (`3.3399 m/s^2`), `event RMS=0.05239 g`, `0-4Hz RMS=0.00675 g`, `0-15Hz RMS=0.04705 g`.
- AA_P/AA_R event peak: `3.357` / `0.155`; event RMS: `0.463` / `0.003`.
- Zcg_SM relative heave in event: min `-0.00075 m`, max `0.00276 m`, peak abs `0.00276 m`.
- Pitch/Roll/Yaw event peak abs: `0.3568 deg`, `0.0021 deg`, `0.0064 deg`; `Yo end=-0.02239 m`.
- FsExt saturation max: `0.2267 %`; front L-R peak `294.012 N`, rear L-R peak `6.881 N`.
- `FsExt_L1: peak 3000.0 N, RMS_event 388.9 N, sat 0.227%`; `FsExt_R1: peak 3000.0 N, RMS_event 387.8 N, sat 0.227%`; `FsExt_L2: peak 1069.6 N, RMS_event 96.5 N, sat 0.000%`; `FsExt_R2: peak 1073.0 N, RMS_event 97.3 N, sat 0.000%`
- `JncR_L1: peak 225.1 mm/s`; `JncR_R1: peak 225.6 mm/s`; `JncR_L2: peak 265.5 mm/s`; `JncR_R2: peak 265.7 mm/s`
- `Rot_L1: delta 84.33, monotonic=True`; `Rot_R1: delta 84.33, monotonic=True`; `Rot_L2: delta 84.36, monotonic=True`; `Rot_R2: delta 84.36, monotonic=True`
- Required Road-3 diagnostic columns are present.

### T2_pilot_preview

- Source: `Output/Road-3/T2_pilot_preview/2026-06-06_20.31.27.csv`; latest stop-force export: `Output/Road-3/T2_pilot_preview/2026-06-06_21.45.00.csv`
- Rows/columns: `15001` / `125`, `dt=0.001000 s`, time `0.000-15.000 s`.
- Speed: `Vx mean=49.963 km/h`, `VxTarget mean=50.000 km/h`, plan `50.0 km/h`.
- Station/Xo end: `Station=208.177 m`, `Xo=208.177 m`, `Yo end=-0.02554 m`.
- Road peak: `max Zgnd/W1/W2=0.050000 m`; event window `6.711-10.606 s`.
- Preview lead by peak time: `W1 mean=10.00 ms`, `W2 mean=20.00 ms`.
- Az_SM: `peak=1.05098 g` (`10.3102 m/s^2`), `event RMS=0.15580 g`, `0-4Hz RMS=0.12620 g`, `0-15Hz RMS=0.15384 g`.
- AA_P/AA_R event peak: `10.006` / `0.972`; event RMS: `2.146` / `0.028`.
- Zcg_SM relative heave in event: min `-0.02703 m`, max `0.04672 m`, peak abs `0.04672 m`.
- Pitch/Roll/Yaw event peak abs: `2.7916 deg`, `0.0106 deg`, `0.0107 deg`; `Yo end=-0.02554 m`.
- FsExt saturation max: `4.1931 %`; front L-R peak `1819.860 N`, rear L-R peak `62.068 N`.
- `FsExt_L1: peak 3000.0 N, RMS_event 1271.3 N, sat 4.193%`; `FsExt_R1: peak 3000.0 N, RMS_event 1270.9 N, sat 4.193%`; `FsExt_L2: peak 2000.0 N, RMS_event 738.6 N, sat 3.060%`; `FsExt_R2: peak 2000.0 N, RMS_event 738.5 N, sat 3.053%`
- `JncR_L1: peak 1259.9 mm/s`; `JncR_R1: peak 1260.0 mm/s`; `JncR_L2: peak 1297.5 mm/s`; `JncR_R2: peak 1295.5 mm/s`
- `Rot_L1: delta 84.34, monotonic=True`; `Rot_R1: delta 84.34, monotonic=True`; `Rot_L2: delta 84.37, monotonic=True`; `Rot_R2: delta 84.37, monotonic=True`
- Required Road-3 diagnostic columns are present.

## Suspension Travel Stop Check

The stop thresholds used for this check are from the current CarSim screenshots:

- Front axle: jounce `+70 mm`, rebound `-50 mm`.
- Rear axle: jounce `+120 mm`, rebound `-60 mm`.

| Case | Wheel | Jnc min mm | Jnc max mm | Jounce margin mm | Rebound margin mm | Interpretation |
|---|---|---:|---:|---:|---:|---|
| T1_pilot_preview | L1/R1 front | -3.73 / -3.69 | 2.01 / 2.05 | about 68 | about 46 | Far from stops |
| T1_pilot_preview | L2/R2 rear | -2.62 / -2.55 | 3.71 / 3.79 | about 116 | about 57 | Far from stops |
| T2_pilot_preview | L1/R1 front | -73.60 / -73.58 | 51.50 / 51.70 | about 18 | about -24 | Large front rebound travel; latest `FRSt_*` remains 0 N |
| T2_pilot_preview | L2/R2 rear | -51.40 / -51.34 | 56.44 / 56.47 | about 64 | about 9 | Close to rear rebound stop, not exceeded |
| T2_passive | L1/R1 front | -36.98 / -36.86 | 39.75 / 39.85 | about 30 | about 13 | No stop contact |
| T2_passive | L2/R2 rear | -14.11 / -13.99 | 30.69 / 30.84 | about 89 | about 46 | No stop contact |

This matters for the controller interpretation. The current mp-QP model is linear and does not include jounce/rebound travel constraints. Since passive stays at about `-37 mm` front `Jnc` while both no-preview and preview go to about `-73.6 mm`, the immediate suspect is the active force command pushing the front suspension into excessive rebound travel, rather than the 50 mm road by itself.

The latest passive, no-preview, and preview CSVs export `FJSt_*` and `FRSt_*`; all stop forces are zero in these T2 50 mm pilot runs. Therefore, do not treat the screenshot rebound range alone as proof of CarSim stop-force engagement. Keep `FJSt_*` / `FRSt_*`, and add `CmpRSt*` / `CmpJSt*` if the stop-transform mapping must be audited.

Passive vs preview on the same T2 50 mm road:

- `Az_SM` event peak: passive `0.524 g`, preview `1.051 g`.
- `Pitch` event peak: passive `1.231 deg`, preview `2.792 deg`.
- Front `Jnc` minimum: passive about `-37 mm`, preview about `-73.6 mm`.
- Passive/no-preview/latest-preview `FJSt_*` and `FRSt_*`: all `0 N`.

## Next Step

- Re-run `T1_pilot_preview` with CarSim constant target speed set to `30 km/h`; keep the same Road3_T1_short_10mm_pilot road file and preview VS Command.
- Do not directly proceed from the current `T2_pilot_preview` to `T2_long_150mm` full-amplitude yet under the strict pilot gate. The 50 mm pilot already has force saturation above the planned `<1%` pilot threshold.
- For T2, run `eMPC no-preview` with the stop-force exports added. Passive has already shown that the road alone does not force stop contact.
- The no-preview VS Command must use explicit wheel variables (`X_L1`, `X_R1`, `X_L2`, `X_R2`) rather than the documentation placeholder `X_*`.
- If no-preview does not hit the front rebound stop but preview does, inspect preview road-state construction and front force timing before changing vehicle travel.
- If both no-preview and preview hit the front rebound stop, retune the active force command conservatively before proceeding to 150 mm full amplitude.
- For full Road-3, keep running `Passive`, `no-preview`, and `preview` as separate outputs; then use the Road-3 comparison script on the three files for each test.
