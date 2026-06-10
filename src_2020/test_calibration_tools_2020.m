function test_calibration_tools_2020()
%TEST_CALIBRATION_TOOLS_2020 Regression checks for flat-road calibration tools.

root_dir = fileparts(mfilename('fullpath'));
addpath(root_dir);

tmp_csv = fullfile(tempdir, 'flat_pose_calibration_fixture.csv');
T = table();
T.Time = (0:0.5:2)';
T.Pitch = 0.2 + zeros(height(T), 1);
T.Roll = [0; 0.01; 0.02; 0.01; 0];
T.Yaw = [0; 0.01; 0.02; 0.03; 0.04];
T.Xo = (0:4)';
T.Yo = [0; 0.01; 0.02; 0.03; 0.04];
T.Az_SM = [0; 0.01; 0.02; 0.01; 0];
T.Vz_SM = zeros(height(T), 1);
T.Ay_SM = zeros(height(T), 1);
T.Vx = 50 + zeros(height(T), 1);
T.Steer_SW = zeros(height(T), 1);
T.FsExt_L1 = [0; 100; 200; 100; 0];
T.FsExt_R1 = [0; -100; -200; -100; 0];
T.FsExt_L2 = [0; 9000; -9000; 9000; 0];
T.FsExt_R2 = [0; -9000; 9000; -9000; 0];
T.Fs_L1 = 7000 + zeros(height(T), 1);
T.Fs_R1 = 7001 + zeros(height(T), 1);
T.Fs_L2 = 3000 + zeros(height(T), 1);
T.Fs_R2 = 3001 + zeros(height(T), 1);
T.Jnc_L1 = zeros(height(T), 1);
T.Jnc_R1 = zeros(height(T), 1);
T.Jnc_L2 = zeros(height(T), 1);
T.Jnc_R2 = zeros(height(T), 1);
T.JncR_L1 = zeros(height(T), 1);
T.JncR_R1 = zeros(height(T), 1);
T.JncR_L2 = [0; 10; 20; 10; 0];
T.JncR_R2 = [0; -10; -20; -10; 0];
T.Zgnd_L1 = zeros(height(T), 1);
T.Zgnd_R1 = zeros(height(T), 1);
T.Zgnd_L2 = zeros(height(T), 1);
T.Zgnd_R2 = zeros(height(T), 1);
T.Rot_L1 = (0:4)';
T.Rot_R1 = (0:4)';
T.Rot_L2 = (0:4)';
T.Rot_R2 = (0:4)';
T.W1_L1 = zeros(height(T), 1);
T.W1_R1 = zeros(height(T), 1);
T.W1_L2 = zeros(height(T), 1);
T.W1_R2 = zeros(height(T), 1);
T.W2_L1 = zeros(height(T), 1);
T.W2_R1 = zeros(height(T), 1);
T.W2_L2 = zeros(height(T), 1);
T.W2_R2 = zeros(height(T), 1);
writetable(T, tmp_csv);

report = AnalyzeFlatPose_2020(tmp_csv, fullfile(tempdir, 'flat_pose_calibration_fixture.md'));
d = report.cases(1).metrics.derived;
assert(d.has_external_force_lr, 'Expected FsExt diagnostics to be detected.');
assert(abs(d.rear_external_force_lr.peak_abs - 18000) < 1e-9, 'Expected rear FsExt L-R peak of 18000 N.');
assert(d.external_force_saturation_fraction > 0, 'Expected FsExt saturation fraction to be nonzero.');
assert(d.has_wheel_rotation, 'Expected Rot_* diagnostics to be detected.');
assert(all([d.wheel_rotation_L1_delta, d.wheel_rotation_R1_delta, d.wheel_rotation_L2_delta, d.wheel_rotation_R2_delta] > 0), ...
    'Expected all wheel rotation deltas to be positive.');

[front_enabled, front_limit, front_scale] = empc_calibration_settings_2020('L1', 'B1_FRONT_ONLY');
[rear_enabled, rear_limit, rear_scale] = empc_calibration_settings_2020('L2', 'B1_FRONT_ONLY');
assert(front_enabled && front_limit == 9000 && front_scale == 1, 'B1 front should be enabled at 9000 N.');
assert(~rear_enabled && rear_limit == 0 && rear_scale == 1, 'B1 rear should be disabled.');

[front_enabled, front_limit] = empc_calibration_settings_2020('R1', 'B2_REAR_LOW');
[rear_enabled, rear_limit] = empc_calibration_settings_2020('R2', 'B2_REAR_LOW');
assert(~front_enabled && front_limit == 0, 'B2 front should be disabled.');
assert(rear_enabled && rear_limit == 1000, 'B2 rear should be limited to 1000 N.');

[front_enabled, front_limit, front_scale] = empc_calibration_settings_2020('R1', 'B2_REAR_LOW_REV');
[rear_enabled, rear_limit, rear_scale] = empc_calibration_settings_2020('R2', 'B2_REAR_LOW_REV');
assert(~front_enabled && front_limit == 0 && front_scale == 1, 'B2 reverse front should stay disabled without sign reversal.');
assert(rear_enabled && rear_limit == 1000 && rear_scale == -1, 'B2 reverse rear should be limited to 1000 N with sign reversal.');

[front_enabled, front_limit] = empc_calibration_settings_2020('L1', 'B3_CONSERVATIVE');
[rear_enabled, rear_limit] = empc_calibration_settings_2020('L2', 'B3_CONSERVATIVE');
assert(front_enabled && front_limit == 3000, 'B3 front should be limited to 3000 N.');
assert(rear_enabled && rear_limit == 2000, 'B3 rear should be limited to 2000 N.');

[front_enabled, front_limit, front_scale, front_post] = empc_calibration_settings_2020('L1', 'ROAD3_BUMP_SAFE');
[rear_enabled, rear_limit, rear_scale, rear_post] = empc_calibration_settings_2020('L2', 'ROAD3_BUMP_SAFE');
assert(front_enabled && front_limit == 1000 && front_scale == 1, 'Road-3 bump-safe front should be limited to 1000 N.');
assert(rear_enabled && rear_limit == 650 && rear_scale == 1, 'Road-3 bump-safe rear should be limited to 650 N.');
assert(front_post.enabled && front_post.limit_N == 1000, 'Road-3 front post-processing must be enabled at 1000 N.');
assert(rear_post.enabled && rear_post.limit_N == 650, 'Road-3 rear post-processing must be enabled at 650 N.');

[front_enabled, front_limit, ~, front_only_post] = empc_calibration_settings_2020('L1', 'ROAD3_T2_FRONT_ONLY_TIGHT');
[rear_enabled, rear_limit, ~, rear_disabled_post] = empc_calibration_settings_2020('L2', 'ROAD3_T2_FRONT_ONLY_TIGHT');
assert(front_enabled && front_limit == 1000 && front_only_post.enabled, 'T2 front-only tight should keep the front controller at 1000 N.');
assert(~rear_enabled && rear_limit == 0 && ~rear_disabled_post.enabled, 'T2 front-only tight should disable the rear controller.');

[front_enabled, front_limit, ~, front_disabled_post] = empc_calibration_settings_2020('R1', 'ROAD3_T2_REAR_ONLY_TIGHT');
[rear_enabled, rear_limit, ~, rear_only_post] = empc_calibration_settings_2020('R2', 'ROAD3_T2_REAR_ONLY_TIGHT');
assert(~front_enabled && front_limit == 0 && ~front_disabled_post.enabled, 'T2 rear-only tight should disable the front controller.');
assert(rear_enabled && rear_limit == 650 && rear_only_post.enabled, 'T2 rear-only tight should keep the rear controller at 650 N.');

[front_enabled, front_limit, ~, both_front_post] = empc_calibration_settings_2020('L1', 'ROAD3_T2_BOTH_TIGHT');
[rear_enabled, rear_limit, ~, both_rear_post] = empc_calibration_settings_2020('L2', 'ROAD3_T2_BOTH_TIGHT');
assert(front_enabled && front_limit == 1000 && both_front_post.rate_limit_N_per_s == 15000, 'T2 both-tight front settings changed unexpectedly.');
assert(rear_enabled && rear_limit == 650 && both_rear_post.rate_limit_N_per_s == 9000, 'T2 both-tight rear settings changed unexpectedly.');

[~, ~, ~, gate_pos] = empc_calibration_settings_2020('L1', 'ROAD3_T2_COMFORT_GATE_UV_POS');
[~, ~, ~, gate_neg] = empc_calibration_settings_2020('L1', 'ROAD3_T2_COMFORT_GATE_UV_NEG');
[~, ~, ~, paper_best] = empc_calibration_settings_2020('L1', 'ROAD3_PAPER_ACTIVE_BEST');
[~, ~, ~, default_post] = empc_calibration_settings_2020('L1');
assert(gate_pos.energy_gate_mode == 1, 'UV_POS gate mode should carry positive sign metadata.');
assert(gate_neg.energy_gate_mode == -1, 'UV_NEG gate mode should carry negative sign metadata.');
assert(paper_best.energy_gate_mode == 1, 'Paper active best should use the UV_POS gate direction.');
assert(default_post.energy_gate_mode == 1, 'Default calibration mode should be the frozen paper active best UV_POS mode.');

[u1, state] = road3_bump_safe_output_2020(3000, 0, front_post, 0.001);
[u2, state] = road3_bump_safe_output_2020(3000, state, front_post, 0.001);
assert(abs(u1) <= 15 + 1e-9, 'Road-3 front output should obey the first 1 ms rate limit.');
assert(abs(u2 - u1) <= 15 + 1e-9, 'Road-3 front output should obey repeated rate limits.');
[u_rear, ~] = road3_bump_safe_output_2020(3000, 0, rear_post, 0.001);
assert(abs(u_rear) <= 9 + 1e-9, 'Road-3 rear output should obey the first 1 ms rate limit.');
[u_clip, ~] = road3_bump_safe_output_2020(3000, 995, front_post, 1.0);
assert(abs(u_clip) <= 1000 + 1e-9, 'Road-3 front output should obey the hard soft-mode limit.');
[u_allowed, ~] = road3_bump_safe_output_2020(3000, 0, gate_pos, 0.001, 1.0);
[u_blocked, ~] = road3_bump_safe_output_2020(3000, 0, gate_pos, 0.001, -1.0);
assert(abs(u_allowed) > 0, 'UV_POS should allow commands with matching force/velocity sign.');
assert(abs(u_blocked) < 1e-12, 'UV_POS should gate commands with opposite force/velocity sign.');
[u_allowed_neg, ~] = road3_bump_safe_output_2020(3000, 0, gate_neg, 0.001, -1.0);
[u_blocked_neg, ~] = road3_bump_safe_output_2020(3000, 0, gate_neg, 0.001, 1.0);
assert(abs(u_allowed_neg) > 0, 'UV_NEG should allow commands with negative force/velocity product.');
assert(abs(u_blocked_neg) < 1e-12, 'UV_NEG should gate commands with positive force/velocity product.');

[u_l2, u_r2] = rear_diff_limiter_2020(3000, -3000, 500);
assert(abs(u_l2 - 500) < 1e-9 && abs(u_r2 + 500) < 1e-9, 'Rear differential limiter should clip symmetric opposite commands.');
[u_l2, u_r2] = rear_diff_limiter_2020(3000, 1000, 500);
assert(abs(u_l2 - 2500) < 1e-9 && abs(u_r2 - 1500) < 1e-9, 'Rear differential limiter should preserve common-mode force.');

fprintf('test_calibration_tools_2020 passed.\n');
end
