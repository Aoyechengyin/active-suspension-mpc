function simOut = runOneCase(param)
% 运行单组 Monte Carlo 闭环仿真

model = 'Fast_7DOF_eMPC_MC';

in = Simulink.SimulationInput(model);

in = in.setVariable('M_vehicle', param.M_vehicle);
in = in.setVariable('tau_act', param.tau_act);
in = in.setVariable('v_vehicle', param.v);
in = in.setVariable('h_bump', param.h_bump);
in = in.setVariable('Lb', param.Lb);
in = in.setVariable('Ts', param.Ts);
in = in.setVariable('wheelbase', param.wheelbase);

in = in.setModelParameter('StopTime', num2str(param.Tsim));

out = sim(in);

logs = out.logsout;

suspDefl_ts = logs.get('suspDefl').Values;

simOut.time = suspDefl_ts.Time;

data = squeeze(suspDefl_ts.Data);

% 保证输出为 N x 4
if size(data, 2) == 4
    simOut.suspDefl = data;
elseif size(data, 1) == 4
    simOut.suspDefl = data.';
else
    error('suspDefl 数据维度错误，应为 N x 4 或 4 x N。');
end

end