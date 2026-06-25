function [isStable, metrics] = checkStability(time, suspDefl, t_front_hit, opts)
%CHECKSTABILITY Monte Carlo 稳定性验收
%
% 输入：
%   time        : N x 1 时间向量 [s]
%   suspDefl    : N x 4 悬架动挠度 [FL FR RL RR] [m]
%   t_front_hit : 前轴撞击减速带时刻 [s]
%   opts        : 可选参数结构体
%
% 输出：
%   isStable : 是否稳定
%   metrics  : 稳定性指标结构体

if nargin < 4 || isempty(opts)
    opts = struct();
end

if ~isfield(opts, 'settleTime')
    opts.settleTime = 3.0;
end

if ~isfield(opts, 'windowLength')
    opts.windowLength = 1.0;
end

if ~isfield(opts, 'deflTol')
    opts.deflTol = 0.005;    % 5 mm
end

time = time(:);

% 保证 suspDefl 为 N x 4
if size(suspDefl, 1) ~= numel(time) && size(suspDefl, 2) == numel(time)
    suspDefl = suspDefl.';
end

if size(suspDefl, 1) ~= numel(time) || size(suspDefl, 2) ~= 4
    error('suspDefl 必须为 N x 4，列顺序为 [FL FR RL RR]。');
end

t_check = t_front_hit + opts.settleTime;

[~, idx_check] = min(abs(time - t_check));
defl_check = suspDefl(idx_check, :);

idx_window = time >= t_check & time <= t_check + opts.windowLength;

if ~any(idx_window)
    isStable = false;
    metrics.reason = 'empty_check_window';
    metrics.t_check = t_check;
    metrics.defl_check = defl_check;
    metrics.max_abs_defl_check = max(abs(defl_check));
    metrics.max_abs_defl_window = NaN;
    return;
end

max_abs_defl_check = max(abs(defl_check));
max_abs_defl_window = max(abs(suspDefl(idx_window, :)), [], 'all');

stable_point = max_abs_defl_check <= opts.deflTol;
stable_window = max_abs_defl_window <= opts.deflTol;
stable_finite = all(isfinite(suspDefl(:)));

isStable = stable_point && stable_window && stable_finite;

metrics.t_check = t_check;
metrics.defl_check = defl_check;
metrics.max_abs_defl_check = max_abs_defl_check;
metrics.max_abs_defl_window = max_abs_defl_window;
metrics.stable_point = stable_point;
metrics.stable_window = stable_window;
metrics.stable_finite = stable_finite;
metrics.deflTol = opts.deflTol;

if isStable
    metrics.reason = 'pass';
elseif ~stable_finite
    metrics.reason = 'nonfinite_signal';
elseif ~stable_point
    metrics.reason = 'point_deflection_exceeded';
elseif ~stable_window
    metrics.reason = 'window_deflection_exceeded';
else
    metrics.reason = 'unknown';
end

end