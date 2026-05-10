function u_cmd = mpc_controller(x_aug)
%MPC_CONTROLLER Simulink MATLAB Function 块: 区域无关显式MPC控制器
%
%   u_cmd = mpc_controller(x_aug)
%
%   输入: x_aug - 增广状态向量 (8x1)
%         [x1; dx1; x1-x2; dx1-dx2; u_a; w0; w1; w2]
%   输出: u_cmd - 执行器力需求 (标量, N)
%
%   使用 persistent 变量加载预计算数据, 首次调用后数据常驻内存
%
%   参考: Theunissen et al., IEEE TIE, 2020

persistent data_loaded active_sets invH invH_Ft Pmat M1mat M2mat u_limit

% 首次调用时加载数据
if isempty(data_loaded)
    % 加载预计算的区域无关求解器数据
    s = coder.load('regionless_mpc_data.mat');

    % 提取变量
    active_sets = s.active_sets;
    invH = s.invH;
    invH_Ft = s.invH_Ft;
    Pmat = s.P;
    M1mat = s.M1;
    M2mat = s.M2;
    u_limit = s.u_max;

    data_loaded = true;
end

% 调用区域无关求解器
[u_opt, exitflag] = regionless_mpc_eval_codegen(...
    x_aug, active_sets, invH, invH_Ft, Pmat, M1mat, M2mat);

% 安全限幅
u_cmd = max(-u_limit, min(u_limit, u_opt));

% 警告: 如果未找到最优解 (exitflag == 0)
% 控制器使用退化解 (已在 regionless_mpc_eval_codegen 中处理)
end

function [u_opt, exitflag] = regionless_mpc_eval_codegen(x, active_sets, invH, invH_Ft, P, M1, M2)
%REGIONLESS_MPC_EVAL_CODEGEN 代码生成兼容的区域无关MPC在线评估
%
%   与 regionless_mpc_eval 功能相同, 但适配 MATLAB Coder 约束:
%   - 不使用 dynamic cell array 索引
%   - 预分配所有变量
%   - 使用 for 循环代替 vectorized 操作

u_opt = 0;
exitflag = 0;

% 约束右端项
c_dim = size(invH, 1);
b = M1 + M2 * x;

% 基线解 (无活跃约束)
U_base = -invH_Ft * x;

% 检查空活跃集
P_U_base = P * U_base;
feasible = true;
for j = 1:size(P, 1)
    if P_U_base(j) > b(j) + 1e-8
        feasible = false;
        break;
    end
end
if feasible
    u_opt = U_base(1);
    exitflag = 1;
    return;
end

% 遍历活跃集
n_sets = numel(active_sets);
for i = 1:n_sets
    Ai = active_sets(i).A;
    n_active = numel(Ai);

    if n_active == 0
        continue;
    end

    Q_i = active_sets(i).Q;
    q_i = active_sets(i).q;
    PAi = active_sets(i).PA;

    % 对偶可行性: lambda = Q_i * x + q_i >= 0
    lambda = Q_i * x + q_i;
    dual_feasible = true;
    for k = 1:n_active
        if lambda(k) < -1e-8
            dual_feasible = false;
            break;
        end
    end
    if ~dual_feasible
        continue;
    end

    % 候选解: U = U_base + invH * PAi' * lambda
    U_candidate = U_base - invH * (PAi' * lambda);

    % 原始可行性: P * U_candidate <= b
    primal_feasible = true;
    for j = 1:size(P, 1)
        Pj_U = 0;
        for k = 1:c_dim
            Pj_U = Pj_U + P(j, k) * U_candidate(k);
        end
        if Pj_U > b(j) + 1e-8
            primal_feasible = false;
            break;
        end
    end

    if primal_feasible
        u_opt = U_candidate(1);
        exitflag = 1;
        return;
    end
end

% 退化解: 限幅 LQR 解
u_opt = U_base(1);
u_limit_val = M1(1);  % u_max
if u_opt > u_limit_val
    u_opt = u_limit_val;
elseif u_opt < -u_limit_val
    u_opt = -u_limit_val;
end
end
