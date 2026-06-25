load('MC_7DOF_result_100.mat');

failIdx = find(~stable);

for k = 1:numel(failIdx)
    i = failIdx(k);

    case_i = result(i).case;

    param.M_vehicle = case_i.M_vehicle;
    param.tau_act   = case_i.tau_act;
    param.v         = case_i.v;
    param.h_bump    = case_i.h_bump;
    param.Lb        = 1.0;
    param.Ts        = 0.01;
    param.Tsim      = 6.0;
    param.wheelbase = 2.8;

    simOut = runOneCase(param);

    figure;
    plot(simOut.time, simOut.suspDefl * 1000, 'LineWidth', 1.2);
    yline(5, '--');
    yline(-5, '--');
    xline(3, ':');

    grid on;
    xlabel('Time [s]');
    ylabel('Suspension deflection [mm]');
    title(sprintf('Failed Case %d: v=%.2f km/h, h=%.3f m, M=%.1f kg, tau=%.3f s', ...
        i, case_i.v*3.6, case_i.h_bump, case_i.M_vehicle, case_i.tau_act));

    legend('FL','FR','RL','RR');
end