# Nonlinear Suspension Offline Profile

- Profile: `ROAD3_NONLINEAR_QC_LONGTRAVEL_V1`
- Description: Road-3 long-travel suspension with Big SUV piecewise-linear damper regions and Q_COMFORT_C weights.
- Front wheel-end k1: 54522.70866 N/m
- Rear wheel-end k1: 46000 N/m
- Front/rear travel: +0.200 m / -0.210 m
- Q weights rho1-rho4: 10000, 5000, 200, 20000
- rho5 front/rear: 3e-05, 0.0001
- Samples per axle-region: 12000
- Dry run: 0
- Generated at: 2026-06-08 21:20:18

## Damper Regions

| Region | front c (N s/m) | rear c (N s/m) |
| --- | ---: | ---: |
| `REB_HIGH` | 2095.05994935 | 5557.24715739 |
| `REB_MID` | 2895.00324652 | 7679.13518052 |
| `LOW` | 3739.68099387 | 9919.6834817 |
| `COMP_MID` | 1395.53173075 | 3701.71495388 |
| `COMP_HIGH` | 1241.2091475 | 3292.36688852 |

## Activation

Run `ActivateNonlinearSuspensionProfile_2020('E:\Scientific_Research\claude\src_nonlinear\data\ROAD3_NONLINEAR_QC_LONGTRAVEL_V1')` after this profile is trained.
Place `src_nonlinear` before `src_2020` on the MATLAB path before starting Simulink.
