function test_road3_actuator50_2020()
%TEST_ROAD3_ACTUATOR50_2020 Unit checks for strict paper actuator modes.

root_dir = fileparts(mfilename('fullpath'));
addpath(root_dir);

[front_enabled, front_limit, ~, front_post] = empc_calibration_settings_2020('L1', 'ROAD3_NONLINEAR_FRONT500_ACT50_ONLY');
[rear_enabled, rear_limit, ~, rear_post] = empc_calibration_settings_2020('L2', 'ROAD3_NONLINEAR_FRONT500_ACT50_ONLY');
[~, ~, ~, pos_post] = empc_calibration_settings_2020('L1', 'ROAD3_NONLINEAR_FRONT500_ACT50_UV_POS');
[~, ~, ~, neg_post] = empc_calibration_settings_2020('L1', 'ROAD3_NONLINEAR_FRONT500_ACT50_UV_NEG');

assert(front_enabled && front_limit == 500 && front_post.enabled, ...
    'ACT50_ONLY must enable front 500 N control.');
assert(~rear_enabled && rear_limit == 0 && ~rear_post.enabled, ...
    'ACT50_ONLY must disable rear control.');
assert(front_post.smooth_tau_s == 0, ...
    'ACT50 modes must not apply software smoothing before the physical actuator.');
assert(front_post.rate_limit_N_per_s == 15000, ...
    'ACT50 front mode should keep the 15000 N/s safety rate limit.');
assert(pos_post.energy_gate_mode == 1, 'ACT50_UV_POS metadata changed.');
assert(neg_post.energy_gate_mode == -1, 'ACT50_UV_NEG metadata changed.');

u_act = 0;
response = zeros(50, 1);
for k = 1:50
    [u_act, alpha] = road3_actuator50_step_2020(1, u_act, 0.001, 0.05);
    response(k) = u_act;
end

assert(abs(alpha - exp(-0.001 / 0.05)) < 1e-14, 'ACT50 alpha changed unexpectedly.');
assert(abs(response(10) - (1 - exp(-0.010 / 0.05))) < 1e-12, '10 ms ACT50 response mismatch.');
assert(abs(response(20) - (1 - exp(-0.020 / 0.05))) < 1e-12, '20 ms ACT50 response mismatch.');
assert(abs(response(50) - (1 - exp(-0.050 / 0.05))) < 1e-12, '50 ms ACT50 response mismatch.');

fprintf('ACT50 step response: 10 ms %.1f%%, 20 ms %.1f%%, 50 ms %.1f%%\n', ...
    100 * response(10), 100 * response(20), 100 * response(50));
fprintf('test_road3_actuator50_2020 passed.\n');
end
