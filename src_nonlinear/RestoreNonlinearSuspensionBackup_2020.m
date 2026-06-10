function RestoreNonlinearSuspensionBackup_2020(backup_dir, target_dir)
%RESTORENONLINEARSUSPENSIONBACKUP_2020 Restore nonlinear MPC assets.

tool_dir = fileparts(mfilename('fullpath'));
if nargin < 2 || isempty(target_dir)
    target_dir = tool_dir;
end

assert(nargin >= 1 && ~isempty(backup_dir), 'backup_dir is required.');
assert(exist(backup_dir, 'dir') == 7, 'Backup directory does not exist: %s', backup_dir);

files = dir(fullfile(backup_dir, 'regionless_mpc_data_*.mat'));
assert(~isempty(files), 'No nonlinear regionless assets found in backup: %s', backup_dir);
if exist(target_dir, 'dir') ~= 7
    mkdir(target_dir);
end

for i = 1:numel(files)
    copyfile(fullfile(backup_dir, files(i).name), fullfile(target_dir, files(i).name));
end

fprintf('Nonlinear suspension backup restored from: %s\n', backup_dir);
fprintf('Restored target directory: %s\n', target_dir);
end
