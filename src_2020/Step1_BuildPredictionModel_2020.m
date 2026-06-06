function Step1_BuildPredictionModel_2020()
%STEP1_BUILDPREDICTIONMODEL_2020 Build front/rear 26-state prediction models.

root_dir = fileparts(mfilename('fullpath'));
cfg = config_2020();

fprintf('========== Step 1 2020: build prediction models ==========\n');
for i = 1:numel(cfg.axles)
    axle = cfg.axles(i);
    model = local_build_axle_model(cfg, axle);
    out_file = fullfile(root_dir, sprintf('prediction_model_%s.mat', axle.name));
    save(out_file, '-struct', 'model');
    fprintf('  %s: saved %s, n_x=%d, dt=%.4f, k1=%.0f, c1=%.1f\n', ...
        axle.name, out_file, model.n_x, model.dt, model.k1, model.c1);
end
fprintf('========== Step 1 2020 complete ==========\n');
end

function model = local_build_axle_model(cfg, axle)
m1 = cfg.m1;
m2 = axle.m2;
k1 = axle.k1;
c1 = axle.c1;
k2 = cfg.k2;
tau = cfg.tau;
n_road = cfg.n_road;

A_qc = [ 0,    1,    0,                       0,                0;
         0,    0,   -k1/m1,                  -c1/m1,           -1/m1;
         0,    0,    0,                       1,                0;
         k2/m2, 0,  -(k1/m1 + k1/m2 + k2/m2),-(c1/m1 + c1/m2),-(1/m1 + 1/m2);
         0,    0,    0,                       0,               -1/tau ];

B_qc = [0; 0; 0; 0; 1/tau];
E_qc = [0; 0; 0; -k2/m2; 0];
C_qc = eye(5);
D_qc = zeros(5, 1);

sys_qc_c = ss(A_qc, [B_qc, E_qc], C_qc, [D_qc, zeros(5, 1)]);
sys_qc_d = c2d(sys_qc_c, cfg.dt, 'zoh');

A_qc_d = sys_qc_d.A;
B_qc_d = sys_qc_d.B(:, 1);
E_qc_d = sys_qc_d.B(:, 2);

A_r_d = zeros(n_road, n_road);
for j = 1:n_road-1
    A_r_d(j, j+1) = 1;
end
E_r_d = zeros(n_road, 1);
E_r_d(end) = 1;

A_s_d = [A_qc_d,            E_qc_d, zeros(5, n_road-1);
         zeros(n_road, 5),  A_r_d];
B_s_d = [B_qc_d; zeros(n_road, 1)];
E_s_d = [zeros(5, 1); E_r_d];

Cz_d = [ 0, 0, -k1/m1, -c1/m1, -1/m1, zeros(1, n_road);
         0, 0,       1,      0,     0, zeros(1, n_road);
         0, 1,       0,      0,     0, zeros(1, n_road);
         1, 0,      -1,      0,     0, -1, zeros(1, n_road-1) ];
C_s_d = [Cz_d; eye(5), zeros(5, n_road)];
D_s_d = zeros(size(C_s_d, 1), 1);
Dz = zeros(4, 1);

model = struct();
model.axle_name = axle.name;
model.A_s_d = A_s_d;
model.B_s_d = B_s_d;
model.E_s_d = E_s_d;
model.C_s_d = C_s_d;
model.D_s_d = D_s_d;
model.Cz_d = Cz_d;
model.Dz = Dz;
model.A_qc_d = A_qc_d;
model.B_qc_d = B_qc_d;
model.E_qc_d = E_qc_d;
model.Wy = cfg.Wy;
model.Wu = axle.rho5 * eye(cfg.c);
model.p = cfg.p;
model.c = cfg.c;
model.N = cfg.N;
model.dt = cfg.dt;
model.tau = cfg.tau;
model.u_max = cfg.u_max;
model.n_road = cfg.n_road;
model.n_x = size(A_s_d, 1);
model.n_u = 1;
model.n_z = size(Cz_d, 1);
model.n_x_total = model.n_x;
model.m1 = m1;
model.m2 = m2;
model.k1 = k1;
model.c1 = c1;
model.k2 = k2;
model.rho1 = cfg.rho1;
model.rho2 = cfg.rho2;
model.rho3 = cfg.rho3;
model.rho4 = cfg.rho4;
model.rho5 = axle.rho5;
model.x_bounds = cfg.x_bounds;
model.pitch_arm = axle.pitch_arm;
model.pitch_sign = axle.pitch_sign;
end
