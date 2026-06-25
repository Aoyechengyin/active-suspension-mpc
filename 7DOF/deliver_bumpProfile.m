w0 = bumpProfile(t,          v, h, Lb);
w1 = bumpProfile(t + Ts,     v, h, Lb);
w2 = bumpProfile(t + 2*Ts,   v, h, Lb);

%%后轴
t_delay = wheelbase / v;

w0_R = bumpProfile(t - t_delay,        v, h, Lb);
w1_R = bumpProfile(t - t_delay + Ts,   v, h, Lb);
w2_R = bumpProfile(t - t_delay + 2*Ts, v, h, Lb);