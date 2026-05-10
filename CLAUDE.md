# Regionless e-MPC for Active Suspension with Preview

MATLAB 实现，基于 Theunissen et al. (IEEE TIE, 2020) 和 Borrelli et al. (Automatica, 2010)。

## 技术栈
- MATLAB (核心算法 + 数据处理)
- Simulink (联合仿真)
- CarSim (车辆动力学模型, 计划中)

## 代码规范
- 注释用中文，变量名用英文
- 函数命名: snake_case (如 `regionless_mpc_eval`)
- 脚本命名: StepN_Description (如 `Step1_BuildPredictionModel.m`)

## 目录结构
```
src/          — 源代码 (.m)
  Step1_BuildPredictionModel.m   — 构建预测模型
  Step2_BuildMPCmatrices.m       — 构建 QP 矩阵
  Step3_RegionlessSolver.m       — 枚举活跃集 + 验证
  Step4_SetupSimulink.m          — Simulink 配置
  Step5_AnalyzeResults.m         — 结果分析
  regionless_mpc_eval.m          — 核心: 在线活跃集评估
  mpc_controller.m               — Simulink S-Function
  road_profile_generator.m       — 道路轮廓
  enumerate_active_sets_sampling.m — 采样法枚举活跃集
  diagnose_preview.m             — 预瞄诊断
data/         — .mat 数据文件
papers/       — 参考文献 PDF
results/      — 仿真输出图表
docs/         — 论文笔记
startup.m     — MATLAB 路径初始化 (addpath src/)
```

## 关键参数
- 控制周期: 10ms, 执行器时间常数: 50ms
- 预测时域 p=8, 控制时域 c=6, 预瞄点数 N=2
- 控制力约束: |u| < 9000N

## 权重调参经验 (来自 MEMORY.md)
- rho5 (控制力) 必须很小 (1e-7~1e-9)，否则优化器倾向于最小化控制力而非改善舒适性
- 经验法则: rho * expected_value^2 各项应在同一数量级
