# src_nonlinear Road-3 Nonlinear Suspension MPC

This folder contains the Road-3 long-travel suspension controller branch.
It does not overwrite `src_2020` training history.

## Scope

- Uses wheel-end spring and damper values derived from the updated CarSim suspension parameters.
- Uses five piecewise-linear Big SUV damper regions.
- Uses Q_COMFORT_C weights:
  - `rho1=10000`
  - `rho2=5000`
  - `rho3=200`
  - `rho4=20000`
  - `rho5_front=3e-5`
  - `rho5_rear=1e-4`
- Keeps the existing Simulink interface and function names through shadow wrappers.

## MATLAB Path

Put `src_nonlinear` before `src_2020`:

```matlab
addpath('src_nonlinear', '-begin');
addpath('src_2020');
```

Check that the nonlinear wrapper is active:

```matlab
which per_corner_mpc_L1_2020
```

The result should point to `src_nonlinear/per_corner_mpc_L1_2020.m`.

## Test

```matlab
addpath('src_nonlinear', '-begin');
addpath('src_2020');
test_nonlinear_suspension_offline_2020
```

This test is a dry-run and activation regression test. It does not train the
full offline controller.

## Train

```matlab
addpath('src_nonlinear', '-begin');
addpath('src_2020');

manifest = TrainNonlinearSuspensionOffline_2020( ...
    'profileName', 'ROAD3_NONLINEAR_QC_LONGTRAVEL_V1', ...
    'nSamples', 12000);
```

Training output is written to:

```text
src_nonlinear/data/ROAD3_NONLINEAR_QC_LONGTRAVEL_V1
```

## Activate

```matlab
backup_dir = ActivateNonlinearSuspensionProfile_2020( ...
    fullfile('src_nonlinear', 'data', 'ROAD3_NONLINEAR_QC_LONGTRAVEL_V1'));

clear per_corner_mpc_L1_2020 per_corner_mpc_R1_2020 ...
      per_corner_mpc_L2_2020 per_corner_mpc_R2_2020 ...
      per_corner_mpc_nonlinear_step_2020 ...
      per_corner_mpc_state_step_2020
```

Activation copies normalized regionless assets into `src_nonlinear`, not into
`src_2020`.

## Restore

```matlab
RestoreNonlinearSuspensionBackup_2020(backup_dir);
```

## Suggested Verification Order

1. T2 50 mm pilot Passive.
2. T2 50 mm pilot nonlinear preview.
3. T1 50 mm full nonlinear preview.
4. T2 150 mm full nonlinear preview.

For full-amplitude runs, check `FJSt/FRSt`, `Fz <= 0`, `Jnc/JncR`, heave,
pitch, and acceleration RMS before drawing controller conclusions.
