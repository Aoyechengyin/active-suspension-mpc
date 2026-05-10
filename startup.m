% startup.m — 项目路径初始化
% MATLAB 启动时自动执行，将 src/ 加入搜索路径
addpath(genpath(fullfile(pwd, 'src')));
disp('[active-suspension-mpc] Path initialized.');
