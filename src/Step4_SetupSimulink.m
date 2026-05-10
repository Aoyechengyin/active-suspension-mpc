% =========================================================================
% Step 4: CarSim/Simulink 联合仿真设置
%
% 本脚本提供:
%   1. MATLAB QC 模型闭环仿真 (纯 MATLAB, 用于初步验证)
%   2. Simulink 模型构建说明 (需 CarSim S-Function)
% =========================================================================
clear; clc;

fprintf('========== Step 4: 仿真环境设置 ==========\n');

%% 1. 纯 MATLAB 仿真: QC 模型闭环 (不依赖 CarSim/Simulink)
% 此仿真用于在接入 CarSim 之前验证控制器性能
fprintf('\n--- 运行纯 MATLAB QC 模型闭环仿真 ---\n');

% 加载数据
load('prediction_model.mat');
load('regionless_mpc_data.mat');

% 仿真参数
vx = 50 / 3.6;        % 50 km/h
t_end = 5;            % 5 秒
profile_type = 'speedbump_long';

% 生成路面
[road, y_r, t_sim] = road_profile_generator(vx, dt, t_end, profile_type);
n_steps = length(t_sim);

fprintf('仿真: %s, vx=%.1f km/h, %d 步\n', profile_type, vx*3.6, n_steps);

%% 2. e-MPC 含预瞄仿真
fprintf('\n=== e-MPC with Preview ===\n');
[x_prev, y_prev, u_prev] = qc_sim_mpc(...
    A_s_d, B_s_d, E_s_d, Cz_d, active_sets, invH, invH_Ft, ...
    P, M1, M2, road, y_r, n_steps, u_max, true);

%% 3. e-MPC 不含预瞄仿真
fprintf('\n=== e-MPC without Preview ===\n');
[x_noprev, y_noprev, u_noprev] = qc_sim_mpc(...
    A_s_d, B_s_d, E_s_d, Cz_d, active_sets, invH, invH_Ft, ...
    P, M1, M2, road, zeros(size(y_r)), n_steps, u_max, false);

%% 4. 被动悬架仿真
fprintf('\n=== Passive Suspension ===\n');
[x_pass, y_pass] = qc_sim_passive(A_s_d, Cz_d, road, n_steps);

%% 5. 绘制仿真结果
figure('Position', [50, 50, 1400, 900]);

% 加速度时域 (参考论文 Fig. 9)
subplot(2, 3, 1);
plot(t_sim, y_pass(:,1), 'k-', 'LineWidth', 1); hold on;
plot(t_sim, y_noprev(:,1), 'b--', 'LineWidth', 1);
plot(t_sim, y_prev(:,1), 'r-', 'LineWidth', 1.5);
ylabel('Accel (m/s^2)'); xlabel('Time (s)');
title('Sprung Mass Acceleration');
legend('Passive', 'eMPC noPrev', 'eMPC Preview');
grid on;

% 悬架位移
subplot(2, 3, 2);
plot(t_sim, y_pass(:,2), 'k-', 'LineWidth', 1); hold on;
plot(t_sim, y_noprev(:,2), 'b--', 'LineWidth', 1);
plot(t_sim, y_prev(:,2), 'r-', 'LineWidth', 1.5);
ylabel('Deflection (m)'); xlabel('Time (s)');
title('Suspension Deflection');
legend('Passive', 'eMPC noPrev', 'eMPC Preview');
grid on;

% 轮胎变形
subplot(2, 3, 3);
plot(t_sim, y_pass(:,4), 'k-', 'LineWidth', 1); hold on;
plot(t_sim, y_noprev(:,4), 'b--', 'LineWidth', 1);
plot(t_sim, y_prev(:,4), 'r-', 'LineWidth', 1.5);
ylabel('Deflection (m)'); xlabel('Time (s)');
title('Tire Deflection');
legend('Passive', 'eMPC noPrev', 'eMPC Preview');
grid on;

% 控制力
subplot(2, 3, 4);
plot(t_sim, u_noprev, 'b--', 'LineWidth', 1); hold on;
plot(t_sim, u_prev, 'r-', 'LineWidth', 1.5);
yline(u_max, 'k:'); yline(-u_max, 'k:');
ylabel('Force (N)'); xlabel('Time (s)');
title('Actuator Force');
legend('eMPC noPrev', 'eMPC Preview', 'Bounds');
grid on;

% PSD (参考论文 Fig. 10)
subplot(2, 3, 5);
[psd_p, f_p] = pwelch(y_pass(:,1), [], [], [], 1/dt);
[psd_n, ~] = pwelch(y_noprev(:,1), [], [], [], 1/dt);
[psd_y, ~] = pwelch(y_prev(:,1), [], [], [], 1/dt);
semilogy(f_p, psd_p, 'k-', 'LineWidth', 1); hold on;
semilogy(f_p, psd_n, 'b--', 'LineWidth', 1);
semilogy(f_p, psd_y, 'r-', 'LineWidth', 1.5);
xlim([0, 15]); grid on;
ylabel('Accel PSD (m^2/s^4/Hz)'); xlabel('Frequency (Hz)');
title('Acceleration PSD');
legend('Passive', 'eMPC noPrev', 'eMPC Preview');

% 性能柱状图
subplot(2, 3, 6);
rms_data = [
    rms(y_pass(:,1)), rms(y_pass(:,2)), rms(y_pass(:,4));
    rms(y_noprev(:,1)), rms(y_noprev(:,2)), rms(y_noprev(:,4));
    rms(y_prev(:,1)), rms(y_prev(:,2)), rms(y_prev(:,4))
];
bar(rms_data);
set(gca, 'XTickLabel', {'Passive', 'eMPC noPrev', 'eMPC Preview'});
legend({'Accel (m/s^2)', 'Susp Defl (m)', 'Tire Defl (m)'}, 'Location', 'best');
title('RMS Performance (0-15 Hz)');
grid on;

sgtitle(sprintf('Regionless e-MPC Performance: %s at %.0f km/h', ...
    strrep(profile_type,'_',' '), vx*3.6));

%% 6. 打印性能对比表
fprintf('\n========== 性能对比摘要 ==========\n');
fprintf('| %-15s | %10s | %10s | %10s | %10s |\n', ...
    'Metric', 'Passive', 'eMPC noPrev', 'eMPC Prev', 'Improv%');
fprintf('|%s|\n', repmat('-', 1, 63));

metrics = {'Accel RMS', 'Susp Defl RMS', 'Tire Defl RMS'};
for mi = 1:3
    rms_p = rms_data(1, mi);
    rms_y = rms_data(3, mi);
    impr = (rms_p - rms_y) / rms_p * 100;
    fprintf('| %-15s | %10.4f | %10.4f | %10.4f | %9.1f%% |\n', ...
        metrics{mi}, rms_data(1,mi), rms_data(2,mi), rms_data(3,mi), impr);
end
fprintf('\n');

%% 7. 保存结果
save('simulation_results.mat', ...
    't_sim', 'dt', 'vx', 'profile_type', ...
    'y_pass', 'y_noprev', 'y_prev', ...
    'x_pass', 'x_noprev', 'x_prev', ...
    'u_noprev', 'u_prev', 'u_max');

fprintf('仿真结果已保存至 simulation_results.mat\n');
fprintf('\n');
fprintf('========== CarSim 集成说明 ==========\n');
fprintf('要将此控制器与 CarSim 联合仿真:\n');
fprintf('1. 在 CarSim 中打开车辆模型, 选择 "Send to Simulink"\n');
fprintf('2. 在 Simulink 模型中添加 CarSim S-Function 块\n');
fprintf('3. CarSim 输出 -> 状态估计器 -> mpc_controller.m -> 执行器模型 -> CarSim 输入\n');
fprintf('4. 路面输入由 road_profile_generator.m 生成, 注入到 CarSim 车轮\n');
fprintf('5. 使用固定步长求解器 (dt = %.3f s)\n', dt);
fprintf('=======================================\n');


%% ========================================================================
%  辅助仿真函数
%  ========================================================================

function [x_hist, y_hist, u_hist] = qc_sim_mpc(A, B, E, Cz, ...
    active_sets, invH, invH_Ft, P, M1, M2, ...
    road, y_r, n_steps, u_max, use_preview)
% QC模型闭环仿真 (e-MPC)

n_x = size(A, 1);
n_z = size(Cz, 1);

x = zeros(n_x, 1);
x_hist = zeros(n_steps, n_x);
y_hist = zeros(n_steps, n_z);
u_hist = zeros(n_steps, 1);

exitflag_hist = zeros(n_steps, 1);

tic;
for k = 1:n_steps
    x_hist(k, :) = x';
    y_hist(k, :) = (Cz * x)';

    % 区域无关 e-MPC
    [u_opt, flag] = regionless_mpc_eval(x, active_sets, invH, invH_Ft, P, M1, M2);
    exitflag_hist(k) = flag;

    % 安全限幅
    u_cmd = max(-u_max, min(u_max, u_opt));
    u_hist(k) = u_cmd;

    % 执行器动力学 (一阶, 已包含在状态方程中)
    % x(k+1) = A*x(k) + B*u(k) + E*y_r(k)
    if use_preview
        x_next = A * x + B * u_cmd + E * y_r(k);
    else
        x_next = A * x + B * u_cmd;
    end

    % 更新路面预瞄状态
    if k < n_steps
        x_next(6) = road(k + 1);  % w0
    end

    x = x_next;
end

elapsed = toc;
n_fail = sum(exitflag_hist == 0);
fprintf('  完成: %.2f s, %.2f ms/步, 失败 %d/%d 步\n', ...
    elapsed, elapsed/n_steps*1000, n_fail, n_steps);
if n_fail > 0
    fprintf('  警告: %d 步未找到最优活跃集, 使用退化解\n', n_fail);
end
end

function [x_hist, y_hist] = qc_sim_passive(A, Cz, road, n_steps)
% QC模型被动悬架仿真 (u=0)

n_x = size(A, 1);
n_z = size(Cz, 1);

x = zeros(n_x, 1);
x_hist = zeros(n_steps, n_x);
y_hist = zeros(n_steps, n_z);

for k = 1:n_steps
    x_hist(k, :) = x';
    y_hist(k, :) = (Cz * x)';

    % 被动: 无控制力, 无预瞄
    x_next = A * x;
    if k < n_steps
        x_next(6) = road(k + 1);
    end
    x = x_next;
end

fprintf('  完成: %d 步\n', n_steps);
end
