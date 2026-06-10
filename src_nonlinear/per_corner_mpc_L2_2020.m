function u_cmd = per_corner_mpc_L2_2020(acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev, pitch_deg)
%PER_CORNER_MPC_L2_2020 Left-rear nonlinear region-scheduled e-MPC.
u_cmd = per_corner_mpc_nonlinear_step_2020(3, 2, -1, 1.77, ...
    acc_body, vel_body, susp_defl, susp_vel, road_now, w1_ahead, w2_ahead, u_prev, pitch_deg);
end
