function [enabled, u_limit, output_scale] = empc_calibration_settings_2020(corner, mode)
%EMPC_CALIBRATION_SETTINGS_2020 Central switches for flat-road eMPC calibration.
%
% Edit default_mode below before running a new Simulink/CarSim calibration case.
% Supported modes:
%   FULL_CURRENT     - Four corners enabled, 9000 N limits.
%   B1_FRONT_ONLY   - Front eMPC enabled, rear zero force.
%   B2_REAR_LOW     - Rear eMPC enabled at 1000 N, front zero force.
%   B2_REAR_LOW_REV - Same as B2, but reverses rear controller output sign.
%   B3_CONSERVATIVE - Front 3000 N, rear 2000 N.

if nargin < 2
    default_mode = 'B3_CONSERVATIVE';
    mode = default_mode;
end

corner = char(corner);
mode = upper(char(mode));

is_front = numel(corner) >= 2 && corner(2) == '1';
enabled = true;
output_scale = 1;

switch mode
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
end
