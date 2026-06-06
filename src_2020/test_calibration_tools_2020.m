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

[u_l2, u_r2] = rear_diff_limiter_2020(3000, -3000, 500);
assert(abs(u_l2 - 500) < 1e-9 && abs(u_r2 + 500) < 1e-9, 'Rear differential limiter should clip symmetric opposite commands.');
[u_l2, u_r2] = rear_diff_limiter_2020(3000, 1000, 500);
assert(abs(u_l2 - 2500) < 1e-9 && abs(u_r2 - 1500) < 1e-9, 'Rear differential limiter should preserve common-mode force.');

fprintf('test_calibration_tools_2020 passed.\n');
end
