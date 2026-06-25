Nmc = 1000;
model = 'Fast_7DOF_eMPC_MC';

in(Nmc,1) = Simulink.SimulationInput(model);

cases = repmat(struct(), Nmc, 1);

for i = 1:Nmc
    cases(i) = sampleCase();

    in(i) = Simulink.SimulationInput(model);
    in(i) = in(i).setVariable('M_vehicle', cases(i).M_vehicle);
    in(i) = in(i).setVariable('tau_act', cases(i).tau_act);
    in(i) = in(i).setVariable('v_vehicle', cases(i).v);
    in(i) = in(i).setVariable('h_bump', cases(i).h_bump);
    in(i) = in(i).setVariable('Lb', 1.0);
    in(i) = in(i).setVariable('Ts', 0.01);
    in(i) = in(i).setModelParameter('StopTime', '5');
end

out = parsim(in, ...
    'ShowProgress', 'on', ...
    'UseFastRestart', 'on');