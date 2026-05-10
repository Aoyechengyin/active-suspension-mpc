% =========================================================================
% 诊断脚本: 排查 preview e-MPC 性能异常问题
% =========================================================================
clear; clc;

load('prediction_model.mat');
load('regionless_mpc_data.mat');

% 短仿真: 只有一个凸块
vx = 50 / 3.6;
t_end = 3;
[road, y_r, t_sim] = road_profile_generator(vx, dt, t_end, 'speedbump_long');

n_steps = length(t_sim);
n_x = size(A_s_d, 1);
n_z = size(Cz_d, 1);

fprintf('诊断: %d步仿真, 凸块在 ~15m 处\n', n_steps);

%% Preview case
fprintf('\n=== Preview case ===\n');
x = zeros(n_x, 1);
qp_count = 0;
for k = 1:n_steps
    % Regionless solver
    [u_rless, flag_rless] = regionless_mpc_eval(x, active_sets, invH, invH_Ft, P, M1, M2);

    % Quadprog ground truth
    options = optimoptions('quadprog', 'Display', 'off', 'Algorithm', 'interior-point-convex');
    [U_qp, ~, flag_qp] = quadprog(H, F' * x, P, M1 + M2 * x, [], [], [], [], [], options);

    if flag_qp == 1 && flag_rless == 1
        u_qp = U_qp(1);
        err = abs(u_rless - u_qp);
        if err > 100  % significant error
            fprintf('  k=%d: regionless=%.1f, quadprog=%.1f, err=%.1fN\n', k, u_rless, u_qp, err);
        end
    elseif flag_qp == 1 && flag_rless == 0
        qp_count = qp_count + 1;
        fprintf('  k=%d: regionless FAILED! quadprog=%.1f\n', k, U_qp(1));
    end

    % State update
    u_cmd = max(-u_max, min(u_max, u_rless));
    x_next = A_s_d * x + B_s_d * u_cmd + E_s_d * y_r(k);
    if k < n_steps
        x_next(6) = road(k + 1);
    end
    x = x_next;
end
fprintf('  Regionless failures: %d/%d\n', qp_count, n_steps);

%% No-preview case
fprintf('\n=== No-preview case ===\n');
x = zeros(n_x, 1);
qp_count = 0;
for k = 1:n_steps
    [u_rless, flag_rless] = regionless_mpc_eval(x, active_sets, invH, invH_Ft, P, M1, M2);
    if flag_rless == 0
        qp_count = qp_count + 1;
        fprintf('  k=%d: regionless FAILED!\n', k);
    end
    u_cmd = max(-u_max, min(u_max, u_rless));
    x_next = A_s_d * x + B_s_d * u_cmd;  % no y_r!
    if k < n_steps
        x_next(6) = road(k + 1);
    end
    x = x_next;
end
fprintf('  Regionless failures: %d/%d\n', qp_count, n_steps);

%% 检查权重建议
fprintf('\n=== 调参建议 ===\n');
fprintf('当前权重: rho1=%.1e (accel), rho2=%.1e (susp), rho3=%.1e (vel), rho4=%.1e (tire), rho5=%.1e (ctrl)\n', ...
    rho1, rho2, rho3, rho4, rho5);
fprintf('典型惩罚量级: accel ~1 m/s^2, susp ~0.01 m, vel ~1 m/s, tire ~0.01 m, ctrl ~5000 N\n');
fprintf('实际代价贡献: accel=%.1e, susp=%.1e, vel=%.1e, tire=%.1e, ctrl=%.1e\n', ...
    rho1*1^2, rho2*0.01^2, rho3*1^2, rho4*0.01^2, rho5*5000^2);
fprintf('平衡建议: 各贡献应在同一量级\n');
