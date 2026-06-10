# Road-3 rho5 Offline Profile

- Profile: `ROAD3_SOFT_F1E4_R3E4`
- Description: Fallback stronger softening trial if the first profile still saturates on T2 pilot.
- Baseline front rho5: 1e-07
- Baseline rear rho5: 0.0001
- Trained front rho5: 0.0001
- Trained rear rho5: 0.0003
- Samples per axle: 8000
- Dry run: 0
- Generated at: 2026-06-07 01:35:55

## Activation

Run `ActivateRoad3Rho5Profile_2020('E:\Scientific_Research\claude\src_2020\road3_rho5_offline\data\ROAD3_SOFT_F1E4_R3E4')` after this profile is trained.
The activation tool backs up the current root MPC assets before copying this profile into `src_2020`.
