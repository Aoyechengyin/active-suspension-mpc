%% 生成四轮路面输入
function road = generateFourWheelBump(t, v, h, Lb, wheelbase)
% road.FL, road.FR, road.RL, road.RR 单位均为 m

t_delay = wheelbase / v;

road.FL = bumpProfile(t,           v, h, Lb);
road.FR = bumpProfile(t,           v, h, Lb);
road.RL = bumpProfile(t - t_delay, v, h, Lb);
road.RR = bumpProfile(t - t_delay, v, h, Lb);

end