# Road-3 Full-Q Offline Profile

- Profile: `ROAD3_Q_COMFORT_C`
- Description: Road-3 T2 comfort profile C: strongest low-frequency comfort weighting with slightly softer front force use.
- Baseline rho1-rho4: 500, 100000, 10, 100000
- Trained rho1-rho4: 10000, 5000, 200, 20000
- Baseline front rho5: 1e-07
- Baseline rear rho5: 0.0001
- Trained front rho5: 3e-05
- Trained rear rho5: 0.0001
- Samples per axle: 8000
- Dry run: 0
- Generated at: 2026-06-07 21:39:23

## Activation

Run `ActivateRoad3Rho5Profile_2020('E:\Scientific_Research\claude\src_2020\road3_rho5_offline\data\ROAD3_Q_COMFORT_C')` after this profile is trained.
The activation tool backs up the current root MPC assets before copying this profile into `src_2020`.
