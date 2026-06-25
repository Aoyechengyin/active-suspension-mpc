function case_i = sampleCase()

%保守版，用于调通框架（记得注释掉重复变量）
% v_kmh = 15 + (30 - 15) * rand;
% case_i.h_bump = 0.05 + (0.15 - 0.05) * rand;

%严苛版，用于最终鲁棒性测试
v_kmh = 10 + (30 - 10) * rand;
case_i.h_bump = 0.05 + (0.18 - 0.05) * rand;

%% 车速：10–30 km/h
% v_kmh = 10 + (30 - 10) * rand;
case_i.v = v_kmh / 3.6;

% 整车质量：1800–2400 kg
case_i.M_vehicle = 1800 + (2400 - 1800) * rand;

% 作动器时间常数：0.01–0.10 s
case_i.tau_act = 0.01 + (0.10 - 0.01) * rand;

% 减速带高度：0.05–0.18 m
% case_i.h_bump = 0.05 + (0.18 - 0.05) * rand;

end