function w = bumpProfile(t, v, h, Lb)
% t  : time [s]
% v  : vehicle speed [m/s]
% h  : bump height [m]
% Lb : bump length [m]

s = v .* t;

w = zeros(size(t));
idx = (s >= 0) & (s <= Lb);

w(idx) = 0.5 * h * (1 - cos(2*pi*s(idx)/Lb));
end

%%考虑前后轴延迟
w_front = bumpProfile(t, v, h, Lb);
w_rear  = bumpProfile(t - wheelbase/v, v, h, Lb);

%%假设左右轮同步
w_FL = w_front;
w_FR = w_front;
w_RL = w_rear;
w_RR = w_rear;