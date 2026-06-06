function [u_l2_out, u_r2_out] = rear_diff_limiter_2020(u_l2, u_r2, half_diff_limit)
%REAR_DIFF_LIMITER_2020 Stateless rear-axle differential force limiter.
%
% Limits abs((u_l2 - u_r2) / 2) while preserving the rear common-mode force.

u_l2 = double(u_l2(1));
u_r2 = double(u_r2(1));
half_diff_limit = abs(double(half_diff_limit(1)));

u_common = 0.5 * (u_l2 + u_r2);
u_half_diff = 0.5 * (u_l2 - u_r2);

if u_half_diff > half_diff_limit
    u_half_diff = half_diff_limit;
elseif u_half_diff < -half_diff_limit
    u_half_diff = -half_diff_limit;
end

u_l2_out = u_common + u_half_diff;
u_r2_out = u_common - u_half_diff;
end
