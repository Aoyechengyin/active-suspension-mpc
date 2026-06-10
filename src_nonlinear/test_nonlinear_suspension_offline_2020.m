function test_nonlinear_suspension_offline_2020()
%TEST_NONLINEAR_SUSPENSION_OFFLINE_2020 Regression checks for src_nonlinear.

tool_dir = fileparts(mfilename('fullpath'));
root_dir = fileparts(tool_dir);
src2020_dir = fullfile(root_dir, 'src_2020');
if exist('config_2020', 'file') ~= 2
    addpath(src2020_dir);
end

cfg = NonlinearSuspensionConfig_2020();
expected_k1f = 146000 * 0.6111^2;
assert(abs(cfg.k1f - expected_k1f) < 1e-9, 'Front wheel-end spring stiffness conversion changed.');
assert(abs(cfg.k1r - 46000) < 1e-9, 'Rear wheel-end spring stiffness conversion changed.');
assert(cfg.rho1 == 10000 && cfg.rho2 == 5000 && cfg.rho3 == 200 && cfg.rho4 == 20000, ...
    'Q_COMFORT_C weights are not active in nonlinear config.');
assert(abs(cfg.rho5_front - 3e-5) < eps && abs(cfg.rho5_rear - 1e-4) < eps, ...
    'Q_COMFORT_C rho5 values are not active in nonlinear config.');

regions = cfg.damper_regions;
assert(numel(regions) == 5, 'Expected five damper regions.');
assert(strcmp(regions(1).name, 'REB_HIGH') && strcmp(regions(5).name, 'COMP_HIGH'), ...
    'Damper region order changed.');

low = regions(strcmp({regions.name}, 'LOW'));
rate_m_s = cfg.damper_rate_mm_s(:) / 1000;
force_N = cfg.damper_force_N(:);
idx = rate_m_s >= low.v_min_m_s & rate_m_s <= low.v_max_m_s & rate_m_s ~= 0;
expected_c_element = sum(rate_m_s(idx) .* force_N(idx)) / sum(rate_m_s(idx).^2);
expected_c_front = expected_c_element * cfg.damper_front_motion_ratio^2;
assert(abs(low.c_element_N_s_per_m - expected_c_element) < 1e-9, ...
    'LOW region element damping fit changed.');
assert(abs(low.c_front_N_s_per_m - expected_c_front) < 1e-9, ...
    'Front damping motion-ratio conversion changed.');

tmp_root = fullfile(tempdir, 'src_nonlinear_fixture');
if exist(tmp_root, 'dir') == 7
    rmdir(tmp_root, 's');
end
mkdir(tmp_root);

manifest = TrainNonlinearSuspensionOffline_2020( ...
    'profileName', 'ROAD3_NONLINEAR_QC_LONGTRAVEL_TEST', ...
    'outputRoot', tmp_root, ...
    'dryRun', true);
assert(manifest.dry_run, 'Dry-run manifest should be marked dry_run.');
assert(exist(fullfile(manifest.profile_dir, 'nonlinear_suspension_config.mat'), 'file') == 2, ...
    'Dry-run should write nonlinear_suspension_config.mat.');
assert(exist(fullfile(manifest.profile_dir, 'regionless_mpc_data_front_LOW.mat'), 'file') ~= 2, ...
    'Dry-run should not create trained regionless assets.');

fake_profile = fullfile(tmp_root, 'FAKE_ACTIVATION_PROFILE');
mkdir(fake_profile);
fake_manifest = struct();
fake_manifest.asset_files = { ...
    'regionless_mpc_data_front_REB_HIGH.mat', ...
    'regionless_mpc_data_front_REB_MID.mat' ...
};
manifest = fake_manifest; 
save(fullfile(fake_profile, 'manifest.mat'), 'manifest');
local_write_fake_asset(fullfile(fake_profile, fake_manifest.asset_files{1}), 2);
local_write_fake_asset(fullfile(fake_profile, fake_manifest.asset_files{2}), 4);

target_dir = fullfile(tmp_root, 'active');
backup_dir = ActivateNonlinearSuspensionProfile_2020(fake_profile, target_dir);
assert(exist(backup_dir, 'dir') == 7, 'Activation should create a backup directory.');
active_a = load(fullfile(target_dir, fake_manifest.asset_files{1}));
active_b = load(fullfile(target_dir, fake_manifest.asset_files{2}));
assert(size(active_a.A_padded, 2) == 4 && size(active_b.A_padded, 2) == 4, ...
    'Activation should normalize active-set padded dimensions.');
assert(active_a.n_sets == 2 && active_a.n_sets_original == 2, ...
    'Activation should preserve original n_sets metadata.');

backup_seed = fullfile(tmp_root, 'manual_backup');
mkdir(backup_seed);
local_write_fake_asset(fullfile(backup_seed, fake_manifest.asset_files{1}), 3);
RestoreNonlinearSuspensionBackup_2020(backup_seed, target_dir);
restored = load(fullfile(target_dir, fake_manifest.asset_files{1}));
assert(restored.n_sets == 3, 'Restore should copy backup assets into target directory.');

fprintf('test_nonlinear_suspension_offline_2020 passed.\n');
end

function local_write_fake_asset(file_path, n_sets)
max_active = 10;
n_x = 26;
c = 10;
n_sets = double(n_sets);
s = struct();
s.n_sets = n_sets;
s.max_active = max_active;
s.n_x = n_x;
s.c = c;
s.A_padded = -ones(max_active, n_sets);
s.Q_padded = zeros(max_active, n_x, n_sets);
s.q_padded = zeros(max_active, 1, n_sets);
s.n_active_arr = zeros(1, n_sets);
s.invH = eye(c);
s.invH_Ft = zeros(c, n_x);
s.H = eye(c);
s.F = zeros(n_x, c);
s.P = [eye(c); -eye(c)];
s.M1 = 9000 * ones(2*c, 1);
s.M2 = zeros(2*c, n_x);
s.u_max = 9000;
s.dt = 0.001;
save(file_path, '-struct', 's');
end
