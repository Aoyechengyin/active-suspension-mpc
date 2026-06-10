# Road-3 T2 Pilot Bump-Safe Tight Compare

- New case: `Output/Road-3/bump_safe_tight/T2_pilot_preview/2026-06-07_19.48.05.csv`
- Baselines:
  - Passive: `Output/Road-3/T2_passive/2026-06-06_21.18.39.csv`
  - B3 preview: `Output/Road-3/T2_pilot_preview/2026-06-06_21.45.00.csv`
  - Bump-safe 1200/800: `Output/Road-3/bump_safe/T2_pilot_preview/2026-06-07_02.22.00.csv`
- Event window: `6.712 s` to `10.603 s`
- Road peak: `0.04992849 m`
- Tight soft limits: front `1000 N`, rear `650 N`

## Summary

| Case | Az event RMS | Az 0-4 Hz RMS | Az 0-15 Hz RMS | AA_P 0-15 RMS | Heave peak m | Pitch peak deg | front Jnc min | rear Jnc min | cfg sat max | soft sat event |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Passive | `1.11471` | `0.63405` | `1.10743` | `1.16219` | `0.02208` | `1.23098` | `-36.98` | `-14.11` | `0.00%` | `0.00%` |
| B3 preview | `1.52902` | `1.23897` | `1.50975` | `2.13923` | `0.04696` | `2.79160` | `-73.60` | `-51.39` | `4.19%` | `16.16%` |
| bump-safe 1200/800 | `1.39222` | `0.98313` | `1.38707` | `1.12619` | `0.03100` | `1.43623` | `-50.34` | `-31.14` | `0.00%` | `3.91%` |
| bump-safe tight 1000/650 | `1.33433` | `0.91209` | `1.32894` | `1.11573` | `0.02892` | `1.34998` | `-47.64` | `-28.06` | `0.00%` | `5.29%` |

## Force Checks

| Case | front FsExt peak N | rear FsExt peak N | front L-R peak N | rear L-R peak N | soft sat full | FJSt/FRSt peak N |
|---|---:|---:|---:|---:|---:|---:|
| B3 preview | `3000.00` | `2000.00` | `1819.86` | `62.07` | `4.19%` | `0.00` |
| bump-safe 1200/800 | `1200.00` | `800.00` | `13.55` | `9.88` | `1.01%` | `0.00` |
| bump-safe tight 1000/650 | `1000.00` | `650.00` | `17.36` | `14.33` | `1.37%` | `0.00` |

## Decision

The tight profile improves the physical response relative to the first bump-safe run:

- `Az_SM` 0-15 Hz RMS: `1.38707 -> 1.32894`
- `AA_P` 0-15 Hz RMS: `1.12619 -> 1.11573`
- heave peak: `0.03100 m -> 0.02892 m`
- pitch peak: `1.43623 deg -> 1.34998 deg`
- front rebound travel min: `-50.34 -> -47.64`
- rear rebound travel min: `-31.14 -> -28.06`

However, the controller now spends more time on the new lower soft limits:

- event soft saturation: `3.91% -> 5.29%`
- full soft saturation: `1.01% -> 1.37%`

This means the second-stage tightening is useful as a conservative Road-3 pilot guard, but it should not be tightened further. The active response is still worse than Passive in vertical acceleration and heave, while it is slightly better than Passive in pitch acceleration (`AA_P`). For Road-3 T2 full, this profile is safer than B3 preview, but the full-amplitude 150 mm bump still needs a separate cautious pilot/full decision.

Recommended next action:

1. Keep `ROAD3_BUMP_SAFE` at `front=1000 N`, `rear=650 N`, `front rate=15000 N/s`, `rear rate=9000 N/s`.
2. Do not reduce force limits further.
3. Use this profile for the next Road-3 active run, and compare against Passive before claiming active-control improvement.
