function profiles = Road3Rho5Profiles_2020()
%ROAD3RHO5PROFILES_2020 Named full-Q profiles for isolated Road-3 training.
%
% The function name is kept for compatibility with the existing offline
% activation scripts. Profiles now carry rho1-rho5 weights.

tool_dir = fileparts(mfilename('fullpath'));
src_dir = fileparts(tool_dir);
if exist('config_2020', 'file') ~= 2
    addpath(src_dir);
end

cfg = config_2020();

profiles = struct( ...
    'name', {}, ...
    'rho1', {}, ...
    'rho2', {}, ...
    'rho3', {}, ...
    'rho4', {}, ...
    'rho5_front', {}, ...
    'rho5_rear', {}, ...
    'description', {} ...
);

profiles(1).name = 'B3_CONSERVATIVE_BASELINE';
profiles(1).rho1 = cfg.rho1;
profiles(1).rho2 = cfg.rho2;
profiles(1).rho3 = cfg.rho3;
profiles(1).rho4 = cfg.rho4;
profiles(1).rho5_front = cfg.rho5_front;
profiles(1).rho5_rear = cfg.rho5_rear;
profiles(1).description = 'Frozen B3/B4 baseline copied from config_2020; not a retuned Road-3 profile.';

profiles(2).name = 'ROAD3_SOFT_F1E5_R1E4';
profiles(2).rho1 = cfg.rho1;
profiles(2).rho2 = cfg.rho2;
profiles(2).rho3 = cfg.rho3;
profiles(2).rho4 = cfg.rho4;
profiles(2).rho5_front = 1e-5;
profiles(2).rho5_rear = 1e-4;
profiles(2).description = 'Legacy Road-3 soft trial: raise front rho5 two decades, keep baseline comfort weights.';

profiles(3).name = 'ROAD3_SOFT_F1E4_R3E4';
profiles(3).rho1 = cfg.rho1;
profiles(3).rho2 = cfg.rho2;
profiles(3).rho3 = cfg.rho3;
profiles(3).rho4 = cfg.rho4;
profiles(3).rho5_front = 1e-4;
profiles(3).rho5_rear = 3e-4;
profiles(3).description = 'Legacy stronger softening trial retained for rollback and comparison.';

profiles(4).name = 'ROAD3_Q_COMFORT_A';
profiles(4).rho1 = 2500;
profiles(4).rho2 = 2e4;
profiles(4).rho3 = 50;
profiles(4).rho4 = 5e4;
profiles(4).rho5_front = 1e-5;
profiles(4).rho5_rear = 1e-4;
profiles(4).description = 'Road-3 T2 comfort profile A: stronger acceleration and tire/road weighting with baseline rear rho5.';

profiles(5).name = 'ROAD3_Q_COMFORT_B';
profiles(5).rho1 = 5000;
profiles(5).rho2 = 1e4;
profiles(5).rho3 = 100;
profiles(5).rho4 = 5e4;
profiles(5).rho5_front = 1e-5;
profiles(5).rho5_rear = 1e-4;
profiles(5).description = 'Road-3 T2 comfort profile B: more body acceleration/velocity authority with moderate suspension-deflection penalty.';

profiles(6).name = 'ROAD3_Q_COMFORT_C';
profiles(6).rho1 = 10000;
profiles(6).rho2 = 5e3;
profiles(6).rho3 = 200;
profiles(6).rho4 = 2e4;
profiles(6).rho5_front = 3e-5;
profiles(6).rho5_rear = 1e-4;
profiles(6).description = 'Road-3 T2 comfort profile C: strongest low-frequency comfort weighting with slightly softer front force use.';
end
