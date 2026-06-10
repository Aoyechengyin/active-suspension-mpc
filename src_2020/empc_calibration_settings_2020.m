function [enabled, u_limit, output_scale, post_settings] = empc_calibration_settings_2020(corner, mode)
%EMPC_CALIBRATION_SETTINGS_2020 Central switches for flat-road eMPC calibration.
%
% Edit default_mode below before running a new Simulink/CarSim calibration case.
% Supported modes:
%   FULL_CURRENT     - Four corners enabled, 9000 N limits.
%   B1_FRONT_ONLY   - Front eMPC enabled, rear zero force.
%   B2_REAR_LOW     - Rear eMPC enabled at 1000 N, front zero force.
%   B2_REAR_LOW_REV - Same as B2, but reverses rear controller output sign.
%   B3_CONSERVATIVE - Front 3000 N, rear 2000 N.
%   ROAD3_BUMP_SAFE - Road-3 T2 pilot guard: lower force and slew limits.
%   ROAD3_T2_FRONT_ONLY_TIGHT - T2 pilot diagnostic, front only at 1000 N.
%   ROAD3_T2_REAR_ONLY_TIGHT  - T2 pilot diagnostic, rear only at 650 N.
%   ROAD3_T2_BOTH_TIGHT       - T2 pilot diagnostic, both axles tight.
%   ROAD3_T2_COMFORT_GATE_UV_POS - T2 pilot both-tight with positive u*v gate.
%   ROAD3_T2_COMFORT_GATE_UV_NEG - T2 pilot both-tight with negative u*v gate.
%   ROAD3_PAPER_ACTIVE_BEST   - Frozen paper active setup: Q_C data + UV_POS.
%   PASSIVE_ZERO    - Four corners disabled, zero external force.

if nargin < 2
    default_mode = 'ROAD3_PAPER_ACTIVE_BEST';
    mode = default_mode;                                                                      
end

corner = char(corner);
mode = upper(char(mode));

is_front = numel(corner) >= 2 && corner(2) == '1';
enabled = true;
output_scale = 1;

switch mode
    case 'PASSIVE_ZERO'
        front_limit = 0;
        rear_limit = 0;
        front_enabled = false;
        rear_enabled = false;
    case 'FULL_CURRENT'
        front_limit = 9000;
        rear_limit = 9000;
        front_enabled = true;
        rear_enabled = true;
    case 'B1_FRONT_ONLY'
        front_limit = 9000;
        rear_limit = 0;
        front_enabled = true;
        rear_enabled = false;
    case 'B2_REAR_LOW'
        front_limit = 0;
        rear_limit = 1000;
        front_enabled = false;
        rear_enabled = true;
    case 'B2_REAR_LOW_REV'
        front_limit = 0;
        rear_limit = 1000;
        front_enabled = false;
        rear_enabled = true;
        if ~is_front
            output_scale = -1;
        end
    case 'B3_CONSERVATIVE'
        front_limit = 3000;
        rear_limit = 2000;
        front_enabled = true;
        rear_enabled = true;
    case 'ROAD3_BUMP_SAFE'
        front_limit = 1000;
        rear_limit = 650;
        front_enabled = true;
        rear_enabled = true;
    case 'ROAD3_T2_FRONT_ONLY_TIGHT'
        front_limit = 1000;
        rear_limit = 0;
        front_enabled = true;
        rear_enabled = false;
    case 'ROAD3_T2_REAR_ONLY_TIGHT'
        front_limit = 0;
        rear_limit = 650;
        front_enabled = false;
        rear_enabled = true;
    case {'ROAD3_T2_BOTH_TIGHT', 'ROAD3_T2_COMFORT_GATE_UV_POS', 'ROAD3_T2_COMFORT_GATE_UV_NEG', 'ROAD3_PAPER_ACTIVE_BEST'}
        front_limit = 1000;
        rear_limit = 650;
        front_enabled = true;
        rear_enabled = true;
    otherwise
        error('Unsupported eMPC calibration mode: %s', mode);
end

if is_front
    enabled = front_enabled;
    u_limit = front_limit;
else
    enabled = rear_enabled;
    u_limit = rear_limit;
end

enabled = logical(enabled);
u_limit = double(u_limit);
output_scale = double(output_scale);
post_settings = local_post_settings(mode, u_limit, is_front, enabled);
end

function post = local_post_settings(mode, u_limit, is_front, enabled)
post = struct();
post.enabled = local_is_tight_mode(mode) && enabled && u_limit > 0;
post.limit_N = double(u_limit);
post.rate_limit_N_per_s = 1e12;
post.smooth_tau_s = 0.0;
post.energy_gate_mode = local_energy_gate_mode(mode);

if post.enabled
    if is_front
        post.rate_limit_N_per_s = 15000;
        post.smooth_tau_s = 0.015;
    else
        post.rate_limit_N_per_s = 9000;
        post.smooth_tau_s = 0.020;
    end
end
end

function tf = local_is_tight_mode(mode)
tf = strcmp(mode, 'ROAD3_BUMP_SAFE') || ...
    strcmp(mode, 'ROAD3_T2_FRONT_ONLY_TIGHT') || ...
    strcmp(mode, 'ROAD3_T2_REAR_ONLY_TIGHT') || ...
    strcmp(mode, 'ROAD3_T2_BOTH_TIGHT') || ...
    strcmp(mode, 'ROAD3_T2_COMFORT_GATE_UV_POS') || ...
    strcmp(mode, 'ROAD3_T2_COMFORT_GATE_UV_NEG') || ...
    strcmp(mode, 'ROAD3_PAPER_ACTIVE_BEST');
end

function gate = local_energy_gate_mode(mode)
if strcmp(mode, 'ROAD3_T2_COMFORT_GATE_UV_POS') || strcmp(mode, 'ROAD3_PAPER_ACTIVE_BEST')
    gate = 1;
elseif strcmp(mode, 'ROAD3_T2_COMFORT_GATE_UV_NEG')
    gate = -1;
else
    gate = 0;
end
end
