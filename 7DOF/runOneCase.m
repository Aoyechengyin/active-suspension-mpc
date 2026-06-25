function simOut = runOneCase(param)
% 运行单组 Monte Carlo 闭环仿真

model = 'Fast_7DOF_eMPC_MC';

in = Simulink.SimulationInput(model);

in = in.setVariable('M_vehicle', param.M_vehicle, 'Workspace', 'global-workspace');
in = in.setVariable('tau_act', param.tau_act, 'Workspace', 'global-workspace');
in = in.setVariable('v_vehicle', param.v, 'Workspace', 'global-workspace');
in = in.setVariable('h_bump', param.h_bump, 'Workspace', 'global-workspace');
in = in.setVariable('Lb', param.Lb, 'Workspace', 'global-workspace');
in = in.setVariable('Ts', param.Ts, 'Workspace', 'global-workspace');
in = in.setVariable('wheelbase', param.wheelbase, 'Workspace', 'global-workspace');

in = in.setModelParameter('StopTime', num2str(param.Tsim));

out = sim(in);

if ~isprop(out, 'logsout') || isempty(out.logsout)
    error(['仿真结果中没有 logsout。请在 Model Settings 中开启 Signal logging，' ...
           '并对 suspDefl 信号线执行 Log Selected Signals。']);
end

logs = out.logsout;

names = logs.getElementNames;

debugLogSignals = false;

if debugLogSignals
    disp('当前 logsout 中包含的信号名：');
    disp(names);
end

idx = find(strcmp(names, 'suspDefl'), 1);

if isempty(idx)
    error(['logsout 中没有名为 suspDefl 的信号。' ...
           '请检查 Plant7DOF 的 suspDefl 输出信号线是否命名为 suspDefl，' ...
           '并且是否执行了 Log Selected Signals。']);
end

sig = logs.get('suspDefl');

if isempty(sig)
    error('logs.get(''suspDefl'') 返回为空。');
end

suspDefl_ts = sig.Values;

simOut.time = suspDefl_ts.Time;

data = squeeze(suspDefl_ts.Data);

if size(data, 2) == 4
    simOut.suspDefl = data;
elseif size(data, 1) == 4
    simOut.suspDefl = data.';
else
    error('suspDefl 数据维度错误。当前尺寸为：%s', mat2str(size(data)));
end

end