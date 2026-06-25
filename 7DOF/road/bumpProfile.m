%%半余弦减速带
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