function active_sets = enumerate_active_sets_sampling(H, F, P, M1, M2, invH, x_bounds, n_x, c, n_samples)
%ENUMERATE_ACTIVE_SETS_SAMPLING 基于采样的活跃集枚举 (备用方法)
%
%   通过随机采样状态空间并求解 QP 来发现最优活跃集
%   比 LP 方法更可靠, 但可能漏掉覆盖范围小的活跃集
%
%   输入:
%     H, F, P, M1, M2 - QP 矩阵
%     invH            - H^{-1}
%     x_bounds        - 参数边界 (n_x x 2)
%     n_x, c          - 状态和优化变量维数
%     n_samples       - 采样点数 (默认 5000)
%
%   输出:
%     active_sets     - 活跃集 cell array

if nargin < 9
    n_samples = 5000;
end

x_min = x_bounds(:, 1);
x_max = x_bounds(:, 2);
invH_Ft = invH * F';

fprintf('  基于采样的活跃集枚举: %d 个采样点...\n', n_samples);

% 存储已发现的活跃集 (使用字符串键)
active_set_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
q_cache = containers.Map('KeyType', 'char', 'ValueType', 'any');

rng(42);

for i = 1:n_samples
    % 随机采样状态
    x = x_min + (x_max - x_min) .* rand(n_x, 1);

    % 用 quadprog 求解 QP
    options = optimoptions('quadprog', 'Display', 'off', ...
        'Algorithm', 'interior-point-convex');
    [U_qp, ~, exitflag] = quadprog(H, F' * x, P, M1 + M2 * x, ...
                                   [], [], [], [], [], options);

    if exitflag ~= 1
        continue;
    end

    % 识别最优活跃集
    residual = P * U_qp - (M1 + M2 * x);
    Ai = find(abs(residual) < 1e-5)';
    key = mat2str(Ai);

    if ~active_set_map.isKey(key)
        n_active = length(Ai);
        if n_active > c
            continue;
        end

        PAi = P(Ai, :);
        M2Ai = M2(Ai, :);
        M1Ai = M1(Ai);

        S = PAi * invH * PAi';
        if n_active > 0 && rcond(S) < 1e-10
            continue;
        end

        if n_active > 0
            invS = S \ eye(n_active);
            Q_Ai = -invS * (M2Ai + PAi * invH_Ft);
            q_Ai = -invS * M1Ai;
        else
            Q_Ai = zeros(0, n_x);
            q_Ai = zeros(0, 1);
        end

        as_struct = struct('A', Ai, 'Q', Q_Ai, 'q', q_Ai, 'PA', PAi);
        active_set_map(key) = as_struct;
    end
end

% 转为 cell array
keys_list = active_set_map.keys();
active_sets = cell(1, length(keys_list));
for i = 1:length(keys_list)
    active_sets{i} = active_set_map(keys_list{i});
end

fprintf('  发现 %d 个唯一活跃集\n', length(active_sets));
end
