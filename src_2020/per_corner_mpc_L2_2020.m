function u_cmd = per_corner_mpc_L2_2020(acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev, pitch_deg)
%PER_CORNER_MPC_L2_2020 Left-rear 1 ms regionless e-MPC controller.
[u_cmd] = local_per_corner_mpc_rear(acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev, pitch_deg);
end

function u_cmd = local_per_corner_mpc_rear(acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev, pitch_deg)
persistent inited x1 ua ramp_cnt no_sol_cnt acc_filt vel_filt sv_filt pitch_prev pitch_rate_filt
persistent A_buf Q_buf q_buf n_act n_sets max_active n_x c_dim iH iHF Hmat Fmat Pmat M1 M2 b_tol u_lim dt_val tau_val calib_enabled output_scale
if isempty(inited)
    s = coder.load('regionless_mpc_data_rear.mat');
    n_sets = double(s.n_sets); max_active = double(s.max_active); n_x = double(s.n_x); c_dim = double(s.c);
    A_buf = double(s.A_padded); Q_buf = double(s.Q_padded); q_buf = double(s.q_padded); n_act = double(s.n_active_arr);
    iH = double(s.invH); iHF = double(s.invH_Ft); Hmat = double(s.H); Fmat = double(s.F); Pmat = double(s.P); M1 = double(s.M1); M2 = double(s.M2);
    [calib_enabled, u_override, output_scale] = empc_calibration_settings_2020('L2');
    b_tol = 1e-6; u_lim = min(double(s.u_max), double(u_override)); dt_val = double(s.dt); tau_val = 0.05;
    x1 = 0; ua = 0; ramp_cnt = 0; no_sol_cnt = 0; acc_filt = 0; vel_filt = 0; sv_filt = 0; pitch_prev = 0; pitch_rate_filt = 0;
    inited = true;
end
u_prev_model = output_scale * u_prev;
[u_cmd, x1, ua, ramp_cnt, no_sol_cnt, acc_filt, vel_filt, sv_filt, pitch_prev, pitch_rate_filt] = ...
    per_corner_mpc_state_step_2020(acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev_model, pitch_deg, ...
    -1, 1.77, x1, ua, ramp_cnt, no_sol_cnt, acc_filt, vel_filt, sv_filt, pitch_prev, pitch_rate_filt, ...
    A_buf, Q_buf, q_buf, n_act, n_sets, max_active, n_x, c_dim, iH, iHF, Hmat, Fmat, Pmat, M1, M2, b_tol, u_lim, dt_val, tau_val);
if ~calib_enabled
    u_cmd = 0;
else
    u_cmd = output_scale * u_cmd;
end
end
