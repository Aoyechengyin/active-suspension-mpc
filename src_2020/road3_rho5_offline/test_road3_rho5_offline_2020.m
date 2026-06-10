function test_road3_rho5_offline_2020()
%TEST_ROAD3_RHO5_OFFLINE_2020 Regression checks for Road-3 rho5 offline tools.

tool_dir = fileparts(mfilename('fullpath'));
src_dir = fileparts(tool_dir);
addpath(src_dir);
addpath(tool_dir);

baseline = config_2020();
profiles = Road3Rho5Profiles_2020();
assert(numel(profiles) >= 6, 'Expected baseline, soft, and Road-3 comfort profiles.');

base_profile = local_find_profile(profiles, 'B3_CONSERVATIVE_BASELINE');
soft_profile = local_find_profile(profiles, 'ROAD3_SOFT_F1E5_R1E4');
comfort_a = local_find_profile(profiles, 'ROAD3_Q_COMFORT_A');
comfort_b = local_find_profile(profiles, 'ROAD3_Q_COMFORT_B');
comfort_c = local_find_profile(profiles, 'ROAD3_Q_COMFORT_C');

assert(base_profile.rho5_front == baseline.rho5_front, 'Baseline front rho5 must mirror config_2020.');
assert(base_profile.rho5_rear == baseline.rho5_rear, 'Baseline rear rho5 must mirror config_2020.');
assert(base_profile.rho1 == baseline.rho1 && base_profile.rho4 == baseline.rho4, 'Baseline comfort weights must mirror config_2020.');
assert(abs(soft_profile.rho5_front - 1e-5) < eps, 'Road-3 soft front rho5 should be 1e-5.');
assert(abs(soft_profile.rho5_rear - 1e-4) < eps, 'Road-3 soft rear rho5 should be 1e-4.');
assert(comfort_a.rho1 == 2500 && comfort_a.rho2 == 2e4 && comfort_a.rho3 == 50 && comfort_a.rho4 == 5e4, ...
    'ROAD3_Q_COMFORT_A full-Q weights changed unexpectedly.');
assert(comfort_b.rho1 == 5000 && comfort_b.rho2 == 1e4 && comfort_b.rho3 == 100 && comfort_b.rho4 == 5e4, ...
    'ROAD3_Q_COMFORT_B full-Q weights changed unexpectedly.');
assert(comfort_c.rho1 == 10000 && comfort_c.rho2 == 5e3 && comfort_c.rho3 == 200 && comfort_c.rho4 == 2e4, ...
    'ROAD3_Q_COMFORT_C full-Q weights changed unexpectedly.');
assert(abs(comfort_c.rho5_front - 3e-5) < eps && abs(comfort_c.rho5_rear - 1e-4) < eps, ...
    'ROAD3_Q_COMFORT_C rho5 weights changed unexpectedly.');

cfg_soft = Road3Rho5Config_2020(soft_profile);
assert(abs(cfg_soft.axles(1).rho5 - 1e-5) < eps, 'Front axle rho5 override was not applied.');
assert(abs(cfg_soft.axles(2).rho5 - 1e-4) < eps, 'Rear axle rho5 override was not applied.');
cfg_comfort_a = Road3Rho5Config_2020(comfort_a);
assert(isequal(diag(cfg_comfort_a.Wy)', [2500, 2e4, 50, 5e4]), 'Full-Q comfort weights were not applied to Wy.');
assert(cfg_comfort_a.rho1 == 2500 && cfg_comfort_a.rho4 == 5e4, 'Full-Q comfort weights were not stored in cfg.');

cfg_after = config_2020();
assert(cfg_after.rho5_front == baseline.rho5_front, 'config_2020 front rho5 should not be modified by Road-3 config.');
assert(cfg_after.rho5_rear == baseline.rho5_rear, 'config_2020 rear rho5 should not be modified by Road-3 config.');

assets = Road3Rho5AssetNames_2020();
assert(numel(assets) == 8, 'Expected eight canonical MPC asset files.');
assert(any(strcmp(assets, 'regionless_mpc_data_front.mat')), 'Missing front safe regionless asset name.');
assert(any(strcmp(assets, 'regionless_mpc_data_rear_full.mat')), 'Missing rear full regionless asset name.');

tmp_root = fullfile(tempdir, 'road3_rho5_offline_fixture');
if exist(tmp_root, 'dir')
    rmdir(tmp_root, 's');
end

manifest = TrainRoad3Rho5Offline_2020( ...
    'profileName', comfort_a.name, ...
    'outputRoot', tmp_root, ...
    'nSamples', 5, ...
    'dryRun', true);

assert(strcmp(manifest.profile_name, comfort_a.name), 'Manifest profile name mismatch.');
assert(manifest.rho1 == comfort_a.rho1 && manifest.rho4 == comfort_a.rho4, 'Manifest should expose full-Q weights.');
assert(exist(manifest.profile_dir, 'dir') == 7, 'Dry-run should create a profile directory.');
assert(exist(fullfile(manifest.profile_dir, 'road3_rho5_config.mat'), 'file') == 2, ...
    'Dry-run should save the Road-3 rho5 config snapshot.');
assert(~exist(fullfile(manifest.profile_dir, 'regionless_mpc_data_front.mat'), 'file'), ...
    'Dry-run should not create trained regionless data.');

profile_assets_dir = fullfile(tmp_root, 'trained_profile');
active_assets_dir = fullfile(tmp_root, 'active_assets');
mkdir(profile_assets_dir);
mkdir(active_assets_dir);
for i = 1:numel(assets)
    marker = 1; %#ok<NASGU>
    save(fullfile(profile_assets_dir, assets{i}), 'marker');
    marker = -1; %#ok<NASGU>
    save(fullfile(active_assets_dir, assets{i}), 'marker');
end

backup_dir = ActivateRoad3Rho5Profile_2020(profile_assets_dir, active_assets_dir);
assert(exist(backup_dir, 'dir') == 7, 'Activation should create a backup directory.');
active_check = load(fullfile(active_assets_dir, 'regionless_mpc_data_front.mat'));
backup_check = load(fullfile(backup_dir, 'regionless_mpc_data_front.mat'));
assert(active_check.marker == 1, 'Activation should copy trained assets to the target directory.');
assert(backup_check.marker == -1, 'Activation should preserve previous active assets in the backup.');

RestoreRoad3Rho5Backup_2020(backup_dir, active_assets_dir);
restored_check = load(fullfile(active_assets_dir, 'regionless_mpc_data_front.mat'));
assert(restored_check.marker == -1, 'Restore should copy backup assets back to the target directory.');

fprintf('test_road3_rho5_offline_2020 passed.\n');
end

function profile = local_find_profile(profiles, name)
idx = find(strcmp({profiles.name}, name), 1);
assert(~isempty(idx), 'Missing Road-3 rho5 profile: %s', name);
profile = profiles(idx);
end
