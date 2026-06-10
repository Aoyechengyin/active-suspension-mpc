function backup_dir = ActivateNonlinearSuspensionProfile_2020(profile_dir, target_dir)
%ACTIVATENONLINEARSUSPENSIONPROFILE_2020 Activate a trained nonlinear profile.
%
% Assets are copied into src_nonlinear so shadow controller wrappers can
% load them when src_nonlinear appears before src_2020 on the MATLAB path.

tool_dir = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(profile_dir)
    profile_dir = fullfile(tool_dir, 'data', 'ROAD3_NONLINEAR_QC_LONGTRAVEL_V1');
end
if nargin < 2 || isempty(target_dir)
    target_dir = tool_dir;
end

assert(exist(profile_dir, 'dir') == 7, 'Profile directory does not exist: %s', profile_dir);
manifest_file = fullfile(profile_dir, 'manifest.mat');
assert(exist(manifest_file, 'file') == 2, 'Missing manifest: %s', manifest_file);
s = load(manifest_file, 'manifest');
asset_files = s.manifest.asset_files;

for i = 1:numel(asset_files)
    trained_file = fullfile(profile_dir, asset_files{i});
    assert(exist(trained_file, 'file') == 2, 'Missing trained asset: %s', trained_file);
end

if exist(target_dir, 'dir') ~= 7
    mkdir(target_dir);
end
backup_dir = fullfile(profile_dir, ['backup_active_' datestr(now, 'yyyymmdd_HHMMSS')]);
mkdir(backup_dir);

for i = 1:numel(asset_files)
    target_file = fullfile(target_dir, asset_files{i});
    if exist(target_file, 'file') == 2
        copyfile(target_file, fullfile(backup_dir, asset_files{i}));
    end
end

max_sets = local_max_n_sets(profile_dir, asset_files);
for i = 1:numel(asset_files)
    trained_file = fullfile(profile_dir, asset_files{i});
    target_file = fullfile(target_dir, asset_files{i});
    local_copy_normalized_asset(trained_file, target_file, max_sets);
end

local_write_activation_note(fullfile(backup_dir, 'activation_note.md'), profile_dir, target_dir, asset_files);
fprintf('Nonlinear suspension profile activated: %s\n', profile_dir);
fprintf('Previous src_nonlinear assets backed up at: %s\n', backup_dir);
end

function max_sets = local_max_n_sets(profile_dir, asset_files)
max_sets = 0;
for i = 1:numel(asset_files)
    s = load(fullfile(profile_dir, asset_files{i}), 'n_sets');
    max_sets = max(max_sets, double(s.n_sets));
end
assert(max_sets > 0, 'No active sets found in trained nonlinear assets.');
end

function local_copy_normalized_asset(source_file, target_file, max_sets)
s = load(source_file);
old_sets = double(s.n_sets);
assert(old_sets <= max_sets, 'Unexpected n_sets larger than max_sets in %s', source_file);

if size(s.A_padded, 2) < max_sets
    s.A_padded(:, end+1:max_sets) = -1;
end
if size(s.Q_padded, 3) < max_sets
    s.Q_padded(:, :, end+1:max_sets) = 0;
end
if size(s.q_padded, 3) < max_sets
    s.q_padded(:, :, end+1:max_sets) = 0;
end
if numel(s.n_active_arr) < max_sets
    s.n_active_arr(end+1:max_sets) = 0;
end

s.n_sets_original = old_sets;
save(target_file, '-struct', 's');
end

function local_write_activation_note(report_file, profile_dir, target_dir, asset_files)
fid = fopen(report_file, 'w');
assert(fid > 0, 'Cannot write activation note: %s', report_file);
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Nonlinear Suspension Activation Backup\n\n');
fprintf(fid, '- Activated profile: `%s`\n', profile_dir);
fprintf(fid, '- Target directory: `%s`\n', target_dir);
fprintf(fid, '- Activated at: %s\n\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf(fid, '## Files\n\n');
for i = 1:numel(asset_files)
    fprintf(fid, '- `%s`\n', asset_files{i});
end
fprintf(fid, '\nRestore with `RestoreNonlinearSuspensionBackup_2020(''%s'', ''%s'')`.\n', fileparts(report_file), target_dir);
end
