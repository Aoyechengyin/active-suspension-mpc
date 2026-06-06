function Step2_BuildMPCmatrices_2020()
%STEP2_BUILDMPCMATRICES_2020 Build front/rear standard QP matrices.

root_dir = fileparts(mfilename('fullpath'));
cfg = config_2020();

fprintf('========== Step 2 2020: build QP matrices ==========\n');
for i = 1:numel(cfg.axles)
    axle_name = cfg.axles(i).name;
    in_file = fullfile(root_dir, sprintf('prediction_model_%s.mat', axle_name));
    assert(exist(in_file, 'file') == 2, 'Run Step1 first: %s missing', in_file);
    model = load(in_file);
    qp = local_build_qp(model);
    out_file = fullfile(root_dir, sprintf('mpc_qp_data_%s.mat', axle_name));
    save(out_file, '-struct', 'qp');
    fprintf('  %s: saved %s, H=%dx%d, P=%dx%d\n', ...
        axle_name, out_file, size(qp.H,1), size(qp.H,2), size(qp.P,1), size(qp.P,2));
end
fprintf('========== Step 2 2020 complete ==========\n');
end

function qp = local_build_qp(model)
p = model.p;
c = model.c;
n_x = model.n_x;
A = model.A_s_d;
B = model.B_s_d;
Cz = model.Cz_d;

Phi = zeros(p * n_x, n_x);
Gamma = zeros(p * n_x, c);

A_powers = cell(p, 1);
A_powers{1} = A;
for i = 2:p
    A_powers{i} = A_powers{i-1} * A;
end

for i = 1:p
    rows = (i-1)*n_x + 1 : i*n_x;
    Phi(rows, :) = A_powers{i};
    for j = 1:min(i, c)
        if i == j
            Gamma(rows, j) = B;
        else
            Gamma(rows, j) = A_powers{i-j} * B;
        end
    end
end

Cz_blk = kron(eye(p), Cz);
Psi = Cz_blk * Phi;
Upsilon = Cz_blk * Gamma;

Wy_blk = kron(eye(p), model.Wy);
H = 2 * (Upsilon' * Wy_blk * Upsilon + model.Wu);
H = (H + H') / 2;
F = 2 * Psi' * Wy_blk * Upsilon;

P = [eye(c); -eye(c)];
M1 = model.u_max * ones(2*c, 1);
M2 = zeros(2*c, n_x);
m = size(P, 1);

qp = struct();
qp.H = H;
qp.F = F;
qp.P = P;
qp.M1 = M1;
qp.M2 = M2;
qp.Phi = Phi;
qp.Gamma = Gamma;
qp.Psi = Psi;
qp.Upsilon = Upsilon;
qp.Wy_blk = Wy_blk;
qp.Wu = model.Wu;
qp.n_x = n_x;
qp.n_u = model.n_u;
qp.n_z = model.n_z;
qp.c = c;
qp.p = p;
qp.m = m;
qp.u_max = model.u_max;
qp.x_bounds = model.x_bounds;
qp.dt = model.dt;
qp.axle_name = model.axle_name;
qp.model_file = sprintf('prediction_model_%s.mat', model.axle_name);
end
