function cfg = config_2020()
%CONFIG_2020 Parameters for the CarSim 2020 1 ms regionless e-MPC setup.

cfg = struct();

cfg.dt = 0.001;
cfg.p = 80;
cfg.c = 10;
cfg.N = 20;
cfg.n_road = cfg.N + 1;
cfg.n_x = 5 + cfg.n_road;
cfg.n_u = 1;
cfg.u_max = 9000;
cfg.tau = 0.05;

cfg.m1 = 1590 / 4;
cfg.m2f = 51.1;
cfg.m2r = 57.5;
cfg.k1f = 146000;
cfg.k1r = 46000;
cfg.k2 = 300000;

cfg.a = 1.18;
cfg.b = 1.77;
cfg.L = 2.95;

cfg.rho1 = 500;
cfg.rho2 = 1e5;
cfg.rho3 = 10;
cfg.rho4 = 1e5;
cfg.rho5 = 1e-7;
cfg.rho5_front = cfg.rho5;
cfg.rho5_rear = 1e-4;
cfg.Wy = diag([cfg.rho1, cfg.rho2, cfg.rho3, cfg.rho4]);
cfg.Wu = cfg.rho5 * eye(cfg.c);

cfg.damper_rear_rate_mm_s = [-1410; -720; -390; -210; -90; -20; 0; 20; 90; 200; 390; 760; 1160];
cfg.damper_rear_force_N = [-7316; -5019; -3395; -2618; -1472; -333; 0; 333; 870; 1145; 1607; 2623; 3740];
cfg.damper_fit_limit_m_s = 0.20;
cfg.c1r = local_fit_damping(cfg.damper_rear_rate_mm_s, cfg.damper_rear_force_N, cfg.damper_fit_limit_m_s);
cfg.c1f = cfg.c1r;

cfg.x_bounds = [ ...
    -0.10,  0.10; ...
    -1.00,  1.00; ...
    -0.12,  0.12; ...
    -4.00,  4.00; ...
    -cfg.u_max, cfg.u_max; ...
    repmat([-0.15, 0.15], cfg.n_road, 1) ...
];

cfg.export_order = { ...
    'W1_L1','W1_R1','W1_L2','W1_R2', ...
    'W2_L1','W2_R1','W2_L2','W2_R2', ...
    'Az_SM','Vz_SM', ...
    'Jnc_L1','Jnc_R1','Jnc_L2','Jnc_R2', ...
    'JncR_L1','JncR_R1','JncR_L2','JncR_R2', ...
    'Zgnd_L1','Zgnd_R1','Zgnd_L2','Zgnd_R2', ...
    'Vx','Pitch' ...
};

cfg.gurobi_matlab_path = 'D:/gurobi1302/win64/matlab';

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

function c_eq = local_fit_damping(rate_mm_s, force_N, fit_limit_m_s)
rate_m_s = rate_mm_s(:) / 1000;
force_N = force_N(:);
idx = abs(rate_m_s) <= fit_limit_m_s & rate_m_s ~= 0;
c_eq = sum(rate_m_s(idx) .* force_N(idx)) / sum(rate_m_s(idx).^2);
end
