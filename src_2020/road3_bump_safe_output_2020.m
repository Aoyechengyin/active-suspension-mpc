function [u_out, u_state] = road3_bump_safe_output_2020(u_raw, u_prev_safe, settings, dt_s, gate_velocity)
%ROAD3_BUMP_SAFE_OUTPUT_2020 Road-3-specific output guard for eMPC force.
%
% Optional gate_velocity is used only by ROAD3_T2_COMFORT_GATE_* modes.

u_target = double(u_raw(1));
u_prev = double(u_prev_safe(1));
dt = double(dt_s(1));
if nargin < 5
    gate_velocity = nan;
else
    gate_velocity = double(gate_velocity(1));
end

if ~isfinite(u_prev)
    u_prev = 0;
end

if ~settings.enabled
    u_out = u_target;
    u_state = u_out;
    return;
end

limit_N = abs(double(settings.limit_N));
if ~isfinite(limit_N) || limit_N < 0
    limit_N = 0;
end

u_target = local_clip(u_target, -limit_N, limit_N);
u_target = local_energy_gate(u_target, gate_velocity, settings.energy_gate_mode);

tau = double(settings.smooth_tau_s);
if isfinite(tau) && tau > 0 && isfinite(dt) && dt > 0
    alpha = exp(-dt / tau);
    u_candidate = alpha * u_prev + (1 - alpha) * u_target;
else
    u_candidate = u_target;
end

rate_limit = abs(double(settings.rate_limit_N_per_s));
if isfinite(rate_limit) && rate_limit > 0 && isfinite(dt) && dt > 0
    max_delta = rate_limit * dt;
    u_candidate = u_prev + local_clip(u_candidate - u_prev, -max_delta, max_delta);
end

u_out = local_clip(u_candidate, -limit_N, limit_N);
u_state = u_out;
end

function y = local_clip(x, lo, hi)
if x > hi
    y = hi;
elseif x < lo
    y = lo;
else
    y = x;
end
end

function u = local_energy_gate(u, gate_velocity, gate_mode)
gate_mode = double(gate_mode);
if gate_mode == 0 || ~isfinite(gate_velocity)
    return;
end

power_sign = u * gate_velocity;
if gate_mode > 0
    allowed = power_sign >= 0;
else
    allowed = power_sign <= 0;
end

if ~allowed
    u = 0;
end
end
