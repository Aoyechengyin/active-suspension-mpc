function [u_act, alpha] = road3_actuator50_step_2020(u_cmd, u_prev_act, dt_s, tau_s)
%ROAD3_ACTUATOR50_STEP_2020 Discrete first-order actuator used for Road-3.
%
% The default parameters match the paper-reproduction actuator:
%   dt = 0.001 s, tau = 0.05 s.

if nargin < 3 || isempty(dt_s)
    dt_s = 0.001;
end
if nargin < 4 || isempty(tau_s)
    tau_s = 0.05;
end

u_cmd = double(u_cmd(1));
u_prev_act = double(u_prev_act(1));
dt_s = double(dt_s(1));
tau_s = double(tau_s(1));

if ~isfinite(u_prev_act)
    u_prev_act = 0;
end
if ~isfinite(dt_s) || dt_s <= 0
    error('dt_s must be positive and finite.');
end
if ~isfinite(tau_s) || tau_s <= 0
    error('tau_s must be positive and finite.');
end

alpha = exp(-dt_s / tau_s);
u_act = alpha * u_prev_act + (1 - alpha) * u_cmd;
end
