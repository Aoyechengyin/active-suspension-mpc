# Road-3 Bump-Safe Output Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Road-3-specific bump-safe eMPC output mode that reduces force authority and output slew without changing CarSim, Simulink I/O, or the offline QP data format.

**Architecture:** Keep the existing regionless MPC calculation intact. Add a new `ROAD3_BUMP_SAFE` calibration mode and a stateless output post-processor called by each corner wrapper with a per-wrapper persistent output state.

**Tech Stack:** MATLAB R2020-era scripts/functions, CarSim/Simulink MATLAB Function wrappers, existing `src_2020` test scripts.

---

### Task 1: Add Calibration Mode And Tests

**Files:**
- Modify: `src_2020/empc_calibration_settings_2020.m`
- Modify: `src_2020/test_calibration_tools_2020.m`
- Modify: `src_2020/self_check_2020.m`

- [ ] Add explicit `ROAD3_BUMP_SAFE` mode with front `1200 N`, rear `800 N`, and post-processing metadata.
- [ ] Make `ROAD3_BUMP_SAFE` the temporary default for the next Road-3 T2 pilot run.
- [ ] Keep explicit `B3_CONSERVATIVE` unchanged at front `3000 N`, rear `2000 N`.
- [ ] Update structural tests to verify the new default and the preserved B3 mode.

### Task 2: Add Output Post-Processor

**Files:**
- Create: `src_2020/road3_bump_safe_output_2020.m`
- Modify: `src_2020/test_calibration_tools_2020.m`

- [ ] Implement hard soft-mode clipping to `settings.limit_N`.
- [ ] Implement first-order smoothing using `settings.smooth_tau_s`.
- [ ] Implement rate limiting using `settings.rate_limit_N_per_s`.
- [ ] Test that repeated commands cannot jump faster than the configured per-step rate and never exceed the soft limit.

### Task 3: Wire Four Corner Wrappers

**Files:**
- Modify: `src_2020/per_corner_mpc_L1_2020.m`
- Modify: `src_2020/per_corner_mpc_R1_2020.m`
- Modify: `src_2020/per_corner_mpc_L2_2020.m`
- Modify: `src_2020/per_corner_mpc_R2_2020.m`

- [ ] Add a persistent `u_safe_prev` in each wrapper.
- [ ] Request the fourth `post_settings` output from `empc_calibration_settings_2020`.
- [ ] Call `road3_bump_safe_output_2020` after output scaling and only through the metadata flag.
- [ ] Preserve `PASSIVE_ZERO` behavior as exact zero.

### Task 4: Restore Failed rho5 Profile And Document Use

**Files:**
- Restore: `src_2020/*mpc*.mat`, `src_2020/prediction_model_*.mat`, `src_2020/regionless_mpc_data_*.mat`
- Create: `日志/Road3_bump_safe输出策略_20260607.md`

- [ ] Restore active root assets from the backup made before `ROAD3_SOFT_F1E4_R3E4`.
- [ ] Document the active control mode, the backup path, the clear-persistent command, and the next run directory.
- [ ] Run MATLAB tests for `test_calibration_tools_2020`, `test_road3_tools_2020`, and `self_check_2020`.
