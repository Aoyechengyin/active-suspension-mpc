function u_cmd = per_corner_mpc_nonlinear_step_2020(corner_id, axle_id, pitch_sign, pitch_arm, ...
    acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev, pitch_deg)
%PER_CORNER_MPC_NONLINEAR_STEP_2020 Shared nonlinear region-scheduled MPC step.

persistent inited
persistent x1 ua ramp_cnt no_sol_cnt acc_filt vel_filt sv_filt pitch_prev pitch_rate_filt u_safe_prev region_idx
persistent f_reb_high f_reb_mid f_low f_comp_mid f_comp_high
persistent r_reb_high r_reb_mid r_low r_comp_mid r_comp_high

if isempty(inited)
    f_reb_high = coder.load('regionless_mpc_data_front_REB_HIGH.mat');
    f_reb_mid = coder.load('regionless_mpc_data_front_REB_MID.mat');
    f_low = coder.load('regionless_mpc_data_front_LOW.mat');
    f_comp_mid = coder.load('regionless_mpc_data_front_COMP_MID.mat');
    f_comp_high = coder.load('regionless_mpc_data_front_COMP_HIGH.mat');

    r_reb_high = coder.load('regionless_mpc_data_rear_REB_HIGH.mat');
    r_reb_mid = coder.load('regionless_mpc_data_rear_REB_MID.mat');
    r_low = coder.load('regionless_mpc_data_rear_LOW.mat');
    r_comp_mid = coder.load('regionless_mpc_data_rear_COMP_MID.mat');
    r_comp_high = coder.load('regionless_mpc_data_rear_COMP_HIGH.mat');

    x1 = zeros(4, 1);
    ua = zeros(4, 1);
    ramp_cnt = zeros(4, 1);
    no_sol_cnt = zeros(4, 1);
    acc_filt = zeros(4, 1);
    vel_filt = zeros(4, 1);
    sv_filt = zeros(4, 1);
    pitch_prev = zeros(4, 1);
    pitch_rate_filt = zeros(4, 1);
    u_safe_prev = zeros(4, 1);
    region_idx = 3 * ones(4, 1);
    inited = true;
end

cid = int32(corner_id);
region_idx(cid) = local_select_region(double(susp_vel(1)), region_idx(cid));
corner_name = local_corner_name(cid);

[calib_enabled, u_override, output_scale, post_settings] = empc_calibration_settings_2020(corner_name);
u_prev_model = output_scale * u_prev;

if axle_id == 1
    if region_idx(cid) == 1
        [u_raw, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid)] = ...
            local_eval_data(f_reb_high, acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev_model, pitch_deg, pitch_sign, pitch_arm, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid), u_override);
    elseif region_idx(cid) == 2
        [u_raw, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid)] = ...
            local_eval_data(f_reb_mid, acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev_model, pitch_deg, pitch_sign, pitch_arm, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid), u_override);
    elseif region_idx(cid) == 3
        [u_raw, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid)] = ...
            local_eval_data(f_low, acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev_model, pitch_deg, pitch_sign, pitch_arm, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid), u_override);
    elseif region_idx(cid) == 4
        [u_raw, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid)] = ...
            local_eval_data(f_comp_mid, acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev_model, pitch_deg, pitch_sign, pitch_arm, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid), u_override);
    else
        [u_raw, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid)] = ...
            local_eval_data(f_comp_high, acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev_model, pitch_deg, pitch_sign, pitch_arm, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid), u_override);
    end
else
    if region_idx(cid) == 1
        [u_raw, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid)] = ...
            local_eval_data(r_reb_high, acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev_model, pitch_deg, pitch_sign, pitch_arm, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid), u_override);
    elseif region_idx(cid) == 2
        [u_raw, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid)] = ...
            local_eval_data(r_reb_mid, acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev_model, pitch_deg, pitch_sign, pitch_arm, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid), u_override);
    elseif region_idx(cid) == 3
        [u_raw, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid)] = ...
            local_eval_data(r_low, acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev_model, pitch_deg, pitch_sign, pitch_arm, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid), u_override);
    elseif region_idx(cid) == 4
        [u_raw, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid)] = ...
            local_eval_data(r_comp_mid, acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev_model, pitch_deg, pitch_sign, pitch_arm, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid), u_override);
    else
        [u_raw, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid)] = ...
            local_eval_data(r_comp_high, acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev_model, pitch_deg, pitch_sign, pitch_arm, x1(cid), ua(cid), ramp_cnt(cid), no_sol_cnt(cid), acc_filt(cid), vel_filt(cid), sv_filt(cid), pitch_prev(cid), pitch_rate_filt(cid), u_override);
    end
end

if ~calib_enabled
    u_cmd = 0;
else
    u_cmd = output_scale * u_raw;
    [u_cmd, u_safe_prev(cid)] = road3_bump_safe_output_2020(u_cmd, u_safe_prev(cid), post_settings, 0.001, vel_body);
end
end

function [u_cmd, x1, ua, ramp_cnt, no_sol_cnt, acc_filt, vel_filt, sv_filt, pitch_prev, pitch_rate_filt] = ...
    local_eval_data(s, acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev_model, pitch_deg, ...
    pitch_sign, pitch_arm, x1, ua, ramp_cnt, no_sol_cnt, acc_filt, vel_filt, sv_filt, pitch_prev, pitch_rate_filt, u_override)

b_tol = 1e-6;
u_lim = min(double(s.u_max), double(u_override));
dt_val = double(s.dt);
tau_val = 0.05;

[u_cmd, x1, ua, ramp_cnt, no_sol_cnt, acc_filt, vel_filt, sv_filt, pitch_prev, pitch_rate_filt] = ...
    per_corner_mpc_state_step_2020(acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev_model, pitch_deg, ...
    pitch_sign, pitch_arm, x1, ua, ramp_cnt, no_sol_cnt, acc_filt, vel_filt, sv_filt, pitch_prev, pitch_rate_filt, ...
    double(s.A_padded), double(s.Q_padded), double(s.q_padded), double(s.n_active_arr), double(s.n_sets), ...
    double(s.max_active), double(s.n_x), double(s.c), double(s.invH), double(s.invH_Ft), double(s.H), double(s.F), ...
    double(s.P), double(s.M1), double(s.M2), b_tol, u_lim, dt_val, tau_val);
end

function idx = local_select_region(susp_vel, prev_idx)
h = 0.05;
prev_idx = double(prev_idx);
if prev_idx < 1 || prev_idx > 5 || ~isfinite(prev_idx)
    prev_idx = 3;
end

lower = [-inf, -0.72, -0.21, 0.20, 0.76];
upper = [-0.72, -0.21, 0.20, 0.76, inf];
if susp_vel >= lower(prev_idx) - h && susp_vel <= upper(prev_idx) + h
    idx = prev_idx;
    return;
end

if susp_vel <= -0.72
    idx = 1;
elseif susp_vel <= -0.21
    idx = 2;
elseif susp_vel <= 0.20
    idx = 3;
elseif susp_vel <= 0.76
    idx = 4;
else
    idx = 5;
end
end

function name = local_corner_name(corner_id)
if corner_id == 1
    name = 'L1';
elseif corner_id == 2
    name = 'R1';
elseif corner_id == 3
    name = 'L2';
else
    name = 'R2';
end
end
