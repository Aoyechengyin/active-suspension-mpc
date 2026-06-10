% =========================================================================
% Step 1: 预测模型构建 (dt=0.001s, 方案A)
% 参考: Theunissen et al., IEEE TIE, 2020
% 参数来源: CarSim SUV 实测
% =========================================================================
clear; clc;

%% 1. CarSim 车辆参数
m1   = 397.5;        % 簧上质量, 单角 (kg)
m2f  = 51.1;         % 前悬簧下质量 (kg)
m2r  = 57.5;         % 后悬簧下质量 (kg)
k1f  = 146000;       % 前悬架刚度 (N/m)
k1r  = 46000;        % 后悬架刚度 (N/m)
c1   = 5;            % 悬架残余阻尼 (N/(m/s))
k2   = 300000;       % 轮胎刚度 (N/m)
tau  = 0.05;         % 执行器时间常数 (s)
u_a0 = 0;            % 执行器初始作动力 (N)

%% 2. MPC 参数 (方案A: dt=0.001)
dt   = 0.001;        % 采样周期 1ms
p    = 80;           % 预测时域 80步 = 80ms
c    = 10;           % 控制时域 10步 = 10ms
N    = 20;           % 预瞄点数 (w0~w20, 覆盖20ms)
u_max = 9000;        % 执行器力约束 (N)

%% 3. 成本函数权重
rho1 = 500;          % 簧上加速度
rho2 = 1e5;          % 悬架动挠度
rho3 = 10;           % 簧上速度
rho4 = 1e5;          % 轮胎动变形
rho5 = 1e-7;         % 控制力

%% 4. mp-QP 参数空间边界
n_road = N + 1;      % 路面状态数 = 21
n_x_total = 5 + n_road;  % 总状态维数 = 26

x_bounds = [ ...
    -0.10,  0.10;     % x1     (m)
    -1.00,  1.00;     % dx1    (m/s)
    -0.12,  0.12;     % x1-x2  (m)
    -4.00,  4.00;     % dx1-dx2(m/s)
    -u_max, u_max;    % u_a    (N)
    repmat([-0.15, 0.15], n_road, 1)  % w0~w20 (m)
];

%% 5. 连续时间 QC 模型 (含阻尼 c1)
m2 = (m2f + m2r) / 2;
k1 = (k1f + k1r) / 2;

A_qc = [ 0,    1,    0,                       0,                0;
         0,    0,   -k1/m1,                  -c1/m1,           -1/m1;
         0,    0,    0,                       1,                0;
         k2/m2, 0,  -(k1/m1 + k1/m2 + k2/m2),-(c1/m1 + c1/m2),-(1/m1 + 1/m2);
         0,    0,    0,                       0,               -1/tau ];

B_qc = [0; 0; 0; 0; 1/tau];
E_qc = [0; 0; 0; -k2/m2; 0];
C_qc = eye(5);
D_qc = zeros(5, 1);

sys_qc_c = ss(A_qc, [B_qc, E_qc], C_qc, [D_qc, zeros(5,1)]);

%% 6. 性能输出矩阵 Cz (26维增广状态)
% z = [ẍ1; x1-x2; ẋ1; x2-w0]
Cz = [ 0, 0, -k1/m1, -c1/m1, -1/m1, zeros(1, n_road);
       0, 0,       1,      0,     0,  zeros(1, n_road);
       0, 1,       0,      0,     0,  zeros(1, n_road);
       1, 0,      -1,      0,     0, -1, zeros(1, n_road-1) ];
Dz = zeros(4, 1);

%% 7. 离散化
sys_qc_d = c2d(sys_qc_c, dt, 'zoh');
A_qc_d = sys_qc_d.A;
B_qc_d = sys_qc_d.B(:, 1);
E_qc_d = sys_qc_d.B(:, 2);
Cz_d = Cz;

%% 8. 路面预瞄移位寄存器 (N+1=21 维)
A_r_d = zeros(n_road, n_road);
for i = 1:n_road-1
    A_r_d(i, i+1) = 1;
end
E_r_d = zeros(n_road, 1);
E_r_d(end) = 1;

%% 9. 增广系统 (26 维)
A_s_d = [A_qc_d,          E_qc_d, zeros(5, n_road-1);
         zeros(n_road, 5), A_r_d];
B_s_d = [B_qc_d; zeros(n_road, 1)];
E_s_d = [zeros(5, 1); E_r_d];
C_s_d = [Cz_d; eye(5), zeros(5, n_road)];
D_s_d = zeros(9, 1);

n_x = size(A_s_d, 1);
n_u = size(B_s_d, 2);
n_z = size(Cz_d, 1);

%% 10. 稳定性校验
eigA = eig(A_s_d);
fprintf('========== Step 1: 预测模型构建 (dt=%.4f) ==========\n', dt);
fprintf('  状态维数: n_x=%d (5 QC + %d road), n_u=%d, n_z=%d\n', n_x, n_road, n_u, n_z);
fprintf('  预测时域: p=%d (%.0fms)\n', p, p*dt*1000);
fprintf('  控制时域: c=%d (%.0fms)\n', c, c*dt*1000);
fprintf('  预瞄点数: N=%d (w10=10ms, w20=20ms)\n', N);
fprintf('  A_s_d 最大特征值幅值: %.6f\n', max(abs(eigA)));
if max(abs(eigA)) >= 1
    fprintf('  ** 警告: 系统开环不稳定 **\n');
end

%% 11. 权重矩阵
Wy = diag([rho1, rho2, rho3, rho4]);
Wu = rho5 * eye(c);

%% 12. 保存
save('prediction_model.mat', ...
     'A_s_d','B_s_d','E_s_d','C_s_d','D_s_d','Cz_d','Dz','Wy','Wu', ...
     'A_qc_d','B_qc_d','E_qc_d', ...
     'p','c','N','dt','tau','u_max','n_road','n_x_total', ...
     'm1','m2','k1','c1','k2', ...
     'rho1','rho2','rho3','rho4','rho5', ...
     'x_bounds','n_x','n_u','n_z');

fprintf('  模型已保存: prediction_model.mat\n');
fprintf('========== Step 1 完成 ==========\n');
