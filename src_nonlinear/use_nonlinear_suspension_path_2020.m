%USE_NONLINEAR_SUSPENSION_PATH_2020 Put nonlinear wrappers before src_2020.
%
% Run from project root:
%   run('src_nonlinear/use_nonlinear_suspension_path_2020.m')

script_file = mfilename('fullpath');
if isempty(script_file)
    stack = dbstack('-completenames');
    script_file = stack(1).file;
end
script_dir = fileparts(script_file);
project_root = fileparts(script_dir);
src_2020_dir = fullfile(project_root, 'src_2020');
src_nonlinear_dir = script_dir;
cd(project_root);

if exist(src_2020_dir, 'dir') ~= 7
    error('src_2020 directory not found: %s', src_2020_dir);
end
if exist(src_nonlinear_dir, 'dir') ~= 7
    error('src_nonlinear directory not found: %s', src_nonlinear_dir);
end

% Remove duplicate entries first; MATLAB path order is the control switch.
if local_path_contains(src_2020_dir)
    rmpath(src_2020_dir);
end
if local_path_contains(src_nonlinear_dir)
    rmpath(src_nonlinear_dir);
end

addpath(src_2020_dir, '-end');
addpath(src_nonlinear_dir, '-begin');
rehash;

clear per_corner_mpc_L1_2020 per_corner_mpc_R1_2020 ...
      per_corner_mpc_L2_2020 per_corner_mpc_R2_2020 ...
      per_corner_mpc_nonlinear_step_2020 ...
      per_corner_mpc_state_step_2020

l1_path = which('per_corner_mpc_L1_2020');
settings_path = which('empc_calibration_settings_2020');

fprintf('per_corner_mpc_L1_2020 -> %s\n', l1_path);
fprintf('empc_calibration_settings_2020 -> %s\n', settings_path);

if ~local_starts_with_path(l1_path, src_nonlinear_dir)
    error('Nonlinear wrapper is not first on path. Expected under: %s', src_nonlinear_dir);
end
if ~local_starts_with_path(settings_path, src_2020_dir)
    error('Calibration settings not found under src_2020. Expected under: %s', src_2020_dir);
end

fprintf('Nonlinear suspension path is active. Default mode is read from empc_calibration_settings_2020.\n');

function tf = local_path_contains(target_dir)
parts = strsplit(path, pathsep);
target = local_norm_path(target_dir);
tf = false;
for i = 1:numel(parts)
    if strcmp(local_norm_path(parts{i}), target)
        tf = true;
        return;
    end
end
end

function tf = local_starts_with_path(file_path, parent_dir)
file_path = [local_norm_path(file_path) '/'];
parent_dir = [local_norm_path(parent_dir) '/'];
tf = strncmp(file_path, parent_dir, numel(parent_dir));
end

function p = local_norm_path(p)
p = strrep(char(p), '\', '/');
p = lower(p);
while endsWith(p, '/')
    p = p(1:end-1);
end
end
