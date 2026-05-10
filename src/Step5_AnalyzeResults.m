% =========================================================================
% Step 5: 结果分析与对比
% 对比 e-MPC (含/不含预瞄) 与被动悬架的性能
% 参考论文 Figs. 9-10, Tables III-V
% =========================================================================
clear; clc;

%% 1. 运行 MATLAB QC 模型闭环仿真
% 对于纯 MATLAB 验证 (在接入 CarSim 之前), 使用 QC 模型进行仿真
fprintf('========== Step 5: 结果分析 ==========\n');

% 加载模型和控制器数据
load('prediction_model.mat');
load('regionless_mpc_data.mat');

% 仿真工况
vx = 50 / 3.6;        % 车速 50 km/h -> m/s
dt_sim = dt;
t_end = 10;           % 仿真时间 10s
profile_type = 'speedbump_long';  % 论文 Test 2

% 生成路面
[road, y_r, t] = road_profile_generator(vx, dt_sim, t_end, profile_type);
n_steps = length(t);

fprintf('仿真工况: %s, 车速 %.1f km/h, 时长 %.0fs, 步数 %d\n', ...
    profile_type, vx*3.6, t_end, n_steps);

%% 2. 运行主动悬架 e-MPC 仿真 (含预瞄)
fprintf('\n--- e-MPC with preview ---\n');
[x_empc_prev, y_empc_prev, u_empc_prev] = simulate_qc_closed_loop(...
    A_s_d, B_s_d, E_s_d, Cz_d, active_sets, invH, invH_Ft, P, M1, M2, ...
    road, y_r, n_steps, dt_sim, u_max, true);

%% 3. 运行主动悬架 e-MPC 仿真 (不含预瞄, 即无 y_r 输入)
fprintf('\n--- e-MPC without preview ---\n');
[x_empc_noprev, y_empc_noprev, u_empc_noprev] = simulate_qc_closed_loop(...
    A_s_d, B_s_d, E_s_d, Cz_d, active_sets, invH, invH_Ft, P, M1, M2, ...
    road, zeros(size(y_r)), n_steps, dt_sim, u_max, false);

%% 4. 运行被动悬架仿真 (u = 0)
fprintf('\n--- Passive suspension ---\n');
[x_passive, y_passive] = simulate_passive_qc(...
    A_s_d, B_s_d, E_s_d, Cz_d, road, n_steps);

%% 5. 计算并对比性能指标
fprintf('\n========== 性能对比 ==========\n');

% 提取簧上质量加速度 (性能输出第1个)
acc_empc_prev = y_empc_prev(:, 1);
acc_empc_noprev = y_empc_noprev(:, 1);
acc_passive = y_passive(:, 1);

% 计算各频段RMS
freq_bands = {[0.1, 4], [4, 15], [0.1, 15]};
band_names = {'0-4 Hz', '4-15 Hz', '0-15 Hz'};

fprintf('\n%-20s %12s %12s %12s %12s\n', 'RMS Acceleration', 'Passive', 'eMPC(noPrev)', 'eMPC(Prev)', 'Improve%');
fprintf('%-70s\n', repmat('-', 1, 70));

for b = 1:length(freq_bands)
    rms_p = compute_rms(acc_passive, dt_sim, freq_bands{b});
    rms_n = compute_rms(acc_empc_noprev, dt_sim, freq_bands{b});
    rms_y = compute_rms(acc_empc_prev, dt_sim, freq_bands{b});

    impr_n = (rms_p - rms_n) / rms_p * 100;
    impr_y = (rms_p - rms_y) / rms_p * 100;

    fprintf('%-20s %12.4f %12.4f %12.4f %11.1f%%\n', ...
        band_names{b}, rms_p, rms_n, rms_y, impr_y);
end

% 悬架位移 RMS
susp_defl_prev = y_empc_prev(:, 2);
susp_defl_noprev = y_empc_noprev(:, 2);
susp_defl_passive = y_passive(:, 2);

fprintf('\n%-20s %12s %12s %12s\n', 'Susp Defl RMS', 'Passive', 'eMPC(noPrev)', 'eMPC(Prev)');
fprintf('%-20s %12.4f %12.4f %12.4f\n', ...
    'RMS (m)', ...
    rms(susp_defl_passive), rms(susp_defl_noprev), rms(susp_defl_prev));

% 轮胎变形 RMS
tire_defl_prev = y_empc_prev(:, 4);
tire_defl_noprev = y_empc_noprev(:, 4);
tire_defl_passive = y_passive(:, 4);

fprintf('\n%-20s %12s %12s %12s\n', 'Tire Defl RMS', 'Passive', 'eMPC(noPrev)', 'eMPC(Prev)');
fprintf('%-20s %12.4f %12.4f %12.4f\n', ...
    'RMS (m)', ...
    rms(tire_defl_passive), rms(tire_defl_noprev), rms(tire_defl_prev));

% 控制力统计
fprintf('\n%-20s %12s %12s\n', 'Control Force', 'eMPC(noPrev)', 'eMPC(Prev)');
fprintf('%-20s %12.1f %12.1f\n', ...
    'Max |u| (N)', ...
    max(abs(u_empc_noprev)), max(abs(u_empc_prev)));
fprintf('%-20s %12.1f %12.1f\n', ...
    'RMS u (N)', ...
    rms(u_empc_noprev), rms(u_empc_prev));

%% 6. 绘图
figure('Position', [100, 100, 1200, 900]);

% 时域对比 (参考论文 Fig. 9)
subplot(3, 2, 1);
plot(t, acc_passive, 'k-', 'LineWidth', 1); hold on;
plot(t, acc_empc_noprev, 'b--', 'LineWidth', 1);
plot(t, acc_empc_prev, 'r-', 'LineWidth', 1.5);
ylabel('Accel (m/s^2)'); xlabel('Time (s)');
title('Sprung Mass Acceleration');
legend('Passive', 'e-MPC noPrev', 'e-MPC Preview', 'Location', 'best');
grid on;

subplot(3, 2, 2);
plot(t, susp_defl_passive, 'k-', 'LineWidth', 1); hold on;
plot(t, susp_defl_noprev, 'b--', 'LineWidth', 1);
plot(t, susp_defl_prev, 'r-', 'LineWidth', 1.5);
ylabel('Deflection (m)'); xlabel('Time (s)');
title('Suspension Deflection');
legend('Passive', 'e-MPC noPrev', 'e-MPC Preview', 'Location', 'best');
grid on;

subplot(3, 2, 3);
plot(t, tire_defl_passive, 'k-', 'LineWidth', 1); hold on;
plot(t, tire_defl_noprev, 'b--', 'LineWidth', 1);
plot(t, tire_defl_prev, 'r-', 'LineWidth', 1.5);
ylabel('Deflection (m)'); xlabel('Time (s)');
title('Tire Deflection');
legend('Passive', 'e-MPC noPrev', 'e-MPC Preview', 'Location', 'best');
grid on;

subplot(3, 2, 4);
plot(t, u_empc_noprev, 'b--', 'LineWidth', 1); hold on;
plot(t, u_empc_prev, 'r-', 'LineWidth', 1.5);
yline(u_max, 'k:', 'LineWidth', 1); yline(-u_max, 'k:', 'LineWidth', 1);
ylabel('Force (N)'); xlabel('Time (s)');
title('Actuator Force Demand');
legend('e-MPC noPrev', 'e-MPC Preview', 'Bounds', 'Location', 'best');
grid on;

% PSD 对比 (参考论文 Fig. 10)
subplot(3, 2, 5);
[psd_p, f_p] = pwelch(acc_passive, [], [], [], 1/dt_sim);
[psd_n, ~] = pwelch(acc_empc_noprev, [], [], [], 1/dt_sim);
[psd_y, ~] = pwelch(acc_empc_prev, [], [], [], 1/dt_sim);
semilogy(f_p, psd_p, 'k-', 'LineWidth', 1); hold on;
semilogy(f_p, psd_n, 'b--', 'LineWidth', 1);
semilogy(f_p, psd_y, 'r-', 'LineWidth', 1.5);
xlim([0, 20]);
ylabel('PSD (m^2/s^4/Hz)'); xlabel('Frequency (Hz)');
title('Acceleration PSD');
legend('Passive', 'e-MPC noPrev', 'e-MPC Preview', 'Location', 'best');
grid on;

subplot(3, 2, 6);
bar_data = [
    rms(acc_passive), rms(susp_defl_passive), rms(tire_defl_passive);
    rms(acc_empc_noprev), rms(susp_defl_noprev), rms(tire_defl_noprev);
    rms(acc_empc_prev), rms(susp_defl_prev), rms(tire_defl_prev)
];
bh = bar(bar_data);
set(gca, 'XTickLabel', {'Passive', 'eMPC noPrev', 'eMPC Preview'});
legend({'Accel (m/s^2)', 'Susp Defl (m)', 'Tire Defl (m)'}, 'Location', 'best');
title('RMS Performance Comparison');
grid on;

sgtitle('Regionless e-MPC vs Passive Suspension Performance');

%% 7. 保存结果
save('simulation_results.mat', ...
    't', 'dt_sim', ...
    'acc_passive', 'acc_empc_noprev', 'acc_empc_prev', ...
    'susp_defl_passive', 'susp_defl_noprev', 'susp_defl_prev', ...
    'tire_defl_passive', 'tire_defl_noprev', 'tire_defl_prev', ...
    'u_empc_noprev', 'u_empc_prev', ...
    'x_empc_prev', 'x_empc_noprev', 'x_passive', ...
    'vx', 'profile_type');

fprintf('\n仿真结果已保存至 simulation_results.mat\n');
fprintf('========== Step 5 完成 ==========\n');


%% ========================================================================
%  辅助函数
%  ========================================================================

function rms_val = compute_rms(signal, dt, f_range)
% 计算指定频段内的 RMS 值 (论文式26)
% 使用 PSD 积分方法
[psd, f] = pwelch(signal, [], [], [], 1/dt);
idx = (f >= f_range(1)) & (f <= f_range(2));
rms_val = sqrt(trapz(f(idx), psd(idx)));
end

function [x_hist, y_hist, u_hist] = simulate_qc_closed_loop(...
    A, B, E, Cz, active_sets, invH, invH_Ft, P, M1, M2, ...
    road, y_r, n_steps, dt_sim, u_max, use_preview)
% QC模型闭环仿真 (主动悬架 e-MPC)

n_x = size(A, 1);
n_z = size(Cz, 1);

x = zeros(n_x, 1);
x_hist = zeros(n_steps, n_x);
y_hist = zeros(n_steps, n_z);
u_hist = zeros(n_steps, 1);

tic;
for k = 1:n_steps
    x_hist(k, :) = x';

    % 性能输出
    y = Cz * x;
    y_hist(k, :) = y';

    % 更新预瞄状态 (w0, w1, w2)
    % w0 = 当前路面, w1/w2 通过移位寄存器更新

    % e-MPC 控制器
    [u_opt, flag] = regionless_mpc_eval(x, active_sets, invH, invH_Ft, P, M1, M2);

    % 安全限幅
    u_cmd = max(-u_max, min(u_max, u_opt));
    u_hist(k) = u_cmd;

    % 状态更新: x(k+1) = A*x(k) + B*u(k) + E*y_r(k)
    if use_preview
        x = A * x + B * u_cmd + E * y_r(k);
    else
        x = A * x + B * u_cmd;
    end

    % 更新路面预瞄状态 (w0 = road(k+1), 移位 w1<-w0, w2<-w1)
    if k < n_steps
        x(6) = road(k + 1);  % w0 = 下一时刻路面
        % w1, w2 由移位寄存器自动更新
    end
end

elapsed = toc;
fprintf('  仿真完成: %d 步, 耗时 %.2f 秒 (%.2f ms/步)\n', ...
    n_steps, elapsed, elapsed/n_steps*1000);
end

function [x_hist, y_hist] = simulate_passive_qc(A, B, E, Cz, road, n_steps)
% QC模型被动悬架仿真 (u = 0, 无执行器力)

n_x = size(A, 1);
n_z = size(Cz, 1);

x = zeros(n_x, 1);
x_hist = zeros(n_steps, n_x);
y_hist = zeros(n_steps, n_z);

for k = 1:n_steps
    x_hist(k, :) = x';
    y = Cz * x;
    y_hist(k, :) = y';

    % 被动: u = 0
    x = A * x;  % B*u = 0, E*y_r = 0 (无预瞄)

    % 更新路面状态
    if k < n_steps
        x(6) = road(k + 1);
    end
end

fprintf('  被动仿真完成: %d 步\n', n_steps);
end
