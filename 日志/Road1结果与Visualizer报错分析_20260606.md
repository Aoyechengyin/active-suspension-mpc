# Road-1 结果与 VS Visualizer 报错分析 2026-06-06

## 输入结果

- CSV: `Output/Road-1/2026-06-06_17.40.14.csv`
- CarSim Results: `D:/CarSim2020.0_Prog/CarSim2020.0_Data/Results/Run_ae835396-4572-469c-94e9-846669454d32`
- Visualizer 报错：`Unhandled unknown exception; terminating the application.`

## CSV 数据结论

数值仿真结果正常：

- 行数：`15001`
- 时间：`0` 到 `15 s`
- 采样间隔：固定 `0.001 s`
- 终点 Station：`208.1787589537 m`
- `Vxz_Fwd`：约 `50 km/h`
- CSV 未发现 `NaN`、`Inf` 或异常文本。

Road-1 三凸包已被车辆正确激励：

- `Zgnd_*` 峰值约 `0.001 / 0.002 / 0.0015 m`
- `W1_*` 相对对应 `Zgnd_*` 提前约 `10 ms`
- `W2_*` 相对对应 `Zgnd_*` 提前约 `20 ms`
- 四轮、三个凸包均满足上述预瞄提前量。

eMPC 输出正常：

- 四角 `FsExt_*` 均无饱和。
- 最大外力约：
  - `FsExt_L1 max abs = 842 N`
  - `FsExt_R1 max abs = 836 N`
  - `FsExt_L2 max abs = 289 N`
  - `FsExt_R2 max abs = 292 N`
- 前轴左右外力差峰值约 `13.1 N`。
- 后轴左右外力差峰值约 `6.9 N`。

车身姿态和轮动正常：

- `Roll final ≈ 0.00203 deg`
- `Pitch final ≈ 0.23751 deg`
- `Yaw final ≈ -0.01251 deg`
- `Yo final ≈ -0.02208 m`
- 后轴 `JncR peak ≈ 45.25 mm/s`
- 四轮 `Rot_*` 均连续增加。

相对 B4 平路基准，Road-1 主要增加的是路面激励引起的垂向响应：

- B4 `Az_SM peak ≈ 0.0043 g`
- Road-1 `Az_SM peak ≈ 0.1012 g`

这个峰值来自三凸包路面事件，不是控制器饱和或车辆失稳。

## Visualizer 报错判断

当前证据不支持“仿真失败”或“控制器导致崩溃”。更可能是 VS Visualizer 在读取动画/道路配置时崩溃。

最可疑根因：

1. Road-1 的 CarSim 道路数据集名包含中文。
2. 在 `2026-06-06_17.40.14_all.par` 和 `2026-06-06_17.40.14_echo.par` 中，道路数据集名已经显示为乱码：

```text
Road: 3D Surface (All Properties)`��С���ɿ�·��_regionless`
Road: Reference Line Elevation`��С���ɿ�·��_regioness`
ROAD_ID(1) 1 ; ��С���ɿ�·��_regionless
```

CarSim 2020 的 VS Visualizer 对非 ASCII 数据集名/描述字段可能不稳定，尤其是在 3D Road 和 Animator 配置一起加载时。

次要可疑点：

- Results 目录中存在旧的 `Run_log.txt`、`Run_out_tab.txt`、`Run_imp_tab.txt`，但本次实际使用的是带时间戳的 `2026-06-06_17.40.14.*` 文件。该点不像主因，但后续可通过新建干净 Run 或清理旧 Results 目录进一步排除。

## 建议修正

下一次 Road-1 复跑前，不改 Simulink、不改控制器，只改 CarSim 数据集命名：

- Road 3D Surface 数据集名改为 ASCII，例如 `Road1_3bumps_210m`.
- Road Reference Line Elevation 数据集名改为 ASCII，例如 `Road1_refz_3bumps_210m`.
- 避免在 CarSim 数据集标题、说明、路径中使用中文、全角符号或特殊字符。
- 保持 CSV 文件名当前 ASCII 形式：`Road1_preview_3bumps_210m_0p16m.csv`.

复跑后检查：

1. Simulink 仿真能否仍完整跑到 `15 s`。
2. `W1/W2` 是否仍提前 `10/20 ms`。
3. VS Visualizer 是否能打开动画。

如果 ASCII 重命名后 Visualizer 仍崩溃，再做第二步排查：

- 将 Output 频率临时降到 `100 Hz` 复跑一次，仅验证 Visualizer 是否能打开。
- 临时关闭 `2 Axle - Fx, Fy, Fz` 力箭头动画组，验证是否是力箭头或道路表面渲染触发。
- 保持同一 Road-1 路面，不改 eMPC 控制器。
