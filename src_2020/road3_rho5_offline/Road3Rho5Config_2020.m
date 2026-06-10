function cfg = Road3Rho5Config_2020(profile)
%ROAD3RHO5CONFIG_2020 Return config_2020 with Road-3 full-Q overrides.

tool_dir = fileparts(mfilename('fullpath'));
src_dir = fileparts(tool_dir);
if exist('config_2020', 'file') ~= 2
    addpath(src_dir);
end

if nargin < 1 || isempty(profile)
    profile = 'ROAD3_SOFT_F1E5_R1E4';
end

if ischar(profile) || isstring(profile)
    profile = local_find_profile(char(profile));
end

required_fields = {'name', 'rho1', 'rho2', 'rho3', 'rho4', 'rho5_front', 'rho5_rear'};
for i = 1:numel(required_fields)
    assert(isfield(profile, required_fields{i}), 'Profile missing field: %s', required_fields{i});
end

cfg = config_2020();
cfg.baseline_rho1 = cfg.rho1;
cfg.baseline_rho2 = cfg.rho2;
cfg.baseline_rho3 = cfg.rho3;
cfg.baseline_rho4 = cfg.rho4;
cfg.baseline_rho5_front = cfg.rho5_front;
cfg.baseline_rho5_rear = cfg.rho5_rear;
cfg.road3_rho5_profile = profile;

cfg.rho1 = double(profile.rho1);
cfg.rho2 = double(profile.rho2);
cfg.rho3 = double(profile.rho3);
cfg.rho4 = double(profile.rho4);
cfg.rho5_front = double(profile.rho5_front);
cfg.rho5_rear = double(profile.rho5_rear);
cfg.Wy = diag([cfg.rho1, cfg.rho2, cfg.rho3, cfg.rho4]);
cfg.rho5 = cfg.rho5_front;
cfg.Wu = cfg.rho5_front * eye(cfg.c);

cfg.axles = struct( ...
    'name', {'front', 'rear'}, ...
    'm2', {cfg.m2f, cfg.m2r}, ...
    'k1', {cfg.k1f, cfg.k1r}, ...
    'c1', {cfg.c1f, cfg.c1r}, ...
    'rho5', {cfg.rho5_front, cfg.rho5_rear}, ...
    'pitch_arm', {cfg.a, cfg.b}, ...
    'pitch_sign', {1, -1} ...
);
end

function profile = local_find_profile(name)
profiles = Road3Rho5Profiles_2020();
idx = find(strcmp({profiles.name}, name), 1);
assert(~isempty(idx), 'Unknown Road-3 rho5 profile: %s', name);
profile = profiles(idx);
end
