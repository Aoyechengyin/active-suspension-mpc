%% 生成前后轴预瞄路面序列
function preview = generatePreviewBump(t, v, h, Lb, Ts, wheelbase)
% N = 2，对应 w0, w1, w2

t_delay = wheelbase / v;

preview.front.w0 = bumpProfile(t,        v, h, Lb);
preview.front.w1 = bumpProfile(t + Ts,   v, h, Lb);
preview.front.w2 = bumpProfile(t + 2*Ts, v, h, Lb);

preview.rear.w0 = bumpProfile(t - t_delay,        v, h, Lb);
preview.rear.w1 = bumpProfile(t - t_delay + Ts,   v, h, Lb);
preview.rear.w2 = bumpProfile(t - t_delay + 2*Ts, v, h, Lb);

end