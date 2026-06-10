function cfg = NonlinearSuspensionConfig_2020(varargin)
%NONLINEARSUSPENSIONCONFIG_2020 Road-3 long-travel nonlinear suspension setup.
%
% The CarSim spring and damper tables are treated as element-coordinate
% values. Wheel-end linearized values therefore use motion_ratio^2.

base = config_2020();
profile_name = 'ROAD3_NONLINEAR_QC_LONGTRAVEL_V1';
if nargin >= 1 && ~isempty(varargin{1})
    profile_name = char(varargin{1});
end

cfg = base;
cfg.profile_name = profile_name;
cfg.profile_description = 'Road-3 long-travel suspension with Big SUV piecewise-linear damper regions and Q_COMFORT_C weights.';

cfg.rho1 = 10000;
cfg.rho2 = 5000;
cfg.rho3 = 200;
cfg.rho4 = 20000;
cfg.rho5_front = 3e-5;
cfg.rho5_rear = 1e-4;
cfg.rho5 = cfg.rho5_front;
cfg.Wy = diag([cfg.rho1, cfg.rho2, cfg.rho3, cfg.rho4]);
cfg.Wu = cfg.rho5_front * eye(cfg.c);

cfg.spring_front_rate_element_N_per_m = 146000;
cfg.spring_rear_rate_element_N_per_m = 46000;
cfg.spring_front_motion_ratio = 0.6111;
cfg.spring_rear_motion_ratio = 1.0;
cfg.k1f = cfg.spring_front_rate_element_N_per_m * cfg.spring_front_motion_ratio^2;
cfg.k1r = cfg.spring_rear_rate_element_N_per_m * cfg.spring_rear_motion_ratio^2;

cfg.damper_rate_mm_s = [-1410; -720; -390; -210; -90; -20; 0; 20; 90; 200; 390; 760; 1160];
cfg.damper_force_N = [-7316; -5019; -3395; -2618; -1472; -333; 0; 333; 870; 1145; 1607; 2623; 3740];
cfg.damper_front_motion_ratio = 0.614;
cfg.damper_rear_motion_ratio = 1.0;
cfg.damper_region_hysteresis_m_s = 0.05;

cfg.jounce_limit_m = 0.200;
cfg.rebound_limit_m = -0.210;
cfg.jounce_stop_front_motion_ratio = 0.614;
cfg.rebound_stop_front_motion_ratio = 0.614;
cfg.jounce_stop_rear_motion_ratio = 1.0;
cfg.rebound_stop_rear_motion_ratio = 1.0;

cfg.roll_stiffness_front_Nm_per_deg = 384;
cfg.roll_stiffness_rear_Nm_per_deg = 510;

regions = NonlinearDamperRegions_2020(cfg);
cfg.damper_regions = regions;

cfg.x_bounds = [ ...
    -0.18,  0.18; ...
    -1.60,  1.60; ...
    cfg.rebound_limit_m, cfg.jounce_limit_m; ...
    -4.00,  4.00; ...
    -cfg.u_max, cfg.u_max; ...
    repmat([-0.15, 0.15], cfg.n_road, 1) ...
];

cfg.axles = struct( ...
    'name', {'front', 'rear'}, ...
    'm2', {cfg.m2f, cfg.m2r}, ...
    'k1', {cfg.k1f, cfg.k1r}, ...
    'rho5', {cfg.rho5_front, cfg.rho5_rear}, ...
    'pitch_arm', {cfg.a, cfg.b}, ...
    'pitch_sign', {1, -1}, ...
    'motion_ratio', {cfg.damper_front_motion_ratio, cfg.damper_rear_motion_ratio} ...
);
end
