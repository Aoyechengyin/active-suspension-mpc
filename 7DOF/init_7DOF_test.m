clear; clc;

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);
addpath(fullfile(thisDir, 'road'));
addpath(fullfile(thisDir, 'post'));
addpath(fullfile(thisDir, 'model'));

% 给 Simulink 手动运行时使用的默认变量
M_vehicle = 2100;
tau_act = 0.05;
v_vehicle = 20/3.6;
h_bump = 0.08;
Lb = 1.0;
Ts = 0.01;
wheelbase = 2.8;

% 仿真时间
Tsim = 5.0;

model = 'Fast_7DOF_eMPC_MC';

load_system(model);

set_param(model, 'StopTime', num2str(Tsim));
set_param(model, 'SignalLogging', 'on');
set_param(model, 'SignalLoggingName', 'logsout');

open_system(model);