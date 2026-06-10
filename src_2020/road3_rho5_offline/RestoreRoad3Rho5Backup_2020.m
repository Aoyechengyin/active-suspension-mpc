function RestoreRoad3Rho5Backup_2020(backup_dir, target_src_dir)
%RESTOREROAD3RHO5BACKUP_2020 Restore src_2020 MPC assets from a backup.

assert(nargin >= 1 && ~isempty(backup_dir), 'Provide the backup directory returned by ActivateRoad3Rho5Profile_2020.');
assert(exist(backup_dir, 'dir') == 7, 'Backup directory does not exist: %s', backup_dir);

tool_dir = fileparts(mfilename('fullpath'));
if nargin >= 2 && ~isempty(target_src_dir)
    src_dir = char(target_src_dir);
else
    src_dir = fileparts(tool_dir);
end
asset_names = Road3Rho5AssetNames_2020();
if exist(src_dir, 'dir') ~= 7
    mkdir(src_dir);
end

for i = 1:numel(asset_names)
    backup_file = fullfile(backup_dir, asset_names{i});
    assert(exist(backup_file, 'file') == 2, 'Missing backup asset: %s', backup_file);
end

for i = 1:numel(asset_names)
    copyfile(fullfile(backup_dir, asset_names{i}), fullfile(src_dir, asset_names{i}));
end

fprintf('Road-3 rho5 backup restored from: %s\n', backup_dir);
end
