function manifest = TrainNonlinearSuspensionOffline_2020(varargin)
%TRAINNONLINEARSUSPENSIONOFFLINE_2020 Train Road-3 nonlinear suspension MPC data.

tool_dir = fileparts(mfilename('fullpath'));
root_dir = fileparts(tool_dir);
src2020_dir = fullfile(root_dir, 'src_2020');
if exist('config_2020', 'file') ~= 2
    addpath(src2020_dir);
end
if exist('regionless_mpc_eval_2020', 'file') ~= 2
    addpath(src2020_dir);
end

options = local_parse_options(tool_dir, varargin{:});
cfg = NonlinearSuspensionConfig_2020(options.profile_name);
baseline = config_2020();

profile_dir = fullfile(options.output_root, options.profile_name);
if exist(profile_dir, 'dir') ~= 7
    mkdir(profile_dir);
end

asset_files = local_asset_names(cfg);
manifest = local_build_manifest(options, cfg, baseline, profile_dir, asset_files);

config_file = fullfile(profile_dir, 'nonlinear_suspension_config.mat');
save(config_file, 'cfg', 'baseline', 'options');

if ~options.dry_run
    fprintf('========== Nonlinear suspension offline training: %s ==========\n', options.profile_name);
    fprintf('  front k1 %.3f N/m, rear k1 %.3f N/m\n', cfg.k1f, cfg.k1r);
    fprintf('  rho1-rho5: %.6g %.6g %.6g %.6g | front %.6g rear %.6g\n', ...
        cfg.rho1, cfg.rho2, cfg.rho3, cfg.rho4, cfg.rho5_front, cfg.rho5_rear);

    if exist(cfg.gurobi_matlab_path, 'dir') == 7
        addpath(cfg.gurobi_matlab_path);
    end

    for i = 1:numel(cfg.axles)
        axle = cfg.axles(i);
        for j = 1:numel(cfg.damper_regions)
            region = cfg.damper_regions(j);
            model = local_build_axle_model(cfg, axle, region);
            out_file = fullfile(profile_dir, sprintf('prediction_model_%s_%s.mat', axle.name, region.name));
            save(out_file, '-struct', 'model');
            fprintf('  %s/%s: model saved, k1=%.3f, c1=%.3f\n', ...
                axle.name, region.name, model.k1, model.c1);
        end
    end

    for i = 1:numel(cfg.axles)
        axle = cfg.axles(i);
        for j = 1:numel(cfg.damper_regions)
            region = cfg.damper_regions(j);
            model_file = fullfile(profile_dir, sprintf('prediction_model_%s_%s.mat', axle.name, region.name));
            model = load(model_file);
            qp = local_build_qp(model);
            qp_file = fullfile(profile_dir, sprintf('mpc_qp_data_%s_%s.mat', axle.name, region.name));
            save(qp_file, '-struct', 'qp');
            fprintf('  %s/%s: QP saved\n', axle.name, region.name);
        end
    end

    for i = 1:numel(cfg.axles)
        axle = cfg.axles(i);
        for j = 1:numel(cfg.damper_regions)
            region = cfg.damper_regions(j);
            qp_file = fullfile(profile_dir, sprintf('mpc_qp_data_%s_%s.mat', axle.name, region.name));
            qp = load(qp_file);
            data = local_build_regionless_data(qp, options.n_samples);
            safe_data = rmfield(data, {'active_sets', 'active_sets_array', 'solver_used'});

            safe_file = fullfile(profile_dir, sprintf('regionless_mpc_data_%s_%s.mat', axle.name, region.name));
            full_file = fullfile(profile_dir, sprintf('regionless_mpc_data_%s_%s_full.mat', axle.name, region.name));
            save(safe_file, '-struct', 'safe_data');
            save(full_file, '-struct', 'data');
            fprintf('  %s/%s: regionless saved (%d sets, solver=%s)\n', ...
                axle.name, region.name, data.n_sets, data.solver_used);
        end
    end
    fprintf('========== Nonlinear suspension offline training complete ==========\n');
end

manifest_file = fullfile(profile_dir, 'manifest.mat');
save(manifest_file, 'manifest');
local_write_manifest_md(fullfile(profile_dir, 'README.md'), manifest, cfg, options);
end

function options = local_parse_options(tool_dir, varargin)
options = struct();
options.profile_name = 'ROAD3_NONLINEAR_QC_LONGTRAVEL_V1';
options.n_samples = 12000;
options.output_root = fullfile(tool_dir, 'data');
options.dry_run = false;

assert(mod(numel(varargin), 2) == 0, 'Use name-value arguments.');
for i = 1:2:numel(varargin)
    name = lower(char(varargin{i}));
    value = varargin{i+1};
    switch name
        case 'profilename'
            options.profile_name = char(value);
        case 'nsamples'
            options.n_samples = double(value);
        case 'outputroot'
            options.output_root = char(value);
        case 'dryrun'
            options.dry_run = logical(value);
        otherwise
            error('Unknown option: %s', name);
    end
end

assert(options.n_samples > 0 && isfinite(options.n_samples), 'nSamples must be positive.');
options.n_samples = round(options.n_samples);
if exist(options.output_root, 'dir') ~= 7
    mkdir(options.output_root);
end
end

function manifest = local_build_manifest(options, cfg, baseline, profile_dir, asset_files)
manifest = struct();
manifest.profile_name = options.profile_name;
manifest.profile_dir = profile_dir;
manifest.output_root = options.output_root;
manifest.n_samples = options.n_samples;
manifest.dry_run = options.dry_run;
manifest.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
manifest.asset_files = asset_files;
manifest.baseline_k1f = baseline.k1f;
manifest.baseline_k1r = baseline.k1r;
manifest.k1f = cfg.k1f;
manifest.k1r = cfg.k1r;
manifest.spring_front_motion_ratio = cfg.spring_front_motion_ratio;
manifest.spring_rear_motion_ratio = cfg.spring_rear_motion_ratio;
manifest.damper_front_motion_ratio = cfg.damper_front_motion_ratio;
manifest.damper_rear_motion_ratio = cfg.damper_rear_motion_ratio;
manifest.jounce_limit_m = cfg.jounce_limit_m;
manifest.rebound_limit_m = cfg.rebound_limit_m;
manifest.rho1 = cfg.rho1;
manifest.rho2 = cfg.rho2;
manifest.rho3 = cfg.rho3;
manifest.rho4 = cfg.rho4;
manifest.rho5_front = cfg.rho5_front;
manifest.rho5_rear = cfg.rho5_rear;
manifest.region_names = {cfg.damper_regions.name};
manifest.c_front = [cfg.damper_regions.c_front_N_s_per_m];
manifest.c_rear = [cfg.damper_regions.c_rear_N_s_per_m];
end

function names = local_asset_names(cfg)
names = {};
for i = 1:numel(cfg.axles)
    for j = 1:numel(cfg.damper_regions)
        names{end+1} = sprintf('regionless_mpc_data_%s_%s.mat', cfg.axles(i).name, cfg.damper_regions(j).name); %#ok<AGROW>
    end
end
end

function model = local_build_axle_model(cfg, axle, region)
m1 = cfg.m1;
m2 = axle.m2;
k1 = axle.k1;
if strcmp(axle.name, 'front')
    c1 = region.c_front_N_s_per_m;
else
    c1 = region.c_rear_N_s_per_m;
end
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
model.region_name = region.name;
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
model.profile_name = cfg.profile_name;
model.jounce_limit_m = cfg.jounce_limit_m;
model.rebound_limit_m = cfg.rebound_limit_m;
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
qp.region_name = model.region_name;
qp.model_file = sprintf('prediction_model_%s_%s.mat', model.axle_name, model.region_name);
qp.rho5 = model.rho5;
qp.profile_name = model.profile_name;
qp.k1 = model.k1;
qp.c1 = model.c1;
end

function data = local_build_regionless_data(qp, n_samples)
H = qp.H;
F = qp.F;
P = qp.P;
M1 = qp.M1;
M2 = qp.M2;
c = qp.c;
n_x = qp.n_x;
x_bounds = qp.x_bounds;

invH = H \ eye(c);
invH_Ft = invH * F';

x_min = x_bounds(:, 1);
x_max = x_bounds(:, 2);
active_set_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
solver_used = 'unresolved';

rng(42);
fprintf('  %s/%s: sampling %d states...\n', qp.axle_name, qp.region_name, n_samples);
for sample_idx = 1:n_samples
    x = x_min + (x_max - x_min) .* rand(n_x, 1);
    [U_qp, exitflag, solver_name] = local_solve_qp(H, F' * x, P, M1 + M2 * x);
    if strcmp(solver_used, 'unresolved')
        solver_used = solver_name;
    end
    if exitflag ~= 1
        continue;
    end

    residual = P * U_qp - (M1 + M2 * x);
    Ai = find(abs(residual) < 1e-4)';
    key = mat2str(Ai);
    if active_set_map.isKey(key)
        continue;
    end

    n_act = numel(Ai);
    if n_act > c
        continue;
    end

    PAi = P(Ai, :);
    M2Ai = M2(Ai, :);
    M1Ai = M1(Ai);
    S = PAi * invH * PAi';
    if n_act > 0 && rcond(S) < 1e-10
        continue;
    end

    if n_act > 0
        invS = S \ eye(n_act);
        Q_Ai = -invS * (M2Ai + PAi * invH_Ft);
        q_Ai = -invS * M1Ai;
    else
        Q_Ai = zeros(0, n_x);
        q_Ai = zeros(0, 1);
    end

    lambda_check = Q_Ai * x + q_Ai;
    U_check = -invH_Ft * x;
    if n_act > 0
        U_check = U_check - invH * PAi' * lambda_check;
    end
    if norm(U_check - U_qp, inf) > 1e-3
        continue;
    end

    active_set_map(key) = struct('A', Ai, 'Q', Q_Ai, 'q', q_Ai, 'PA', PAi);

    if mod(sample_idx, 1000) == 0
        fprintf('    %s/%s: %d/%d, sets=%d\n', qp.axle_name, qp.region_name, sample_idx, n_samples, active_set_map.Count);
    end
end

keys_list = active_set_map.keys();
active_sets = cell(1, numel(keys_list));
for i = 1:numel(keys_list)
    active_sets{i} = active_set_map(keys_list{i});
end

n_sets = numel(active_sets);
max_active = c;
A_padded = -ones(max_active, n_sets);
Q_padded = zeros(max_active, n_x, n_sets);
q_padded = zeros(max_active, 1, n_sets);
n_active_arr = zeros(1, n_sets);

for i = 1:n_sets
    Ai = active_sets{i}.A;
    n_act = numel(Ai);
    n_active_arr(i) = n_act;
    if n_act > 0
        A_padded(1:n_act, i) = Ai(:);
        Q_padded(1:n_act, :, i) = active_sets{i}.Q;
        q_padded(1:n_act, 1, i) = active_sets{i}.q;
    end
end

[max_error, n_fail] = local_verify_regionless(qp, active_sets, invH, invH_Ft, 200);
fprintf('  %s/%s: sets=%d, validation max error=%.3e, misses=%d\n', ...
    qp.axle_name, qp.region_name, n_sets, max_error, n_fail);
assert(max_error < 1e-3, 'Regionless validation error too large for %s/%s', qp.axle_name, qp.region_name);

if isempty(active_sets)
    active_sets_array = struct('A', {}, 'Q', {}, 'q', {}, 'PA', {});
else
    active_sets_array = [active_sets{:}]; 
end

data = struct();
data.active_sets = active_sets;
data.active_sets_array = active_sets_array;
data.invH = invH;
data.invH_Ft = invH_Ft;
data.F = F;
data.P = P;
data.M1 = M1;
data.M2 = M2;
data.H = H;
data.c = c;
data.m = qp.m;
data.n_x = n_x;
data.n_u = qp.n_u;
data.u_max = qp.u_max;
data.x_bounds = x_bounds;
data.dt = qp.dt;
data.A_padded = A_padded;
data.Q_padded = Q_padded;
data.q_padded = q_padded;
data.n_active_arr = n_active_arr;
data.n_sets = n_sets;
data.max_active = max_active;
data.solver_used = solver_used;
data.validation_max_error = max_error;
data.validation_misses = n_fail;
data.rho5 = qp.rho5;
data.profile_name = qp.profile_name;
data.axle_name = qp.axle_name;
data.region_name = qp.region_name;
data.k1 = qp.k1;
data.c1 = qp.c1;
end

function [x, exitflag, solver_name] = local_solve_qp(H, f, A, b)
if exist('gurobi', 'file') == 3 || exist('gurobi', 'file') == 2
    try
        model = struct();
        model.Q = sparse(0.5 * H);
        model.obj = f(:);
        model.A = sparse(A);
        model.rhs = b(:);
        model.sense = repmat('<', size(A, 1), 1);
        model.lb = -inf(size(f(:)));
        model.ub = inf(size(f(:)));
        params = struct('OutputFlag', 0);
        result = gurobi(model, params);
        if isfield(result, 'x') && any(strcmp(result.status, {'OPTIMAL', 'SUBOPTIMAL'}))
            x = result.x;
            exitflag = 1;
            solver_name = 'gurobi';
            return;
        end
    catch
        % Fall through to quadprog.
    end
end

options = optimoptions('quadprog', 'Display', 'off', 'Algorithm', 'interior-point-convex');
[x, ~, flag] = quadprog(H, f, A, b, [], [], [], [], [], options);
exitflag = double(flag == 1);
solver_name = 'quadprog';
end

function [max_error, n_fail] = local_verify_regionless(qp, active_sets, invH, invH_Ft, n_test)
x_min = qp.x_bounds(:, 1);
x_max = qp.x_bounds(:, 2);
max_error = 0;
n_fail = 0;

rng(7);
for i = 1:n_test
    x = x_min + (x_max - x_min) .* rand(qp.n_x, 1);
    [u_rless, flag_rless] = regionless_mpc_eval_2020(x, active_sets, invH, invH_Ft, qp.H, qp.F, qp.P, qp.M1, qp.M2);
    [U_qp, flag_qp] = local_solve_qp(qp.H, qp.F' * x, qp.P, qp.M1 + qp.M2 * x);
    if flag_rless == 1 && flag_qp == 1
        err = abs(u_rless - U_qp(1));
        if err > max_error
            max_error = err;
        end
    elseif flag_qp == 1
        n_fail = n_fail + 1;
    end
end
end

function local_write_manifest_md(report_file, manifest, cfg, options)
fid = fopen(report_file, 'w');
assert(fid > 0, 'Cannot write manifest report: %s', report_file);
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Nonlinear Suspension Offline Profile\n\n');
fprintf(fid, '- Profile: `%s`\n', manifest.profile_name);
fprintf(fid, '- Description: %s\n', cfg.profile_description);
fprintf(fid, '- Front wheel-end k1: %.12g N/m\n', manifest.k1f);
fprintf(fid, '- Rear wheel-end k1: %.12g N/m\n', manifest.k1r);
fprintf(fid, '- Front/rear travel: +%.3f m / %.3f m\n', manifest.jounce_limit_m, manifest.rebound_limit_m);
fprintf(fid, '- Q weights rho1-rho4: %.12g, %.12g, %.12g, %.12g\n', ...
    manifest.rho1, manifest.rho2, manifest.rho3, manifest.rho4);
fprintf(fid, '- rho5 front/rear: %.12g, %.12g\n', manifest.rho5_front, manifest.rho5_rear);
fprintf(fid, '- Samples per axle-region: %d\n', manifest.n_samples);
fprintf(fid, '- Dry run: %d\n', double(options.dry_run));
fprintf(fid, '- Generated at: %s\n\n', manifest.timestamp);

fprintf(fid, '## Damper Regions\n\n');
fprintf(fid, '| Region | front c (N s/m) | rear c (N s/m) |\n');
fprintf(fid, '| --- | ---: | ---: |\n');
for i = 1:numel(manifest.region_names)
    fprintf(fid, '| `%s` | %.12g | %.12g |\n', manifest.region_names{i}, manifest.c_front(i), manifest.c_rear(i));
end

fprintf(fid, '\n## Activation\n\n');
fprintf(fid, 'Run `ActivateNonlinearSuspensionProfile_2020(''%s'')` after this profile is trained.\n', manifest.profile_dir);
fprintf(fid, 'Place `src_nonlinear` before `src_2020` on the MATLAB path before starting Simulink.\n');
end
