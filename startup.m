% startup.m — 项目路径初始化
% MATLAB 启动时自动执行，将 src/ 加入搜索路径
root_dir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(root_dir, 'src')));
addpath(root_dir);  % 确保 .mat 数据文件可被 Simulink 找到
tbxmanager restorepath
disp('[active-suspension-mpc] Path initialized.');
