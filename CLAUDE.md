# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Regionless Explicit MPC 主动悬架控制器，含路面预瞄。基于 Theunissen et al. (IEEE TIE, 2020) 和 Borrelli et al. (Automatica, 2010)。

核心思路：离线枚举所有最优活跃集 → 在线遍历活跃集检查 KKT 条件 → 找到最优控制律。与传统显式 MPC（多参数规划划分区域）不同，此方法无需存储参数空间分区，直接在线匹配活跃集。

## 当前优先级

**src_2020 是目前最重要的库。** 正在对 CarSim 2020 联合仿真的 eMPC 做最后调优，目标是在 Road-3 凸块工况下实现 active 模式性能超越 Passive。详见 `日志/` 目录下的实验记录。

## 运行方式

**MATLAB 必需工具箱**: Optimization Toolbox (quadprog, linprog), Signal Processing Toolbox (pwelch), Control System Toolbox (ss, c2d). 可选: Gurobi (Step3 自动检测, 比 quadprog 更快更准).

### src_2020 流水线（当前主要使用）

```matlab
addpath('src_2020');
self_check_2020;                     % 结构完整性自检
Step1_BuildPredictionModel_2020;     % → prediction_model_front/rear.mat
Step2_BuildMPCmatrices_2020;         % → mpc_qp_data_front/rear.mat
Step3_RegionlessSolver_2020;         % → regionless_mpc_data_front/rear[_full].mat
Step4_CheckSimulink_2020(true);      % 更新 untitled_2020.slx
```

### src/ 流水线（早期单轴原型）

```matlab
startup;                             % 初始化路径
Step1_BuildPredictionModel;          % → prediction_model.mat
Step2_BuildMPCmatrices;              % → mpc_qp_data.mat
Step3_RegionlessSolver;              % → regionless_mpc_data[_full].mat
Step4_SetupSimulink;                 % 闭环仿真验证
Step5_AnalyzeResults;                % 频域分析
```

每步 clear workspace，通过 .mat 文件传递数据。Step1-3 为离线阶段，Step4-5 为在线仿真验证。

## 架构

### src/ vs src_2020/

- `src/` — 早期单轴原型（dt=0.001s, p=80, c=10, N=20, 单一 quarter-car 模型）
- `src_2020/` — **当前主力**（前/后轴独立建模, CarSim 2020 联合仿真, 四角独立控制器, 含校准系统和实验分析工具链）

### src_2020 数据流

```
config_2020.m (中央参数: 车辆/MPC/权重/阻尼/CarSim Export 顺序)
    │
    ▼
Step1: 前/后轴独立建模 (26维增广 = 5 QC + 21 路面预瞄)
    │  前轴: k1=146kN/m, 后轴: k1=46kN/m, c1≈7949 N·s/m (减震器曲线拟合)
    │
    ▼
Step2: QP 矩阵 H, F, P, M1, M2 (前/后各一套)
    │
    ▼
Step3: 采样 8000 状态点 → 枚举活跃集 → 验证误差 < 1e-3
    │  求解器: Gurobi 优先 (Q=0.5*H), 退回 quadprog
    │
    ▼
8个 .mat 文件 → per_corner_mpc_*_2020.m (Simulink 四角控制器)
    │
    ▼
CarSim 仿真 → CSV → 分析工具链
```

### 状态空间 (26维增广)

x = [x1; dx1; x1-x2; dx1-dx2; u_a; w0; w1; ...; w20]
- QC 状态：簧上位移、簧上速度、悬架变形、悬架速度、执行器力
- 路面状态：w0=当前路面，w1~w20=未来 1~20ms 路面（移位寄存器）

### 核心算法 (regionless_mpc_eval)

实现 Borrelli et al. Algorithm 5：
1. 计算无约束解 U_base = -H⁻¹F'x
2. 检查空活跃集可行性
3. 遍历候选活跃集：对偶可行性 → 候选解 → 原始可行性
4. 返回第一个满足 KKT 条件的解（脚本版返回目标函数最小的解）

### per_corner_mpc_*_2020.m（CarSim 集成入口）

四角独立控制器，每个 wrapper 持有 persistent 状态：
- 输入：加速度、速度、悬架变形/速度、路面高程(当前+10ms+20ms)、上一控制力、俯仰角
- 信号滤波：acc 20Hz LP, sv 30Hz LP, vel 0.1Hz 泄漏积分
- 俯仰补偿：vel_corner = vel_cg ± pitch_arm × pitch_rate
- 路面插值：w0→w10→w20 分段线性填充 21 维
- 软启动：前 500 步线性渐变
- 退化保护：连续 500 步无解 → 输出 0

### 校准系统 (empc_calibration_settings_2020.m)

控制模式开关，决定四角是否启用和力限制：

| 模式 | 前轴 | 后轴 | 用途 |
|------|------|------|------|
| PASSIVE_ZERO | 禁用 | 禁用 | 被动基线 |
| B1_FRONT_ONLY | 9000N | 禁用 | 前轴隔离测试 |
| B2_REAR_LOW | 禁用 | 1000N | 后轴隔离测试 |
| B3_CONSERVATIVE | 3000N | 2000N | 平路/道路基线 |
| ROAD3_BUMP_SAFE | 1000N | 650N | **当前默认**，Road-3 凸块安全模式 |

ROAD3_BUMP_SAFE 额外包含后处理：硬限幅 + 一阶平滑 (tau=15~20ms) + 斜率限制 (9~15 kN/s)。

### rho5 调优系统 (road3_rho5_offline/)

离线训练不同 rho5 组合的 MPC 数据：

| Profile | 前轴 rho5 | 后轴 rho5 | 状态 |
|---------|----------|----------|------|
| B3_CONSERVATIVE_BASELINE | 1e-7 | 1e-4 | 基线 |
| ROAD3_SOFT_F1E5_R1E4 | 1e-5 | 1e-4 | **当前激活** |
| ROAD3_SOFT_F1E4_R3E4 | 1e-4 | 3e-4 | 已训练, 未激活 |

工具链：`TrainRoad3Rho5Offline_2020` → `ActivateRoad3Rho5Profile_2020` → `RestoreRoad3Rho5Backup_2020`。激活时自动备份旧 .mat。

### 实验分析工具链

分阶段验证，从简单到复杂：

| 阶段 | 工具 | 用途 |
|------|------|------|
| 平路 | `AnalyzeFlatPose_2020` | 姿态基线, 力饱和, 轮旋转 |
| Road-1/2 | `AnalyzeRoadAcceptance_2020` | 快速 pass/fail |
| Road-1/2 | `AnalyzeRoadExperiment_2020` | 详细诊断 (预瞄延迟, 频谱, 力差) |
| Road-3 | `AnalyzeRoad3BumpExperiment_2020` | 凸块事件窗口, 频段 RMS, 饱和比例 |

验收标准（Road-3 T2 pilot gate）：FsExt 饱和 <1%, Az_SM 不劣于 Passive, FJSt/FRSt=0N。

## 关键参数

| 参数 | src/ | src_2020/ | 说明 |
|------|------|-----------|------|
| dt | 0.001s | 0.001s | 采样周期 |
| p | 80 | 80 | 预测时域 = 80ms |
| c | 10 | 10 | 控制时域 = 10ms |
| N | 20 | 20 | 预瞄点数 = 20ms |
| u_max | 9000N | 9000N | 执行器力约束 |
| tau | 0.05s | 0.05s | 执行器时间常数 |
| rho5_front | 1e-7 | 1e-7 (基线) / 1e-5 (当前) | 控制力权重 |
| rho5_rear | 1e-7 | 1e-4 | 后轴控制力权重 |

## 已知问题与调参经验

- **rho5 必须很小**（1e-7~1e-5），否则优化器最小化控制力而非改善舒适性。经验法则：rho × expected_value² 各项应在同一数量级。
- **单纯增大 rho5 不能解决 Road-3 饱和问题**。rho5=1e-4/3e-4 虽然降低了左右力差，但 Az_SM 反而恶化。当前转向输出后处理策略 (ROAD3_BUMP_SAFE)。
- **Gurobi 二次项缩放**：必须用 `Q=0.5*H`（不是 `Q=H`），否则与 quadprog 不一致。
- **Gurobi 变量下界**：必须设 `model.lb = -inf`，默认下界为 0 会导致控制力错误。
- **活跃集识别阈值**：用 `1e-4`（不是 `1e-5`），过紧会漏掉边界约束。
- **persistent 变量**：切换校准模式或 rho5 profile 后必须 `clear per_corner_mpc_*_2020`。
- **CarSim Import 顺序**：当前为 `[IMP_FS_L1, IMP_FS_L2, IMP_FS_R1, IMP_FS_R2]`，Simulink Mux 必须对齐。
- **CarSim S-Function 更新**：Step4 更新模型时临时注释 CarSim S-Function 块，避免 solver DLL 报错。

## 代码规范

- 注释用中文，变量名用英文
- 函数命名: snake_case（如 regionless_mpc_eval）
- 脚本命名: StepN_Description（如 Step1_BuildPredictionModel.m）
- src_2020 函数统一加 `_2020` 后缀

## .mat 数据文件

`.gitignore` 排除 .mat（除 src_2020/ 外）。src_2020 根目录 8 个 .mat 文件是 Simulink/CarSim 联仿的运行时资产，由 Step1-3 生成或由 rho5 离线训练工具管理。

## 实验数据与结果 (Output/)

CarSim 仿真输出的 CSV 和分析报告存放于此，按实验阶段组织：

```
Output/
  平直零力/          — 零外力平路基线
  平直_MPC/          — 平路 MPC 基线
  CaseB1/            — 仅前轴 MPC (9000N), 后轴零力
  CaseB2/            — 仅后轴 MPC (1000N), 前轴零力
  CaseB2-rev/        — 后轴反向力测试
  CaseB3/            — 前 3000N + 后 2000N conservative
  CaseB4/            — **当前冻结基线** (rho5_rear=1e-4 重训练后)
  Road-1/            — 预瞄验证 (小幅路面, 1-2mm)
  Road-2A/           — 单凸包 5mm
  Road-2B/           — 单凸包 10mm
  Road-3/            — **论文凸块工况** (当前焦点)
    T2_passive/          — 被动基线
    T2_no_preview/       — eMPC 无预瞄
    T2_pilot_preview/    — eMPC 预瞄 B3 baseline
    rho5_front_new/      — rho5 前轴 1e-5 测试
    rho5_front1e-4_rear_3e-4/ — rho5 前 1e-4 后 3e-4 (失败)
    bump_safe/           — bump-safe 1200/800N (改善但未超 Passive)
    bump_safe_tight/     — bump-safe 1000/650N (最新, 仍在评估)
```

每个 CSV 约 15000 行 (15s × 1000Hz)，包含 141 列诊断变量。分析报告为 `.md` 文件，由对应的 `Analyze*_2020` 工具生成。

**Road-3 当前结论** (截至 2026-06-07)：bump-safe tight (1000/650N) 方向有效，Az_SM 从 B3 preview 的 1.51 降到 1.33，但仍高于 Passive 的 1.11。不再继续降力限，保持当前参数等待下一轮验证。

## CarSim 参数集 (Carsim参数集/)

CarSim 2020 联合仿真所需的路面、导入/导出配置：

```
Carsim参数集/
  3D路况文件/          — CarSim 3D Road CSV (Station, elevation)
    Road1_*.csv            — 预瞄验证路面 (小幅, 1-2mm)
    Road2_*.csv            — 单凸包路面 (5mm/10mm)
    Road3_T1_*.csv         — Road-3 短凸块 (50mm/10mm pilot)
    Road3_T2_*.csv         — Road-3 长凸块 (150mm full / 50mm pilot)
    RdRefZ_*.par           — CarSim 路面参考文件
  VSCommand/           — CarSim VS Command 表达式
    Road3_preview_exports_2020.txt   — 预瞄: W1=W(z+v*0.01), W2=W(z+v*0.02)
    Road3_no_preview_exports_2020.txt — 无预瞄: W1=W2=当前轮下路面
  输入/                — CarSim 输入变量说明 (Run_imp.xlsx)
  输出/                — CarSim 输出变量说明 (Run_out.xlsx)
```

**CarSim Export 24 路顺序** (config_2020.m `export_order`):
```
W1_L1,W1_R1,W1_L2,W1_R2, W2_L1,W2_R1,W2_L2,W2_R2,
Az_SM,Vz_SM, Jnc_L1~R2, JncR_L1~R2, Zgnd_L1~R2, Vx,Pitch
```

**CarSim Import 4 路顺序**: `[IMP_FS_L1, IMP_FS_L2, IMP_FS_R1, IMP_FS_R2]`

## 外部依赖

- `tbxmanager/` — 第三方工具箱管理器（SeDuMi, MPT3 等），通过 `tbxmanager restorepath` 恢复路径，不在 git 中
- `papers/` — 参考文献 PDF，不在 git 中
- CarSim 2020 — 车辆动力学仿真，通过 S-Function 与 Simulink 联合仿真
- Gurobi（可选）— QP 求解器，路径在 `config_2020.m` 中配置
