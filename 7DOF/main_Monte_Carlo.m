clear; clc;

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);
addpath(fullfile(thisDir, 'road'));
addpath(fullfile(thisDir, 'post'));
addpath(fullfile(thisDir, 'model'));

Nmc = 100;     % 先跑 10 组，不要一开始 1000
Ts = 0.01;
Tsim = 5.0;
Lb = 1.0;

% 名义参数
param0.M_vehicle = 2100;      % kg
param0.tau_act = 0.05;        % s
param0.wheelbase = 2.8;       % m，根据你的车改
param0.Ts = Ts;
param0.Tsim = Tsim;

result = struct();
stable = false(Nmc,1);

rng(1);  % 固定随机种子，方便复现实验

for i = 1:Nmc

    % 1. 随机采样
    case_i = sampleCase();

    % 2. 更新模型参数
    param = param0;
    param.M_vehicle = case_i.M_vehicle;
    param.tau_act   = case_i.tau_act;
    param.v         = case_i.v;
    param.h_bump    = case_i.h_bump;
    param.Lb        = Lb;

    % 3. 运行一次闭环仿真
    simOut = runOneCase(param);

    % 4. 稳定性验收：前轴撞击减速带 3 s 后
    t_front_hit = 0.0;
    
    defl = simOut.suspDefl;   % N x 4, [FL FR RL RR]
    time = simOut.time;
    
    opts = struct();
    opts.settleTime = 3.0;
    opts.windowLength = 1.0;
    opts.deflTol = 0.005;
    
    [stable(i), metrics] = checkStability(time, defl, t_front_hit, opts);
    
    % 5. 保存结果
    result(i).case = case_i;
    result(i).defl_check = metrics.defl_check;
    result(i).metrics = metrics;
    result(i).stable = stable(i);
    
    fprintf('Case %4d / %4d | stable = %d | max window defl = %.3f mm | reason = %s\n', ...
        i, Nmc, stable(i), metrics.max_abs_defl_window*1000, metrics.reason);
end

pass_rate = mean(stable) * 100;

fprintf('\nMonte Carlo finished.\n');
fprintf('Pass rate = %.2f %%\n', pass_rate);
fprintf('Failed cases = %d / %d\n', sum(~stable), Nmc);
save('MC_7DOF_result_100.mat', 'result', 'stable', 'pass_rate');