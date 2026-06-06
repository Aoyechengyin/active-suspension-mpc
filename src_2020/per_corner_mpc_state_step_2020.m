function [u_cmd, x1, ua, ramp_cnt, no_sol_cnt, acc_filt, vel_filt, sv_filt, pitch_prev, pitch_rate_filt] = ...
    per_corner_mpc_state_step_2020(acc_body, vel_body, susp_defl, susp_vel, ...
    road_now, w1_ahead, w2_ahead, u_prev, pitch_deg, pitch_sign, pitch_arm, ...
    x1, ua, ramp_cnt, no_sol_cnt, acc_filt, vel_filt, sv_filt, pitch_prev, pitch_rate_filt, ...
    A_buf, Q_buf, q_buf, n_act, n_sets, max_active, n_x, c_dim, ...
    iH, iHF, Hmat, Fmat, Pmat, M1, M2, b_tol, u_lim, dt_val, tau_val)
%PER_CORNER_MPC_STATE_STEP_2020 Stateless computation shared by four wrappers.

acc = double(acc_body(1));
vel_cg = double(vel_body(1));
sd = double(susp_defl(1));
sv = double(susp_vel(1));
rd = double(road_now(1));
w10 = double(w1_ahead(1));
w20 = double(w2_ahead(1));
up = double(u_prev(1));
pitch_rad = double(pitch_deg(1)) * pi / 180;

raw_pitch_rate = (pitch_rad - pitch_prev) / dt_val;
pitch_prev = pitch_rad;
alpha_pitch = exp(-2*pi*5*dt_val);
pitch_rate_filt = alpha_pitch * pitch_rate_filt + (1 - alpha_pitch) * raw_pitch_rate;
vel_corner = vel_cg + pitch_sign * pitch_arm * pitch_rate_filt;

alpha_acc = exp(-2*pi*20*dt_val);
acc_filt = alpha_acc * acc_filt + (1 - alpha_acc) * acc;

alpha_sv = exp(-2*pi*30*dt_val);
sv_filt = alpha_sv * sv_filt + (1 - alpha_sv) * sv;

alpha_vel = exp(-2*pi*0.1*dt_val);
vel_filt = alpha_vel * vel_filt + (1 - alpha_vel) * vel_corner;

alpha_comp = 0.98;
x1 = alpha_comp * (x1 + vel_filt * dt_val) + (1 - alpha_comp) * (sd + rd);

alpha_a = exp(-dt_val / tau_val);
ua = alpha_a * ua + (1 - alpha_a) * up;

x = zeros(n_x, 1);
x(1) = x1;
x(2) = vel_filt;
x(3) = sd;
x(4) = sv_filt;
x(5) = ua;
x(6:26) = local_fill_road_states(rd, w10, w20);

b = M1 + M2 * x;
U0 = -iHF * x;

u_cmd = 0;
found = false;
best_obj = inf;

if all(Pmat * U0 <= b + b_tol)
    u_cmd = U0(1);
    found = true;
    best_obj = local_objective(U0, Hmat, Fmat, x);
end

if ~found
    for ii = 1:n_sets
        ni = n_act(ii);
        if ni == 0
            continue;
        end

        lam = Q_buf(1:ni, 1:n_x, ii) * x + q_buf(1:ni, 1, ii);
        if any(lam < -b_tol)
            continue;
        end

        PAi = zeros(max_active, c_dim);
        idx = A_buf(1:ni, ii);
        for k = 1:ni
            r = int32(idx(k));
            PAi(k, 1:c_dim) = Pmat(r, 1:c_dim);
        end

        Uc = U0 - iH * (PAi(1:ni, 1:c_dim)' * lam);
        if all(Pmat * Uc <= b + b_tol)
            obj = local_objective(Uc, Hmat, Fmat, x);
            if obj < best_obj
                best_obj = obj;
                u_cmd = Uc(1);
                found = true;
            end
        end
    end
end

if ~found
    u_cmd = U0(1);
    no_sol_cnt = no_sol_cnt + 1;
    if no_sol_cnt > 500
        u_cmd = 0;
    end
else
    no_sol_cnt = 0;
end

if u_cmd > u_lim
    u_cmd = u_lim;
elseif u_cmd < -u_lim
    u_cmd = -u_lim;
end

ramp_cnt = ramp_cnt + 1;
if ramp_cnt <= 500
    u_cmd = u_cmd * (ramp_cnt / 500);
end
end

function road_vec = local_fill_road_states(w0, w10, w20)
road_vec = zeros(21, 1);
for i = 0:10
    road_vec(i + 1) = w0 + (double(i) / 10) * (w10 - w0);
end
for i = 1:10
    road_vec(11 + i) = w10 + (double(i) / 10) * (w20 - w10);
end
end

function obj = local_objective(U, H, F, x)
obj = 0.5 * (U' * H * U) + x' * F * U;
end
