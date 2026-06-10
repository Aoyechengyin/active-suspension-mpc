# Road Acceptance 分析脚本使用说明

日期：2026-06-06

## 脚本文件

- `src_2020/AnalyzeRoadAcceptance_2020.m`
- `src_2020/test_road_acceptance_2020.m`

`AnalyzeRoadAcceptance_2020.m` 用于检查道路实验 CSV 是否满足当前阶段验收条件，重点包括：

- `Time` 采样间隔、仿真时长、`Station`、车速。
- `Zgnd/W1/W2` 峰值和预瞄提前量。
- 四轮 `FsExt_*` 峰值、RMS、饱和比例。
- 前后轴左右外力差。
- `Az_SM/Ay_SM/Vz_SM/Roll/Pitch/Yaw/Yo/JncR_*` 动态响应。
- `Rot_*` 是否连续增加。

`test_road_acceptance_2020.m` 是脚本自检，用合成 CSV 验证预瞄提前量、饱和判断、轮转判断和 Markdown 报告输出。

## 当前验证结果

你在 MATLAB 中已经完成以下验证：

```matlab
addpath('src_2020');
AnalyzeRoadAcceptance_2020( ...
    'Output/Road-2A/2026-06-06_18.10.16.csv', ...
    'Output/Road-2A/road_acceptance_report.md');
```

MATLAB 输出：

```text
Road acceptance report written: Output/Road-2A/road_acceptance_report.md
Road acceptance status: PASS (0 warnings)
```

脚本自检命令：

```matlab
addpath('src_2020');
test_road_acceptance_2020;
```

MATLAB 输出：

```text
Road acceptance report written: D:\Temp\road_acceptance_fixture.md
Road acceptance status: PASS (0 warnings)
test_road_acceptance_2020 passed.
```

结论：Road-2A 的 5 mm 单凸包工况通过当前道路实验验收脚本，可以进入 Road-2B 的 10 mm 单凸包工况。

Road-2B 随后完成验证：

```matlab
AnalyzeRoadAcceptance_2020( ...
    'Output/Road-2B/2026-06-06_18.55.38.csv', ...
    'Output/Road-2B/road_acceptance_report.md');
```

MATLAB 输出：

```text
Road acceptance report written: Output/Road-2B/road_acceptance_report.md
Road acceptance status: PASS (0 warnings)
```

结论：Road-2B 的 10 mm 单凸包工况也通过当前道路实验验收脚本。

## Road-2B 使用模板

完成 Road-2B 仿真后，在 MATLAB 工程根目录运行：

```matlab
cd('E:\Scientific_Research\claude');
addpath('src_2020');
AnalyzeRoadAcceptance_2020( ...
    'Output/Road-2B_10mm/your_result.csv', ...
    'Output/Road-2B_10mm/road_acceptance_report.md');
```

如果你实际输出目录仍采用 `Output/Road-2B/`，则改为：

```matlab
cd('E:\Scientific_Research\claude');
addpath('src_2020');
AnalyzeRoadAcceptance_2020( ...
    'Output/Road-2B/your_result.csv', ...
    'Output/Road-2B/road_acceptance_report.md');
```

其中 `your_result.csv` 替换成 CarSim 实际导出的 CSV 文件名。

## 判读规则

如果命令行输出：

```text
Road acceptance status: PASS (0 warnings)
```

说明该组工况满足当前验收条件。

如果输出：

```text
Road acceptance status: CHECK (... warnings)
```

需要打开生成的 `road_acceptance_report.md`，优先查看 `Warnings` 部分。常见需要暂停升级路面的情况：

- `W1/W2` 预瞄提前量不接近 `10 ms / 20 ms`。
- 任一 `FsExt_*` 饱和比例超过阈值。
- 后轴左右外力差明显超过 `1000 N`。
- `Roll/Yaw/Yo` 出现持续漂移。
- `Rot_*` 没有持续增加。

## MATLAB 启动异常说明

如果 MATLAB 在启动阶段出现：

```text
Fatal Startup Error
std::exception::what: System Error: File system inconsistency
```

这不是 `AnalyzeRoadAcceptance_2020.m` 的脚本错误，而是 MATLAB 启动或本机文件系统状态问题。需要先恢复 MATLAB 启动环境，再运行上述命令。
