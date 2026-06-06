function Step3_RegionlessSolver_2020(n_samples)
%STEP3_REGIONLESSSOLVER_2020 Enumerate active sets and save codegen-safe data.

if nargin < 1
    n_samples = 8000;
end

root_dir = fileparts(mfilename('fullpath'));
cfg = config_2020();
if exist(cfg.gurobi_matlab_path, 'dir') == 7
    addpath(cfg.gurobi_matlab_path);
end

fprintf('========== Step 3 2020: regionless solver data ==========\n');
for i = 1:numel(cfg.axles)
    axle_name = cfg.axles(i).name;
    in_file = fullfile(root_dir, sprintf('mpc_qp_data_%s.mat', axle_name));
    assert(exist(in_file, 'file') == 2, 'Run Step2 first: %s missing', in_file);
    qp = load(in_file);
    data = local_build_regionless_data(qp, n_samples);

    safe_file = fullfile(root_dir, sprintf('regionless_mpc_data_%s.mat', axle_name));
    full_file = fullfile(root_dir, sprintf('regionless_mpc_data_%s_full.mat', axle_name));
    safe_data = rmfield(data, {'active_sets', 'active_sets_array', 'solver_used'});
    solver_used = data.solver_used; %#ok<NASGU>
    save(safe_file, '-struct', 'safe_data');
    save(full_file, '-struct', 'data');
    fprintf('  %s: saved %s (%d sets, solver=%s)\n', ...
        axle_name, safe_file, data.n_sets, solver_used);
end
fprintf('========== Step 3 2020 complete ==========\n');
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
fprintf('  %s: sampling %d states...\n', qp.axle_name, n_samples);
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
        fprintf('    %s: %d/%d, sets=%d\n', qp.axle_name, sample_idx, n_samples, active_set_map.Count);
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
fprintf('  %s: sets=%d, validation max error=%.3e, misses=%d\n', qp.axle_name, n_sets, max_error, n_fail);
assert(max_error < 1e-3, 'Regionless validation error too large for %s', qp.axle_name);

active_sets_array = [active_sets{:}]; %#ok<NASGU>
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
    [u_rless, flag_rless, active_idx] = regionless_mpc_eval_2020(x, active_sets, invH, invH_Ft, qp.H, qp.F, qp.P, qp.M1, qp.M2);
    [U_qp, flag_qp] = local_solve_qp(qp.H, qp.F' * x, qp.P, qp.M1 + qp.M2 * x);
    if flag_rless == 1 && flag_qp == 1
        err = abs(u_rless - U_qp(1));
        if err > max_error
            max_error = err;
        end
        if err > 1e-3 && n_fail == 0
            obj_qp = 0.5 * U_qp' * qp.H * U_qp + x' * qp.F * U_qp;
            fprintf('    first mismatch: u_rless=%.3f, u_qp=%.3f, active_idx=%d, obj_qp=%.6e\n', ...
                u_rless, U_qp(1), active_idx, obj_qp);
        end
    elseif flag_qp == 1
        n_fail = n_fail + 1;
    end
end
end
