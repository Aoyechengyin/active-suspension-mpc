function [u_opt, exitflag, active_idx] = regionless_mpc_eval(x, active_sets, invH, invH_Ft, P, M1, M2)
%REGIONLESS_MPC_EVAL 区域无关显式MPC在线评估 (Algorithm 5, Borrelli et al. 2010)
%
%   [u_opt, exitflag] = regionless_mpc_eval(x, active_sets, invH, invH_Ft, P, M1, M2)
%
%   输入:
%     x            - 当前增广状态 (n_x x 1)
%     active_sets  - 活跃集结构体数组 (字段: .A, .Q, .q, .PA)
%     invH         - H^{-1}, 预计算的 Hessian 逆矩阵
%     invH_Ft      - H^{-1} * F^T, 预计算项
%     P, M1, M2    - QP 约束矩阵
%
%   输出:
%     u_opt        - 最优控制输入 (标量, U*(1))
%     exitflag     - 1=找到最优解, 0=未找到可行活跃集
%     active_idx   - 最优活跃集在列表中的索引 (0 if not found)
%
%   算法步骤 (对应 Borrelli et al. Algorithm 5):
%     1. 对每个候选活跃集 Ai:
%        a. 计算对偶变量 lambda = Q(Ai)*x + q(Ai)
%        b. 检查对偶可行性: lambda >= 0
%        c. 计算候选解 U = -invH*F'*x + invH*P_Ai'*lambda
%        d. 检查原始可行性: P*U <= M1 + M2*x
%        e. 若两者都满足 -> 最优解找到
%
%   参考:
%     Theunissen et al., IEEE TIE, 2020 (式18-22)
%     Borrelli et al., Automatica, 2010 (Algorithm 5)

u_opt = 0;
exitflag = 0;
active_idx = 0;

% 约束右端项 (只计算一次)
b = M1 + M2 * x;

% 预分配: 计算一次 U_no_active = -invH * F' * x
U_base = -invH_Ft * x;

n_sets = length(active_sets);

% 从空活跃集开始 (如果存在)
% 检查空活跃集: 所有对偶约束自动满足 (无活跃约束), 只需检查原始可行性
P_U_base = P * U_base;
if all(P_U_base <= b + 1e-6)
    u_opt = U_base(1);
    exitflag = 1;
    active_idx = 0;  % 空活跃集
    return;
end

% 遍历所有候选活跃集
for i = 1:n_sets
    Ai = active_sets{i}.A;
    Q_i = active_sets{i}.Q;
    q_i = active_sets{i}.q;

    if isempty(Ai)
        continue;  % 空活跃集已在上面处理
    end

    % Step 1: 对偶可行性检查
    % lambda = Q(Ai) * x + q(Ai) >= 0  [论文式(19)]
    lambda = Q_i * x + q_i;
    if any(lambda < -1e-6)
        continue;  % 对偶不可行
    end

    % Step 2: 计算候选最优控制序列
    % U = -invH * F' * x + invH * P_Ai' * lambda  [论文式(18)]
    PAi = active_sets{i}.PA;
    U_candidate = U_base - invH * PAi' * lambda;

    % Step 3: 原始可行性检查
    % P * U < M1 + M2 * x  [论文式(22)]
    if all(P * U_candidate <= b + 1e-6)
        u_opt = U_candidate(1);
        exitflag = 1;
        active_idx = i;
        return;
    end
end

% 未找到可行活跃集 - 使用限幅的 LQR 解
% (这种情况在参数空间覆盖范围内不应发生)
u_opt = U_base(1);
u_opt = max(-M1(1), min(M1(1), u_opt));  % 限幅到执行器范围
end
