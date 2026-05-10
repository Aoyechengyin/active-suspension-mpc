function [road_profile, y_r_preview, t] = road_profile_generator(vx, dt, t_end, profile_type, varargin)
%ROAD_PROFILE_GENERATOR 生成路面轮廓和预瞄信号
%
%   [road, y_r, t] = road_profile_generator(vx, dt, t_end, type)
%
%   输入:
%     vx           - 车速 (m/s)
%     dt           - 采样时间 (s)
%     t_end        - 仿真时长 (s)
%     profile_type - 'random' | 'speedbump_short' | 'speedbump_long' | 'sine'
%     varargin     - 额外参数 (取决于 profile_type)
%
%   输出:
%     road_profile - 当前车轮处路面高程 (N x 1), 单位 m
%     y_r_preview  - 预瞄传感器信号 w_{N+1} (N x 1), 单位 m
%     t            - 时间向量 (N x 1)
%
%   预瞄距离 = (N+1) * dt * vx  (基于论文: N=2, 3步预瞄)
%
%   参考:
%     Theunissen et al., IEEE TIE, 2020, Section V

t = (0:dt:t_end)';
n_samples = length(t);

switch lower(profile_type)
    case 'random'
        % ISO 8608 C-D 级随机路面
        road_profile = generate_iso_road(t, vx, varargin{:});

    case 'speedbump_short'
        % 论文 Test 1: 短波长凸块, 高5cm, 长0.4m, ~30km/h
        bump_pos = 10;     % 凸块位置 (m)
        bump_len = 0.4;    % 凸块长度 (m)
        bump_height = 0.05; % 凸块高度 (m)
        if ~isempty(varargin)
            bump_pos = varargin{1};
        end
        road_profile = generate_bump(t, vx, bump_pos, bump_len, bump_height, 'halfsine');

    case 'speedbump_long'
        % 论文 Test 2: 长波长凸块, 高15cm, 长2.5m, ~50km/h
        bump_pos = 15;
        bump_len = 2.5;
        bump_height = 0.15;
        if ~isempty(varargin)
            bump_pos = varargin{1};
        end
        road_profile = generate_bump(t, vx, bump_pos, bump_len, bump_height, 'halfsine');

    case 'sine'
        % 正弦波路面 (频率扫描测试)
        freq = 1.5;  % Hz
        amp = 0.05;  % m
        if ~isempty(varargin)
            freq = varargin{1};
        end
        road_profile = amp * sin(2 * pi * freq * t);

    otherwise
        error('Unknown profile type: %s', profile_type);
end

% 生成预瞄信号: y_r(k) = w_N(k+1) = road(k + N + 1)
% N=2 表示3步预瞄 (w0当前, w1, w2)
preview_steps = 3;  % N+1 = 3
y_r_preview = [road_profile(preview_steps+1:end); zeros(preview_steps, 1)];

end

%% 辅助函数: ISO 8608 随机路面
function road = generate_iso_road(t, vx, road_class)
% 使用成形滤波器生成 ISO 8608 随机路面
% 默认 C-D 级: G_d(n0) = 256e-6 m^3 (at n0 = 0.1 cycle/m)

if nargin < 3 || isempty(road_class)
    % ISO C-D 级: G_d(n0) = 256e-6 m^3
    G_d_n0 = 256e-6;
else
    switch lower(road_class)
        case 'c'
            G_d_n0 = 64e-6;
        case 'd'
            G_d_n0 = 256e-6;
        case 'e'
            G_d_n0 = 1024e-6;
        otherwise
            G_d_n0 = 256e-6;
    end
end

n0 = 0.1;       % 参考空间频率 (cycle/m)
w = 2;          % 波度指数 (标准路面)

% 空间频率向量
n_min = 0.01;   % min spatial freq
n_max = 10;     % max spatial freq
N_fft = 2^ceil(log2(length(t)));

% 生成频域白噪声
df = 1 / (N_fft * vx * (t(2) - t(1)));
f_spatial = (0:N_fft-1)' * df;

% PSD: G_d(n) = G_d(n0) * (n/n0)^{-w}
psd = zeros(N_fft, 1);
idx = f_spatial > 0 & f_spatial <= n_max;
psd(idx) = G_d_n0 * (f_spatial(idx) / n0).^(-w);

% IFFT 生成路面
phase = 2 * pi * rand(N_fft, 1);
Z = sqrt(psd * N_fft / (2*pi)) .* exp(1j * phase);
road_raw = real(ifft(Z));

% 插值到所需时间点
x = vx * t;
x_raw = (0:N_fft-1)' * vx * (t(2) - t(1));
road = interp1(x_raw, road_raw, x, 'linear', 'extrap');
road = road(:);

% 缩放到合理范围 (~±0.05m)
road = road / max(abs(road)) * 0.05;
end

%% 辅助函数: 凸块轮廓
function road = generate_bump(t, vx, bump_pos, bump_len, bump_height, shape)
% 生成单个凸块

x = vx * t;
bump_center = bump_pos + bump_len / 2;

switch lower(shape)
    case 'halfsine'
        % 半正弦凸块
        road = zeros(size(x));
        in_bump = abs(x - bump_center) < bump_len / 2;
        road(in_bump) = bump_height * sin(pi * (x(in_bump) - bump_pos) / bump_len);

    case 'trapezoid'
        % 梯形凸块
        ramp_len = bump_len * 0.2;
        road = zeros(size(x));
        for i = 1:length(x)
            if x(i) < bump_pos || x(i) > bump_pos + bump_len
                road(i) = 0;
            elseif x(i) < bump_pos + ramp_len
                road(i) = bump_height * (x(i) - bump_pos) / ramp_len;
            elseif x(i) > bump_pos + bump_len - ramp_len
                road(i) = bump_height * (bump_pos + bump_len - x(i)) / ramp_len;
            else
                road(i) = bump_height;
            end
        end

    otherwise
        error('Unknown bump shape: %s', shape);
end
end
