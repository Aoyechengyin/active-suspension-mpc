% =========================================================================
% Step 1: 面向无区域显式MPC的主动悬架预测模型构建
% 参考: Theunissen et al., "Regionless Explicit MPC of Active Suspension
%        Systems With Preview", IEEE TIE, 2020
% =========================================================================
clear; clc;

%% 1. 车辆与执行器物理参数定义
m1 = 450;      % 簧上质量 (kg) - 单角
m2 = 45;       % 簧下质量 (kg)
k1 = 20000;    % 悬架刚度 (N/m)
k2 = 200000;   % 轮胎刚度 (N/m)
tau = 0.05;    % 执行器时间常数 (s), 论文 Section IV-C: tau = 50 ms
dt = 0.01;     % MPC 离散控制周期 (s), 论文: dt = 10 ms

%% 2. MPC 参数 (论文 Section IV-C)
p = 8;         % 预测时域 (prediction horizon)
c = 6;         % 控制时域 (control horizon)
N = 2;         % 预瞄点数 (w0, w1, w2, 共N+1=3个道路状态)
u_max = 9000;  % 执行器力约束 (N), 论文: |u| < 9000 N

%% 3. 成本函数权重 (论文 Section III-C, 式16)
% J = sum_i [rho1*acc^2 + rho2*suspDefl^2 + rho3*vel^2 + rho4*tireDefl^2] + sum_j rho5*u^2
rho1 = 500;    % 簧上质量加速度权重 (核心目标)
rho2 = 1e5;    % 悬架动挠度权重 (防止过度行程)
rho3 = 5;      % 簧上质量速度权重
rho4 = 1e5;    % 轮胎动变形权重
rho5 = 1e-7;   % 控制力权重

%% 4. mp-QP 参数空间边界 (论文 Section IV-C)
% 状态向量 x_aug = [x1; dx1; x1-x2; dx1-dx2; u_a; w0; w1; w2]
x_bounds = [ ...
    -0.10,  0.10;    % x1:    车身位移 (m)
    -0.50,  0.50;    % dx1:   车身速度 (m/s)
    -0.15,  0.15;    % x1-x2: 悬架位移 (m)
    -4.00,  4.00;    % dx1-dx2: 悬架速度 (m/s)
    -u_max, u_max;   % u_a:   实际执行器力 (N)
    -0.15,  0.15;    % w0:    当前路面高程 (m)
    -0.15,  0.15;    % w1:    预瞄路面高程1 (m)
    -0.15,  0.15     % w2:    预瞄路面高程2 (m)
];

%% 5. 构建连续时间四分之一车辆模型 (QC Model)
% 论文式(1): 状态 x_qc = [x1; dx1; x1-x2; dx1-dx2; u_a]
% 输入: u (执行器需求力), 扰动: w0 (当前车轮处路面高程)
% 假设 c1 ≈ 0, c2 ≈ 0 (论文 Section II)

A_qc = [ 0, 1, 0, 0, 0;
         0, 0, -k1/m1, 0, -1/m1;
         0, 0, 0, 1, 0;
         k2/m2, 0, -(k1/m1 + k1/m2 + k2/m2), 0, -(1/m1 + 1/m2);
         0, 0, 0, 0, -1/tau ];

B_qc = [ 0; 0; 0; 0; 1/tau ];

E_qc = [ 0; 0; 0; -k2/m2; 0 ];

C_qc = eye(5);
D_qc = zeros(5, 1);

% 构建连续系统状态空间对象
sys_qc_c = ss(A_qc, [B_qc, E_qc], C_qc, [D_qc, zeros(5,1)]);

%% 6. 性能输出矩阵 Cz
% 论文式(16) 惩罚量: z = [ẍ1; x1-x2; ẋ1; x2-w0]
% 增广状态: x_aug = [x1; dx1; x1-x2; dx1-dx2; u_a; w0; w1; w2]
% ẍ1 = -(k1/m1)*(x1-x2) - ua/m1  (连续时间关系)
% x2 - w0 = x1 - (x1-x2) - w0
Cz = [ 0, 0, -k1/m1, 0, -1/m1,  0, 0, 0;   % ẍ1
       0, 0,       1, 0,     0,  0, 0, 0;   % x1-x2
       0, 1,       0, 0,     0,  0, 0, 0;   % ẋ1
       1, 0,      -1, 0,     0, -1, 0, 0 ]; % x2-w0

Dz = zeros(4, 1);

%% 7. 模型离散化 (Zero-Order Hold)
sys_qc_d = c2d(sys_qc_c, dt, 'zoh');

A_qc_d = sys_qc_d.A;
B_qc_d = sys_qc_d.B(:, 1);  % 对应控制输入 u
E_qc_d = sys_qc_d.B(:, 2);  % 对应扰动输入 w0

% 离散性能输出矩阵: 使用离散化后的QC状态
% 注: 离散化后 Cz_d 需基于离散状态计算加速度近似
% 这里使用连续时间Cz作为近似 (论文采用此方法)
Cz_d = Cz;  % 对输出使用相同的线性组合近似

%% 8. 构建路面预瞄移位寄存器模型
% 论文式(4)-(5): 预瞄状态 w_hat = [w0; w1; w2]
% 预瞄传感器输入 y_r(k) = w_N(k+1) = w_{N+1}(k) [论文式(5)]

A_r_d = [ 0, 1, 0;
          0, 0, 1;
          0, 0, 0 ];

E_r_d = [ 0; 0; 1 ];

%% 9. 组合扩展状态空间模型
% 论文式(6)-(7): 增广状态 x_aug = [x1; dx1; x1-x2; dx1-dx2; u_a; w0; w1; w2]
% 总状态数: 5 QC + 3 road = 8

% 构建组合系统A矩阵
A_s_d = [ A_qc_d,                E_qc_d, zeros(5, 2);
          zeros(3, 5),           A_r_d ];

% 构建组合系统B矩阵
B_s_d = [ B_qc_d;
          zeros(3, 1) ];

% 构建组合系统E矩阵 (对应未来路面输入 y_r)
E_s_d = [ zeros(5, 1);
          E_r_d ];

% 组合输出矩阵 (用于状态反馈)
C_s_d = [ Cz_d;                % 性能输出 (4行)
          eye(5), zeros(5,3) ]; % QC状态输出 (5行)

D_s_d = zeros(9, 1);

%% 10. 输出模型摘要与保存
n_x = size(A_s_d, 1);   % 状态维数 = 8
n_u = size(B_s_d, 2);   % 控制维数 = 1
n_z = size(Cz_d, 1);    % 性能输出维数 = 4

fprintf('========== 预测模型构建完成 ==========\n');
fprintf('增广状态维数:    %d\n', n_x);
fprintf('控制输入维数:    %d\n', n_u);
fprintf('性能输出维数:    %d\n', n_z);
fprintf('预测时域 p:      %d\n', p);
fprintf('控制时域 c:      %d\n', c);
fprintf('预瞄点数 N:      %d\n', N);
fprintf('采样周期 dt:     %.3f s\n', dt);
fprintf('执行器约束:      ±%.0f N\n', u_max);
fprintf('系统矩阵维度:\n');
fprintf('  A_s_d: %d x %d\n', size(A_s_d));
fprintf('  B_s_d: %d x %d\n', size(B_s_d));
fprintf('  E_s_d: %d x %d\n', size(E_s_d));

% 构建权重矩阵
Wy = diag([rho1, rho2, rho3, rho4]);  % 性能输出权重
Wu = rho5 * eye(c);                    % 控制力权重 (控制时域维度)

% 保存预测模型数据
save('prediction_model.mat', ...
     'A_s_d', 'B_s_d', 'E_s_d', 'C_s_d', 'D_s_d', ...
     'Cz_d', 'Dz', 'Wy', 'Wu', ...
     'A_qc_d', 'B_qc_d', 'E_qc_d', ...
     'p', 'c', 'N', 'dt', 'tau', 'u_max', ...
     'm1', 'm2', 'k1', 'k2', ...
     'rho1', 'rho2', 'rho3', 'rho4', 'rho5', ...
     'x_bounds', 'n_x', 'n_u', 'n_z');

fprintf('\n模型数据已保存至 prediction_model.mat\n');
