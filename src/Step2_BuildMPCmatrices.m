% =========================================================================
% Step 2: 构建MPC预测矩阵与mp-QP矩阵
% 将预测模型转化为标准二次规划形式:
%   min   0.5 * U' * H * U + x' * F * U
%   s.t.  P * U <= M1 + M2 * x
% =========================================================================
clear; clc;

%% 1. 加载预测模型
load('prediction_model.mat');
fprintf('已加载 prediction_model.mat\n');

%% 2. 构建状态预测矩阵 Phi 和 Gamma
% X_pred = Phi * x(k) + Gamma * U
% Phi: (p * n_x) x n_x
% Gamma: (p * n_x) x c

Phi = zeros(p * n_x, n_x);
Gamma = zeros(p * n_x, c);

% 预计算 A 的幂次
A_powers = cell(p, 1);
A_powers{1} = A_s_d;
for i = 2:p
    A_powers{i} = A_powers{i-1} * A_s_d;
end

% 构建 Phi
for i = 1:p
    idx = (i-1)*n_x + 1 : i*n_x;
    Phi(idx, :) = A_powers{i};
end

% 构建 Gamma
for i = 1:p
    idx = (i-1)*n_x + 1 : i*n_x;
    for j = 1:min(i, c)
        col = j;  % single input, scalar index
        if i == j
            Gamma(idx, col) = B_s_d;
        else
            Gamma(idx, col) = A_powers{i-j} * B_s_d;
        end
    end
end

fprintf('Phi: %d x %d\n', size(Phi));
fprintf('Gamma: %d x %d\n', size(Gamma));

%% 3. 构建性能输出预测矩阵 Psi 和 Upsilon
% Z_pred = Psi * x(k) + Upsilon * U
% Psi: (p * n_z) x n_x
% Upsilon: (p * n_z) x c

% 块对角性能输出矩阵 Cz_blk
Cz_blk = kron(eye(p), Cz_d);

Psi = Cz_blk * Phi;
Upsilon = Cz_blk * Gamma;

fprintf('Psi: %d x %d\n', size(Psi));
fprintf('Upsilon: %d x %d\n', size(Upsilon));

%% 4. 构建 QP 矩阵 H 和 F
% 论文式(14)-(15): 从 J = Z'*Wy_blk*Z + U'*Wu*U 推导
% H = 2 * (Upsilon' * Wy_blk * Upsilon + Wu)
% F = 2 * Psi' * Wy_blk * Upsilon

Wy_blk = kron(eye(p), Wy);

H = 2 * (Upsilon' * Wy_blk * Upsilon + Wu);
F = 2 * Psi' * Wy_blk * Upsilon;  % n_x x c

% 确保 H 是对称正定的
H = (H + H') / 2;

fprintf('H: %d x %d (cond=%.2e)\n', size(H), cond(H));
fprintf('F: %d x %d\n', size(F));

%% 5. 构建约束矩阵 P, M1, M2
% 约束: |u(k+j)| <= u_max  for j = 0, ..., c-1
% 即: u(k+j) <= u_max  AND  -u(k+j) <= u_max
% P * U <= M1 + M2 * x
% M2 = 0, 因为执行器力约束不依赖状态

P = [ eye(c);
     -eye(c) ];

M1 = u_max * ones(2*c, 1);

M2 = zeros(2*c, n_x);

m = size(P, 1);  % 约束总数 = 2c
fprintf('约束数 m: %d\n', m);
fprintf('P: %d x %d\n', size(P));

%% 6. 保存 QP 数据
save('mpc_qp_data.mat', ...
     'H', 'F', 'P', 'M1', 'M2', ...
     'Phi', 'Gamma', 'Psi', 'Upsilon', ...
     'Wy_blk', 'Wu', ...
     'n_x', 'n_u', 'n_z', 'c', 'p', 'm', ...
     'u_max', 'x_bounds', 'dt');

fprintf('\nQP 数据已保存至 mpc_qp_data.mat\n');
fprintf('========== Step 2 完成 ==========\n');
