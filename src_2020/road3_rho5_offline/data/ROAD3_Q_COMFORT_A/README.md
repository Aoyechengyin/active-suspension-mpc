# Road-3 Full-Q Offline Profile

- Profile: `ROAD3_Q_COMFORT_A`
- Description: Road-3 T2 comfort profile A: stronger acceleration and tire/road weighting with baseline rear rho5.
- Baseline rho1-rho4: 500, 100000, 10, 100000
- Trained rho1-rho4: 2500, 20000, 50, 50000
- Baseline front rho5: 1e-07
- Baseline rear rho5: 0.0001
- Trained front rho5: 1e-05
- Trained rear rho5: 0.0001
- Samples per axle: 8000
- Dry run: 0
- Generated at: 2026-06-07 21:23:37

## Activation

Run `ActivateRoad3Rho5Profile_2020('E:\Scientific_Research\claude\src_2020\road3_rho5_offline\data\ROAD3_Q_COMFORT_A')` after this profile is trained.
The activation tool backs up the current root MPC assets before copying this profile into `src_2020`.
