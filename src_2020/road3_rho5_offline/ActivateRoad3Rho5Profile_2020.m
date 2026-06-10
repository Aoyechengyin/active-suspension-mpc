function backup_dir = ActivateRoad3Rho5Profile_2020(profile_dir, target_src_dir)
%ACTIVATEROAD3RHO5PROFILE_2020 Copy a trained Road-3 profile into src_2020.
%
% This changes only MPC .mat assets in src_2020. It first backs up the
% current assets under the profile directory and returns that backup path.

if nargin < 1 || isempty(profile_dir)
    profile_dir = fullfile(fileparts(mfilename('fullpath')), 'data', 'ROAD3_SOFT_F1E5_R1E4');
end

tool_dir = fileparts(mfilename('fullpath'));
if nargin >= 2 && ~isempty(target_src_dir)
    src_dir = char(target_src_dir);
else
    src_dir = fileparts(tool_dir);
end
asset_names = Road3Rho5AssetNames_2020();

assert(exist(profile_dir, 'dir') == 7, 'Profile directory does not exist: %s', profile_dir);
if exist(src_dir, 'dir') ~= 7
    mkdir(src_dir);
end
for i = 1:numel(asset_names)
    trained_file = fullfile(profile_dir, asset_names{i});
    assert(exist(trained_file, 'file') == 2, 'Missing trained asset: %s', trained_file);
end

backup_dir = fullfile(profile_dir, ['backup_active_' datestr(now, 'yyyymmdd_HHMMSS')]);
mkdir(backup_dir);

for i = 1:numel(asset_names)
    root_file = fullfile(src_dir, asset_names{i});
    if exist(root_file, 'file') == 2
        copyfile(root_file, fullfile(backup_dir, asset_names{i}));
    end
end

for i = 1:numel(asset_names)
    copyfile(fullfile(profile_dir, asset_names{i}), fullfile(src_dir, asset_names{i}));
end

local_write_activation_note(fullfile(backup_dir, 'activation_note.md'), profile_dir, src_dir, asset_names);
fprintf('Road-3 rho5 profile activated: %s\n', profile_dir);
fprintf('Previous src_2020 assets backed up at: %s\n', backup_dir);
end

function local_write_activation_note(report_file, profile_dir, src_dir, asset_names)
fid = fopen(report_file, 'w');
assert(fid > 0, 'Cannot write activation note: %s', report_file);
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Road-3 rho5 Activation Backup\n\n');
fprintf(fid, '- Activated profile: `%s`\n', profile_dir);
fprintf(fid, '- Target source directory: `%s`\n', src_dir);
fprintf(fid, '- Activated at: %s\n\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf(fid, '## Files\n\n');
for i = 1:numel(asset_names)
    fprintf(fid, '- `%s`\n', asset_names{i});
end
fprintf(fid, '\nRestore with `RestoreRoad3Rho5Backup_2020(''%s'')`.\n', fileparts(report_file));
end
