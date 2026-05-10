# Regionless e-MPC 项目方向延伸

基于 2024–2026 年最新论文，整理可延伸的研究方向。

---

## 当前基线

- Theunissen et al., "Regionless Explicit Model Predictive Control of Active Suspension Systems With Preview", *IEEE TIE*, 2020
- 1/4 车模型，p=8, c=6, N=2，控制力约束 |u|<9000N
- 预瞄假设完美测量

---

## 方向 1: 预瞄鲁棒性（最直接）

**论文**: Ming Bai, Weichao Sun, "Disturbance-Resilient Model Predictive Control for Active Suspension Systems with Perception Errors in Road Preview Information", *Journal of the Franklin Institute*, 2025

**核心问题**: LiDAR/相机预瞄产生错误道路数据时（噪声、碎片、环境扰动），标准 MPC 出现病态行为（不稳定、约束违反）。

**方法**: DR-MPC，修改终端代价函数并约束感知误差，证明稳定性和递归可行性。

**套用到本项目的思路**:
- 当前 `road_profile_generator.m` 生成完美道路轮廓
- 注入感知噪声模型（高斯噪声、量化误差、缺失帧）
- 对比标准 regionless e-MPC vs 鲁棒变体
- 核心改动：QP 目标函数中增加感知误差惩罚项

**难度**: ★★★☆☆（改动量中等，理论坚实）

---

## 方向 2: 速度自适应显式 MPC

**论文**: Q. Li, Z. Chen 等 (吉林大学), "Model Predictive Control for Speed-Dependent Active Suspension System with Road Preview Information", *Sensors*, 24(7), 2255, 2024

**核心问题**: 当前 MPC 参数 p, c, dt 固定，但车辆速度变化时，预瞄距离和时间常数都变了。

**方法**: 
- 离线 mp-LP 计算多组显式控制律（不同速度档位）
- 在线通过 lookup table 查表
- Padé 近似处理速度相关轮间时延
- 自适应卡尔曼滤波处理传感器噪声

**套用到本项目的思路**:
- `regionless_mpc_eval.m` 中的活跃集枚举随速度变化
- 按速度分段预计算多个活跃集列表
- 在线根据速度切换

**难度**: ★★★★☆（需要重新推导模型）

---

## 方向 3: 多维度扩展 — 全车 7-DOF

**论文**: "An MPC Strategy for Anti-Pitch/Roll in Electric Vehicle Active Suspension Systems With Wheelbase Preview Information on Uneven Roads", *IEEE Access*, 2025

**核心问题**: 1/4 车模型只考虑垂向振动，实际车辆有俯仰（pitch）和侧倾（roll）。

**方法**:
- 7-DOF 整车模型
- 轴距预瞄信息作为增广状态
- 目标函数同时抑制垂向、俯仰、侧倾
- CarSim/MATLAB + HIL 验证

**套用到本项目的思路**:
- 从 1/4 车模型（2-DOF）升级到全车模型
- 状态向量从 ~5 维扩展到 ~20+ 维
- 活跃集数量指数增长 → 需要更高效的枚举策略
- CarSim 联合仿真已计划中

**难度**: ★★★★★（模型复杂度大幅增加）

---

## 方向 4: 纵向+垂向联合优化

**论文**: Z.Y. Liu, Y. Si, W. Sun (哈工大), "Ride Comfort Oriented Integrated Design of Preview Active Suspension Control and Longitudinal Velocity Planning", *Mechanical Systems and Signal Processing*, Vol. 208, 2024

**核心问题**: 舒适性不仅是垂向振动，减速/加速引起的纵向加速度也很关键。

**方法**:
- 上层：动态规划 + QP 做速度规划（给定路线高度图）
- 下层：Semi-EMPC 做悬架控制
- 联合优化：速度规划时考虑悬架约束，悬架控制时利用速度信息

**套用到本项目的思路**:
- 这是**自动驾驶规划 + 悬架控制**的交叉
- 适合智能车辆研究方向
- CarSim 可同时仿真纵向动力学和悬架

**难度**: ★★★★★（跨域联合优化，计算量大）

---

## 方向 5: 实车传感器融合 — LiDAR 预瞄

**论文**: F. Dong 等, "The Model Predictive Control of Dual-Chamber Active Air Suspension Based on Road Preview", *SAE WCX 2025*, Paper 2025-01-8789

**核心问题**: 道路轮廓不是已知的——需要从传感器实时获取。

**方法**:
- LiDAR 点云处理（分割、滤波、配准）
- 提取路面粗糙度作为预瞄信息
- MPC 主动调节双腔空气弹簧的非线性刚度/阻尼

**套用到本项目的思路**:
- 适合转向"感知方向"的研究
- 道路轮廓从 `road_profile_generator.m` 生成 → 变为 LiDAR 实时获取
- 增加了计算机视觉/点云处理的技术栈

**难度**: ★★★★☆（跨域，需要感知+控制）

---

## 优先级建议

| 方向 | 难度 | 与当前项目衔接 | 推荐时机 |
|------|------|---------------|---------|
| 预瞄鲁棒性 | ★★★ | 最好衔接 | 近期可做 |
| 速度自适应 | ★★★★ | 较好衔接 | 中期 |
| 7-DOF 全车 | ★★★★★ | 需较大改动 | 远期 |
| 纵垂联合 | ★★★★★ | 需新建项目 | 远期 |
| LiDAR 预瞄 | ★★★★ | 跨域需学习 | 感知方向 |

---

## 关键期刊

- *IEEE Transactions on Industrial Electronics* (TIE)
- *Mechanical Systems and Signal Processing* (MSSP)
- *IEEE/ASME Transactions on Mechatronics*
- *Vehicle System Dynamics* (VSD)
- *Journal of the Franklin Institute* (JFI)
- *SAE International* (WCX)

---

> 2026-05-10 笔记，基于 WebSearch 检索
