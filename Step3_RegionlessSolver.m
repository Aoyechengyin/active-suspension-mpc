% =========================================================================
% Step 3: 区域无关显式MPC求解器 (Regionless e-MPC Solver)
%
% 离线阶段: 枚举所有最优活跃集，预计算KKT矩阵分解
% 在线阶段: Algorithm 5 (Borrelli et al., Automatica, 2010)
%
% 参考:
%   [1] Theunissen et al., "Regionless Explicit MPC of Active Suspension
%       Systems With Preview", IEEE TIE, 2020
%   [2] Borrelli et al., "On the computation of linear model predictive
%       control laws", Automatica, 2010
% =========================================================================
clear; clc;

%% ========================================================================
%  第一部分: 离线枚举 (OFFLINE PHASE)
%  ========================================================================
fprintf('========== 区域无关求解器：离线枚举阶段 ==========\n');

%% 1. 加载 QP 数据
load('mpc_qp_data.mat');
fprintf('已加载 mpc_qp_data.mat\n');
fprintf('状态维数 n_x = %d, 优化变量数 c = %d, 约束数 m = %d\n', n_x, c, m);

%% 2. 预计算不依赖活跃集的矩阵
invH = H \ eye(c);              % H^{-1}
invH_Ft = invH * F';            % H^{-1} * F^T,  c x n_x
% 注: F 是 n_x x c, 所以 F' 是 c x n_x, invH_Ft = invH * F'

fprintf('H 条件数: %.2e\n', cond(H));
fprintf('invH_Ft: %d x %d\n', size(invH_Ft));

%% 3. 参数空间边界 (LP约束)
% A_bound * x <= b_bound 定义参数空间
x_min = x_bounds(:, 1);
x_max = x_bounds(:, 2);
A_bound = [ eye(n_x); -eye(n_x) ];
b_bound = [ x_max; -x_min ];

%% 4. 活跃集枚举 (基于采样的方法)
% 使用 quadprog 随机采样状态空间，收集所有最优活跃集
% 比组合枚举+LP方法更可靠
n_samples = 5000;
fprintf('\n基于采样的活跃集枚举: %d 个随机采样点...\n', n_samples);

AS_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
x_min = x_bounds(:, 1);
x_max = x_bounds(:, 2);

active_sets = {};
count = 0;

rng(42);
tic;
for i = 1:n_samples
    % 随机采样状态
    x_sample = x_min + (x_max - x_min) .* rand(n_x, 1);

    % 用 quadprog 求解 QP
    options = optimoptions('quadprog', 'Display', 'off', ...
        'Algorithm', 'interior-point-convex');
    [U_qp, ~, exitflag] = quadprog(H, F' * x_sample, P, M1 + M2 * x_sample, ...
                                   [], [], [], [], [], options);

    if exitflag ~= 1
        continue;
    end

    % 识别最优活跃集
    residual = P * U_qp - (M1 + M2 * x_sample);
    Ai = find(abs(residual) < 1e-5)';
    key = mat2str(Ai);

    if ~AS_map.isKey(key)
        n_active = length(Ai);
        if n_active > c
            continue;
        end

        PAi = P(Ai, :);
        M2Ai = M2(Ai, :);
        M1Ai = M1(Ai);

        % 计算 KKT 矩阵分解
        S = PAi * invH * PAi';
        if n_active > 0 && rcond(S) < 1e-10
            continue;
        end

        if n_active > 0
            invS = S \ eye(n_active);
            Q_Ai = -invS * (M2Ai + PAi * invH_Ft);
            q_Ai = -invS * M1Ai;
        else
            invS = zeros(0);
            Q_Ai = zeros(0, n_x);
            q_Ai = zeros(0, 1);
        end

        count = count + 1;
        AS_map(key) = true;
        active_sets{count} = struct(...
            'A', Ai, ...
            'Q', Q_Ai, ...
            'q', q_Ai, ...
            'PA', PAi, ...
            'invS', invS);
    end

    % 进度显示
    if mod(i, 500) == 0
        fprintf('  进度: %d/%d, 已找到 %d 个活跃集\n', i, n_samples, count);
    end
end

elapsed_total = toc;
fprintf('\n枚举完成! 耗时 %.1f 秒\n', elapsed_total);
fprintf('找到 %d 个可行活跃集 (来自 %d 个采样点)\n', count, n_samples);

%% 5. 保存离线数据
% 将 cell array 转为 struct array 以便 codegen
active_sets_array = [active_sets{:}];

save('regionless_mpc_data.mat', ...
     'active_sets', 'active_sets_array', ...
     'invH', 'invH_Ft', 'F', 'P', 'M1', 'M2', ...
     'H', 'c', 'm', 'n_x', 'n_u', 'u_max', ...
     'x_bounds', 'dt');

fprintf('离线数据已保存至 regionless_mpc_data.mat\n');

%% 6. 离线验证: 与 quadprog 对比
fprintf('\n========== 离线验证: 与 quadprog 对比 ==========\n');
rng(42);
n_test = 100;
max_error = 0;
max_error_x = zeros(n_x, 1);

for i = 1:n_test
    % 随机采样状态
    x_test = x_min + (x_max - x_min) .* rand(n_x, 1);

    % 区域无关求解器
    [u_rless, flag_rless] = regionless_mpc_eval(...
        x_test, active_sets, invH, invH_Ft, P, M1, M2);

    % quadprog 直接求解
    options = optimoptions('quadprog', 'Display', 'off', ...
        'Algorithm', 'interior-point-convex');
    [U_qp, ~, flag_qp] = quadprog(H, F' * x_test, P, M1 + M2 * x_test, ...
                                   [], [], [], [], [], options);

    if flag_rless == 1 && flag_qp == 1
        u_qp = U_qp(1);
        error_i = abs(u_rless - u_qp);
        if error_i > max_error
            max_error = error_i;
            max_error_x = x_test;
        end
    elseif flag_rless == 0 && flag_qp == 1
        fprintf('  警告: 测试点 %d - 区域无关求解器未找到可行解, quadprog 找到了\n', i);
    end
end

fprintf('测试 %d 个随机点, 最大误差: %.2e\n', n_test, max_error);
if max_error < 1e-3
    fprintf('*** 验证通过: 区域无关求解器与 quadprog 结果一致 ***\n');
else
    fprintf('*** 警告: 存在不一致, 最大误差 = %.2e ***\n', max_error);
end

fprintf('\n========== Step 3 完成 ==========\n');


%% ========================================================================
%  辅助函数
%  ========================================================================

function feasible = check_lp_feasibility(Ai, Q_Ai, q_Ai, invH, invH_Ft, ...
                                          P, M1, M2, A_bound, b_bound, n_x, c, m)
% 通过 LP 检查活跃集 Ai 是否对某些 x 是最优的
% 约束条件:
%   1. 参数边界: A_bound * x <= b_bound
%   2. 对偶可行性: Q_Ai * x + q_Ai >= 0  =>  -Q_Ai * x <= q_Ai
%   3. 原始可行性(非活跃约束): P_{I\A} * U(x) <= M1_{I\A} + M2_{I\A} * x
%      其中 U(x) = -invH*F'*x + invH*P_Ai'*lambda
%                = -(invH_Ft)*x + invH*P_Ai'*(Q_Ai*x + q_Ai)
%                = (-invH_Ft + invH*P_Ai'*Q_Ai)*x + invH*P_Ai'*q_Ai

    persistent lp_count;
    if isempty(lp_count)
        lp_count = 0;
    end
    lp_count = lp_count + 1;

    % 对偶可行性约束
    if ~isempty(Ai)
        A_dual = -Q_Ai;      % -Q_Ai * x <= q_Ai
        b_dual = q_Ai;
    else
        A_dual = zeros(0, n_x);
        b_dual = zeros(0, 1);
    end

    % 原始可行性约束 (非活跃约束)
    % U(x) = -invH*F'*x - invH*P_Ai'*lambda
    %      = (-invH_Ft - invH*P_Ai'*Q_Ai)*x + (-invH*P_Ai'*q_Ai)
    I_minus_A = setdiff(1:m, Ai);

    if ~isempty(I_minus_A) && ~isempty(Ai)
        PAi = P(Ai, :);
        P_inact = P(I_minus_A, :);
        M1_inact = M1(I_minus_A);
        M2_inact = M2(I_minus_A, :);

        K = -invH_Ft - invH * PAi' * Q_Ai;    % c x n_x
        k = -invH * PAi' * q_Ai;               % c x 1

        % P_inact * (K*x + k) <= M1_inact + M2_inact * x
        % => (P_inact * K - M2_inact) * x <= M1_inact - P_inact * k
        A_primal = P_inact * K - M2_inact;
        b_primal = M1_inact - P_inact * k;
    elseif ~isempty(I_minus_A) && isempty(Ai)
        % 空活跃集: U(x) = -invH * F' * x
        P_inact = P(I_minus_A, :);
        M1_inact = M1(I_minus_A);
        M2_inact = M2(I_minus_A, :);

        K = -invH_Ft;  % c x n_x

        A_primal = P_inact * K - M2_inact;
        b_primal = M1_inact - P_inact * zeros(c, 1);  % k = 0
    else
        A_primal = zeros(0, n_x);
        b_primal = zeros(0, 1);
    end

    % 合并所有约束
    A_lp = [A_bound; A_dual; A_primal];
    b_lp = [b_bound; b_dual; b_primal];

    % 可行性 LP (零目标)
    f = zeros(n_x, 1);
    options = optimoptions('linprog', 'Display', 'off', ...
                           'Algorithm', 'dual-simplex');
    [~, ~, exitflag] = linprog(f, A_lp, b_lp, [], [], [], [], options);

    feasible = (exitflag == 1);
end
