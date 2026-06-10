$ErrorActionPreference = "Stop"

$root = "E:\Scientific_Research\claude"
$outDir = Join-Path $root "Output\Road-3\reporting"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$pptxPath = Join-Path $outDir "Road3_论文复现过程与工程反思汇报.pptx"
$docxPath = Join-Path $outDir "Road3_reproduction_speech_script.docx"

$msoFalse = 0
$msoTrue = -1
$ppLayoutBlank = 12
$ppSaveAsOpenXMLPresentation = 24
$wdFormatXMLDocument = 12

function Rgb($r, $g, $b) {
    return ($r + ($g * 256) + ($b * 65536))
}

$C = @{
    Ink = Rgb 22 28 36
    Ink2 = Rgb 42 48 58
    Paper = Rgb 248 246 241
    White = Rgb 255 255 255
    Muted = Rgb 106 112 122
    Blue = Rgb 40 96 170
    Cyan = Rgb 30 142 160
    Green = Rgb 41 130 91
    Amber = Rgb 198 125 38
    Red = Rgb 180 70 65
    Line = Rgb 210 214 220
    PaleBlue = Rgb 226 236 248
    PaleGreen = Rgb 224 242 232
    PaleAmber = Rgb 249 236 218
    PaleRed = Rgb 248 225 224
}

function AddBox($slide, [double]$x, [double]$y, [double]$w, [double]$h, [int]$fill, [int]$line, [double]$radius = 0) {
    $shapeType = 1
    if ($radius -gt 0) { $shapeType = 5 }
    $s = $slide.Shapes.AddShape($shapeType, $x, $y, $w, $h)
    $s.Fill.ForeColor.RGB = $fill
    $s.Line.ForeColor.RGB = $line
    $s.Line.Weight = 0.8
    return $s
}

function AddText($slide, [string]$text, [double]$x, [double]$y, [double]$w, [double]$h, [int]$size = 18, [int]$color = 0, [bool]$bold = $false, [string]$font = "Microsoft YaHei UI") {
    $s = $slide.Shapes.AddTextbox(1, $x, $y, $w, $h)
    $tf = $s.TextFrame
    $tf.MarginLeft = 2
    $tf.MarginRight = 2
    $tf.MarginTop = 2
    $tf.MarginBottom = 2
    $tf.WordWrap = $msoTrue
    $tf.TextRange.Text = $text
    $tr = $tf.TextRange
    $tr.Font.Name = $font
    $tr.Font.Size = $size
    $tr.Font.Color.RGB = $color
    if ($bold) { $tr.Font.Bold = $msoTrue } else { $tr.Font.Bold = $msoFalse }
    return $s
}

function AddTitle($slide, [string]$kicker, [string]$title, [string]$subtitle = "") {
    AddText $slide $kicker 46 28 230 24 10 $C.Muted $true | Out-Null
    $line = $slide.Shapes.AddLine(46, 58, 666, 58)
    $line.Line.ForeColor.RGB = $C.Line
    $line.Line.Weight = 1
    AddText $slide $title 46 70 870 58 27 $C.Ink $true | Out-Null
    if ($subtitle.Length -gt 0) {
        AddText $slide $subtitle 48 126 820 30 13 $C.Muted $false | Out-Null
    }
}

function AddFooter($slide, [int]$idx) {
    AddText $slide "Road-3 论文复现 | CarSim-Simulink-MATLAB | 2026-06" 46 688 520 16 8 $C.Muted $false | Out-Null
    AddText $slide ("{0:00}" -f $idx) 912 686 24 16 8 $C.Muted $true | Out-Null
}

function AddKpi($slide, [string]$value, [string]$label, [string]$note, [double]$x, [double]$y, [double]$w, [int]$accent) {
    AddBox $slide $x $y $w 86 $C.White $C.Line 1 | Out-Null
    AddText $slide $value ($x+14) ($y+10) ($w-26) 28 24 $accent $true | Out-Null
    AddText $slide $label ($x+14) ($y+42) ($w-26) 18 11 $C.Ink $true | Out-Null
    AddText $slide $note ($x+14) ($y+61) ($w-26) 18 8 $C.Muted $false | Out-Null
}

function AddBullet($slide, [string[]]$items, [double]$x, [double]$y, [double]$w, [double]$gap = 36, [int]$size = 15) {
    $cy = $y
    foreach ($item in $items) {
        $dot = $slide.Shapes.AddShape(9, $x, $cy + 7, 6, 6)
        $dot.Fill.ForeColor.RGB = $C.Cyan
        $dot.Line.Visible = $msoFalse
        AddText $slide $item ($x+18) $cy ($w-18) 30 $size $C.Ink $false | Out-Null
        $cy += $gap
    }
}

function AddMiniTable($slide, [object[]]$rows, [double]$x, [double]$y, [double]$w, [double]$rowH, [int[]]$colWidths, [string[]]$headers) {
    $cols = $headers.Count
    $cx = $x
    for ($j=0; $j -lt $cols; $j++) {
        AddBox $slide $cx $y $colWidths[$j] $rowH $C.Ink2 $C.Ink2 0 | Out-Null
        AddText $slide $headers[$j] ($cx+6) ($y+6) ($colWidths[$j]-12) ($rowH-8) 9 $C.White $true | Out-Null
        $cx += $colWidths[$j]
    }
    $cy = $y + $rowH
    foreach ($row in $rows) {
        $cx = $x
        for ($j=0; $j -lt $cols; $j++) {
            $fill = $C.White
            if (($cy / $rowH) % 2 -lt 1) { $fill = Rgb 252 252 250 }
            AddBox $slide $cx $cy $colWidths[$j] $rowH $fill $C.Line 0 | Out-Null
            AddText $slide ([string]$row[$j]) ($cx+6) ($cy+5) ($colWidths[$j]-12) ($rowH-6) 8.5 $C.Ink $false | Out-Null
            $cx += $colWidths[$j]
        }
        $cy += $rowH
    }
}

function AddBar($slide, [string]$label, [double]$passive, [double]$active, [double]$maxVal, [double]$x, [double]$y, [double]$w, [string]$unit) {
    AddText $slide $label $x $y 116 18 9 $C.Ink $true | Out-Null
    $px = $x + 126
    AddBox $slide $px ($y+3) ($w * $passive / $maxVal) 8 $C.Muted $C.Muted 0 | Out-Null
    AddBox $slide $px ($y+17) ($w * $active / $maxVal) 8 $C.Blue $C.Blue 0 | Out-Null
    AddText $slide ("P {0:N3}{1}" -f $passive,$unit) ($px+$w+8) ($y-1) 90 12 7.5 $C.Muted $false | Out-Null
    AddText $slide ("A {0:N3}{1}" -f $active,$unit) ($px+$w+8) ($y+13) 90 12 7.5 $C.Blue $false | Out-Null
}

function AddStep($slide, [string]$num, [string]$title, [string]$text, [double]$x, [double]$y, [double]$w, [int]$accent) {
    AddBox $slide $x $y $w 82 $C.White $C.Line 1 | Out-Null
    $circle = $slide.Shapes.AddShape(9, $x+12, $y+15, 30, 30)
    $circle.Fill.ForeColor.RGB = $accent
    $circle.Line.Visible = $msoFalse
    AddText $slide $num ($x+18) ($y+20) 18 18 11 $C.White $true | Out-Null
    AddText $slide $title ($x+52) ($y+12) ($w-64) 20 13 $C.Ink $true | Out-Null
    AddText $slide $text ($x+52) ($y+35) ($w-64) 36 9.5 $C.Muted $false | Out-Null
}

function AddSlide($ppt, [int]$idx) {
    $slide = $ppt.Slides.Add($idx, $ppLayoutBlank)
    $slide.FollowMasterBackground = $msoFalse
    $slide.Background.Fill.ForeColor.RGB = $C.Paper
    return $slide
}

$pp = New-Object -ComObject PowerPoint.Application
$pp.Visible = $msoTrue
$ppt = $pp.Presentations.Add()
$ppt.PageSetup.SlideWidth = 960
$ppt.PageSetup.SlideHeight = 720

# Slide 1
$s = AddSlide $ppt 1
AddBox $s 0 0 960 720 $C.Ink $C.Ink 0 | Out-Null
AddText $s "论文主动悬架凸包工况复现汇报" 58 88 780 62 32 $C.White $true | Out-Null
AddText $s "Road-3 speed bump | CarSim-Simulink-MATLAB | 复现过程、结果与反思" 60 154 780 30 15 (Rgb 215 221 230) $false | Out-Null
AddKpi $s "4类路面" "Road-3 half-sine CSV" "10/50/150 mm; 0.4/2.5 m" 60 246 205 $C.Cyan
AddKpi $s "三阶段调试" "轴向隔离 + Q重训 + 能量门控" "停止条件驱动，而非盲目调参" 285 246 260 $C.Green
AddKpi $s "关键结论" "150 mm 暴露车辆模型边界" "前悬止块/离地主导响应" 565 246 260 $C.Amber
AddText $s "汇报目的：展示我如何把论文工况转化为可复现实验链路，并从失败结果中识别模型边界。" 62 610 770 38 16 (Rgb 226 231 238) $false | Out-Null

# Slide 2
$s = AddSlide $ppt 2
AddTitle $s "EXECUTIVE SUMMARY" "这次复现不是简单`"跑通`"，而是建立了一套可追溯的工程验证链" "导师汇报建议先给结论：我复现了论文凸包工况，也定位了 full 工况失效的物理边界。"
AddKpi $s "PASS" "Road-2 验收" "单凸包结果 0 warnings" 52 190 180 $C.Green
AddKpi $s "有效" "Road-3 T2 pilot" "预瞄提前量 W1/W2 = 10/20 ms" 250 190 220 $C.Blue
AddKpi $s "未全胜" "Active vs Passive" "T2 pilot 只能改善部分指标" 490 190 210 $C.Amber
AddKpi $s "边界" "T2 full 150 mm" "Passive 也发生离地/止块冲击" 720 190 185 $C.Red
AddBullet $s @(
    "复现层面：道路、速度、输出变量、验收脚本、对比报告和日志均建立可复查链路。",
    "工程层面：每次异常先做可观测性增强，再分离控制器、路面、车辆模型和输出层因素。",
    "科研层面：没有把`"主动控制不如被动`"简单归咎为调参失败，而是识别出车辆模型行程限制。"
) 70 340 790 52 18
AddFooter $s 2

# Slide 3
$s = AddSlide $ppt 3
AddTitle $s "REPRODUCTION TARGET" "复现对象被拆成可验收的 Road-3 论文 speed-bump 工况" "论文只给出凸包高度、长度和速度；我采用现有生成器的 half-sine 路面定义。"
AddMiniTable $s @(
    @("T1 pilot","10 mm","0.4 m","30 km/h","s0=60 m, dx=0.02 m"),
    @("T1 full","50 mm","0.4 m","30 km/h","s0=60 m, dx=0.02 m"),
    @("T2 pilot","50 mm","2.5 m","50 km/h","s0=100 m, dx=0.05 m"),
    @("T2 full","150 mm","2.5 m","50 km/h","s0=100 m, dx=0.05 m")
) 60 190 840 38 @(120,110,110,120,300) @("工况","高度","长度","速度","路面采样")
AddText $s "复现质量控制" 70 410 260 24 16 $C.Ink $true | Out-Null
AddBullet $s @(
    "路面文件峰值、端点、峰值位置和 NaN/Inf 检查。",
    "输出变量追加 Zcg_SM、AA_P、AA_R、FJSt/FRSt 等诊断量。",
    "每次切换控制模式清 persistent，避免状态污染。"
) 74 446 770 40 14
AddFooter $s 3

# Slide 4
$s = AddSlide $ppt 4
AddTitle $s "ENGINEERING PIPELINE" "我把复现搭成了`"道路生成-仿真-验收-诊断-回退`"的闭环" "重点不是单次结果，而是每一步都有输入、输出、判据和回退点。"
AddStep $s "1" "道路生成" "half-sine bump CSV；短凸包 0.02 m、长凸包 0.05 m 加密采样。" 58 172 260 $C.Cyan
AddStep $s "2" "CarSim/Simulink" "冻结 B3 基准控制器，逐步切换 Passive/no-preview/preview。" 350 172 260 $C.Blue
AddStep $s "3" "验收脚本" "AnalyzeRoadAcceptance / Road3Bump / T2PassiveGap 自动输出报告。" 642 172 260 $C.Green
AddStep $s "4" "诊断增强" "追加止块力、轮胎力、悬架行程和低频分频 RMS。" 58 310 260 $C.Amber
AddStep $s "5" "控制器重训" "rho/Q profile 离线重训，保留历史数据可回退。" 350 310 260 $C.Cyan
AddStep $s "6" "停止条件" "若轴向隔离、Q重训、能量门控均不能全胜，则停止盲目调参。" 642 310 260 $C.Red
AddText $s "工程思维体现：先扩大可观测性，再做控制变量实验；每次结论都能追到 CSV、脚本和日志。" 78 585 790 40 17 $C.Ink $true | Out-Null
AddFooter $s 4

# Slide 5
$s = AddSlide $ppt 5
AddTitle $s "PILOT FINDINGS" "T2 pilot 暴露出 Passive 是强基线，主动只能改善部分指标" "第一轮 preview 跑通后，我没有直接上 150 mm，而是先检查速度、预瞄、限幅和行程。"
AddBar $s "Az event RMS" 1.114713 1.103862 1.5 80 210 420 " m/s²"
AddBar $s "Az 0-4 RMS" 0.634054 0.592498 1.0 80 262 420 " m/s²"
AddBar $s "Pitch peak" 1.230976 1.425203 1.8 80 314 420 " deg"
AddBar $s "Rear Jnc min abs" 14.108 26.119 32 80 366 420 " mm"
AddText $s "灰色=Passive，蓝色=Q comfort C。Q_C 压低了 Az，但牺牲 pitch 和后悬回弹行程。" 90 446 630 24 12 $C.Muted $false | Out-Null
AddBox $s 650 206 240 202 $C.PaleAmber $C.Line 1 | Out-Null
AddText $s "关键判断" 670 224 200 24 16 $C.Ink $true | Out-Null
AddBullet $s @(
    "不能只看一个舒适性指标。",
    "主动控制可能把能量转移到姿态或悬架行程。",
    "需要轴向隔离和能量门控继续定位。"
) 670 264 195 36 12
AddFooter $s 5

# Slide 6
$s = AddSlide $ppt 6
AddTitle $s "AXIS ISOLATION" "轴向隔离证明：后轴控制能压低 Az，前轴控制更偏向改善 pitch" "这一步避免了把前后轴混在一起盲调参数。"
AddMiniTable $s @(
    @("Both tight","+0.220","+0.278","+0.119","-13.95","不作为主线"),
    @("Front only","+0.257","+0.335","-0.155","-0.58","pitch 好但 Az 恶化"),
    @("Rear only","-0.018","-0.046","+0.246","-13.15","进入 Q comfort")
) 62 190 836 44 @(125,105,105,105,105,260) @("模式","Az event gap","Az 0-4 gap","Pitch gap","Rear Jnc gap","判断")
AddBox $s 78 430 365 96 $C.PaleGreen $C.Line 1 | Out-Null
AddText $s "实验设计能力" 98 448 260 22 15 $C.Green $true | Out-Null
AddText $s "我用控制变量法分离前轴/后轴贡献，而不是在一个耦合系统里直接堆参数。" 98 480 310 36 13 $C.Ink $false | Out-Null
AddBox $s 500 430 365 96 $C.PaleBlue $C.Line 1 | Out-Null
AddText $s "下一步逻辑" 520 448 260 22 15 $C.Blue $true | Out-Null
AddText $s "以 rear-only 为主线做 comfort profile，后续再用 gate 抑制回弹阶段能量注入。" 520 480 310 36 13 $C.Ink $false | Out-Null
AddFooter $s 6

# Slide 7
$s = AddSlide $ppt 7
AddTitle $s "COMFORT RETRAINING" "Q comfort C 是 pilot 阶段综合最好的折中 profile，但仍不能全方位超过 Passive" "A/B/C 重跑前做了 hash 有效性检查，避免把同一份结果误认为三组调参结果。"
AddMiniTable $s @(
    @("Rear only","-0.018","-0.046","+0.246","-13.15","Az 最好，姿态差"),
    @("Q comfort A","-0.012","-0.043","+0.229","-12.79","略改善"),
    @("Q comfort B","-0.011","-0.037","+0.214","-12.46","略改善"),
    @("Q comfort C","-0.011","-0.042","+0.194","-12.01","综合最好")
) 62 184 836 42 @(125,105,105,105,105,260) @("profile","Az event gap","Az 0-4 gap","Pitch gap","Rear Jnc gap","判断")
AddText $s "科研规范点" 72 436 220 24 16 $C.Ink $true | Out-Null
AddBullet $s @(
    "先发现 A/B/C 与 rear-only 字节级相同，判断仿真未真正加载 profile。",
    "重跑后确认 hash 不同，再进入结果解释。",
    "保留历史离线数据，支持回退和复现实验记录。"
) 76 472 760 38 14
AddFooter $s 7

# Slide 8
$s = AddSlide $ppt 8
AddTitle $s "ENERGY GATE" "能量门控把 Q_C 推向更稳的折中：heave/pitch/rear travel 改善，但 Az 不再全胜" "这是主动悬架设计中的典型 trade-off：舒适性、姿态、行程和限幅不能只靠单目标优化。"
AddMiniTable $s @(
    @("Q_C","-0.011","-0.042","+0.00038","+0.194","-12.01","Az 好，姿态/行程差"),
    @("Q_C + UV_POS","+0.051","-0.030","+0.00004","+0.119","-9.00","折中最好"),
    @("Q_C + UV_NEG","+0.199","+0.291","+0.00652","-0.086","-1.73","Az/heave 明显差")
) 54 190 850 46 @(120,95,95,105,95,95,245) @("模式","Az event","Az 0-4","Heave gap","Pitch gap","Rear Jnc","结论")
AddBox $s 72 430 790 92 $C.PaleAmber $C.Line 1 | Out-Null
AddText $s "最终 active-best 冻结为 Q_C + UV_POS，但我明确标注它是`"折中最优`"，不是`"全指标优于被动`"。" 96 456 740 28 18 $C.Ink $true | Out-Null
AddText $s "这体现科研诚实：不把局部改善包装成全面胜利。" 96 493 680 20 13 $C.Muted $false | Out-Null
AddFooter $s 8

# Slide 9
$s = AddSlide $ppt 9
AddTitle $s "FULL CONDITION RESULT" "150 mm full 工况下，主动没有大部分优于被动；两者都进入车辆模型极限区" "这是本次复现最重要的负结果：失败不是终点，而是模型边界识别。"
AddMiniTable $s @(
    @("Az event RMS","3.397","3.433","+0.036","Active略差"),
    @("Az 0-4 RMS","2.154","2.219","+0.065","Active略差"),
    @("Az 0-15 RMS","3.124","3.149","+0.025","Active略差"),
    @("AA_P 0-15","2.920","2.958","+0.038","Active略差"),
    @("heave peak","0.126","0.128","+0.002","Active略差"),
    @("pitch peak","5.207","5.279","+0.072","Active略差")
) 62 174 610 38 @(150,105,105,105,145) @("指标","Passive","Active","差值","判断")
AddBox $s 704 186 190 262 $C.PaleRed $C.Line 1 | Out-Null
AddText $s "不能下的结论" 724 208 160 22 15 $C.Red $true | Out-Null
AddBullet $s @(
    "不能宣称 full 工况主动优于被动。",
    "不能继续只靠 MPC 参数硬调。",
    "不能忽略车辆模型行程约束。"
) 724 248 145 42 11
AddFooter $s 9

# Slide 10
$s = AddSlide $ppt 10
AddTitle $s "MODEL BOUNDARY" "150 mm 不是单纯控制问题，而是前悬止块与轮胎离地共同主导" "Passive 也离地，说明物理基线本身已经进入强非线性。"
AddKpi $s "0 N" "Fz 最小值" "Passive 与 Active 均达到" 64 185 180 $C.Red
AddKpi $s "7.44%" "Fz <= 0 N" "两组均出现离地/卸载" 270 185 190 $C.Red
AddKpi $s "43-45 kN" "前悬 jounce stop" "几十 kN 硬冲击" 486 185 205 $C.Amber
AddKpi $s "+70/-50 mm" "前悬行程限" "截图参数对应极短回弹行程" 716 185 180 $C.Amber
AddText $s "分角点诊断" 76 336 220 24 17 $C.Ink $true | Out-Null
AddBullet $s @(
    "前悬 FJSt/FRSt 达几十 kN；后悬止块力仍为 0。",
    "Active 使前悬止块力和后悬回弹位移略恶化。",
    "150 mm full 应先调整车辆/悬架 stop 数据集，再谈控制效果。"
) 80 374 760 42 15
AddFooter $s 10

# Slide 11
$s = AddSlide $ppt 11
AddTitle $s "WHAT THIS SHOWS" "这次复现能力的核心证据：我能把失败变成可解释、可复查、可推进的问题" "面向导师，不只汇报结果，也要汇报科研训练中的方法论。"
AddStep $s "A" "复现能力" "把论文工况拆成路面、速度、输出、验收指标和事件窗口。" 62 178 250 $C.Blue
AddStep $s "B" "工程思维" "用日志、脚本、hash、可回退离线数据维护实验可追溯性。" 355 178 250 $C.Green
AddStep $s "C" "科研判断" "不执着于调参胜利，而是识别车辆模型与控制器假设的边界。" 648 178 250 $C.Amber
AddBox $s 88 348 760 124 $C.White $C.Line 1 | Out-Null
AddText $s "我认为这次最有价值的不是某个指标是否超过 Passive，而是形成了一个研究闭环：" 112 374 710 24 17 $C.Ink $true | Out-Null
AddText $s "复现实验 -> 暴露异常 -> 增强可观测性 -> 控制变量定位 -> 明确停止条件 -> 提出下一阶段模型修正。" 112 420 710 26 18 $C.Blue $true | Out-Null
AddFooter $s 11

# Slide 12
$s = AddSlide $ppt 12
AddTitle $s "REFLECTION" "反思：主动悬架复现不能只复现控制器，还要复现车辆模型的适用域" "研0阶段我还需要提升论文细节追踪、模型假设验证和实验设计的前置性。"
AddMiniTable $s @(
    @("做对的事","道路加密采样、输出诊断变量、模式隔离、hash有效性检查","保证结果可复查"),
    @("踩到的问题","T1 pilot 初次速度不符；T2 full 才发现车辆行程边界","前置验收还可更早"),
    @("最重要反思","论文工况参数不等于本车模型一定可物理复现","要先确认适用域"),
    @("下一步能力建设","补充车辆参数辨识、止块非线性建模、实验矩阵设计","从复现走向改进")
) 62 190 836 56 @(140,500,196) @("维度","内容","能力指向")
AddFooter $s 12

# Slide 13
$s = AddSlide $ppt 13
AddTitle $s "NEXT PLAN" "下一阶段：保留基线车辆，另建 long-travel 车辆版本，再重跑全套对照" "这能避免污染原始复现基线，同时验证 150 mm 工况是否需要模型层修正。"
AddStep $s "1" "冻结当前复现基线" "保留 Road3_baseline_vehicle 与所有 CSV/脚本/日志。" 70 178 250 $C.Blue
AddStep $s "2" "复制悬架 stop 数据集" "建立 ASCII 命名 Road3_paper_longtravel，不覆盖原车。" 355 178 250 $C.Amber
AddStep $s "3" "重跑对照实验" "T2 full Passive / no-preview / preview 全部重跑，旧结果不混用。" 640 178 250 $C.Green
AddStep $s "4" "判断控制价值" "若离地比例和止块力下降，再讨论 active 是否真正优于 passive。" 70 320 250 $C.Cyan
AddStep $s "5" "写入论文式报告" "报告同时呈现正结果、负结果和模型边界。" 355 320 250 $C.Green
AddStep $s "6" "形成博士阶段问题" "把复现扩展到模型适用域、非线性约束和鲁棒控制。" 640 320 250 $C.Blue
AddText $s "结束语：我希望把这次复现作为科研训练起点，从`"能跑通`"推进到`"能解释、能质疑、能改进`"。" 92 592 760 32 18 $C.Ink $true | Out-Null
AddFooter $s 13

$ppt.SaveAs($pptxPath, $ppSaveAsOpenXMLPresentation)
$ppt.Close()
$pp.Quit()

# Build Word speech script
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$doc = $word.Documents.Add()
$selection = $word.Selection
$selection.Font.Name = "Microsoft YaHei UI"
$selection.Font.Size = 11

function WTitle([string]$text) {
    $selection.Range.ListFormat.RemoveNumbers() | Out-Null
    $selection.Font.Name = "Microsoft YaHei UI"
    $selection.Font.Size = 18
    $selection.Font.Bold = $msoTrue
    $selection.TypeText($text)
    $selection.TypeParagraph()
    $selection.Font.Bold = $msoFalse
    $selection.Font.Size = 10.5
}

function WH1([string]$text) {
    $selection.Range.ListFormat.RemoveNumbers() | Out-Null
    $selection.Font.Name = "Microsoft YaHei UI"
    $selection.Font.Size = 14
    $selection.Font.Bold = $msoTrue
    $selection.TypeText($text)
    $selection.TypeParagraph()
    $selection.Font.Bold = $msoFalse
    $selection.Font.Size = 10.5
}

function WPara([string]$text) {
    $selection.Range.ListFormat.RemoveNumbers() | Out-Null
    $selection.Font.Name = "Microsoft YaHei UI"
    $selection.Font.Size = 10.5
    $selection.Font.Bold = $msoFalse
    $selection.TypeText($text)
    $selection.TypeParagraph()
}

function WBullet([string]$text) {
    $selection.Font.Name = "Microsoft YaHei UI"
    $selection.Font.Size = 10.5
    $selection.Font.Bold = $msoFalse
    $selection.Range.ListFormat.ApplyBulletDefault() | Out-Null
    $selection.TypeText($text)
    $selection.TypeParagraph()
    $selection.Range.ListFormat.RemoveNumbers() | Out-Null
}

WTitle "Road-3 论文复现汇报演讲稿"
WPara "建议时长：12-15 分钟。汇报目标：向导师展示复现能力、工程思维、科研诚实和博士阶段潜力。"

$script = @(
@("1. 标题页","老师好，我这次汇报的是基于 CarSim-Simulink-MATLAB 的 Road-3 论文凸包工况复现。我的汇报重点不是只给一个主动控制效果好或不好的结论，而是说明我如何把论文中的工况转化成可复现实验链路，并在结果不理想时定位问题边界。"),
@("2. 总览结论","先给结论：Road-2 已经通过验收，Road-3 的 T2 pilot 能跑通并完成多轮控制策略对比；但是 T2 full 150 mm 工况下，主动并没有大部分优于被动。更重要的是，被动组也出现离地和前悬止块几十 kN 冲击，所以 full 工况暴露的是车辆模型适用域问题，而不是单纯调参问题。"),
@("3. 复现对象","我把论文中的 speed bump 工况拆成四类：T1 pilot、T1 full、T2 pilot、T2 full。由于论文只明确高度、长度和速度，我沿用现有生成器中的 half-sine 形状。为了避免短凸包被 0.16 m 网格失真，T1 使用 0.02 m 采样，T2 使用 0.05 m 采样。"),
@("4. 工程链路","我建立的是一条闭环链路：道路 CSV 生成、CarSim/Simulink 联合仿真、MATLAB 输出、自动验收脚本、对比报告和日志记录。每一次切换控制器或 profile 都清 persistent，输出目录按工况和策略分开，保证结果可复查。"),
@("5. Pilot 初步结果","T2 pilot 中，Q comfort C 能够让 Az event、Az 0-4 和 Az 0-15 小于 Passive，但 pitch、heave 和后悬回弹行程仍然更差。这说明主动控制并不是简单全面优于被动，而是在不同指标之间发生了能量和响应的转移。"),
@("6. 轴向隔离","为了避免盲调参数，我做了前轴 only、后轴 only 和 both tight 的轴向隔离。结果显示后轴控制是唯一能压低 Az 的策略，而前轴控制更偏向改善 pitch，但会恶化 Az 和前悬行程。因此后续 comfort profile 以 rear-only 为主线。"),
@("7. Q profile 重训","我扩展了离线训练工具，让它不只支持 rho5，也支持 rho1 到 rho5 完整 profile。A/B/C 第一次结果异常相同，我通过 hash 检查发现它们没有真正生效，重跑后才进入分析。这一步体现的是实验有效性检查，而不是只看文件名或仿真时间。"),
@("8. 能量门控","Q_C 之后我继续测试了 UV_POS 和 UV_NEG 两个能量门控方向。UV_POS 是更好的折中：它改善了 heave、pitch、rear travel 和限幅比例，但代价是 Az event 和 Az 0-15 不再优于 Passive。因此我把它冻结为 active-best，但明确它不是全指标胜利。"),
@("9. T2 full 150 mm 结果","进入论文 full 幅值后，主动组在 Az event、Az 0-4、Az 0-15、AA_P、heave、pitch 上都略差于 Passive，rear Jnc 也明显更差。因此不能把 full 工况写成主动优于被动。这个结论虽然不理想，但它是数据支持的。"),
@("10. 模型边界","进一步诊断发现，Passive 和 Active 的 Fz 最小值都到 0 N，Fz 小于等于 0 的比例约 7.44%。同时前悬 jounce stop 达到 43 到 45 kN，rebound stop 也达到约 -33 kN。后悬止块力为 0，所以问题集中在前悬短行程和硬止块。"),
@("11. 能力体现","我认为这次复现最有价值的是形成了研究闭环：复现实验、暴露异常、增强可观测性、控制变量定位、明确停止条件、提出模型层修正。对我来说，这比单纯调出一个漂亮曲线更能体现科研能力。"),
@("12. 反思","我的反思有三点。第一，论文工况参数不等于当前车辆模型一定可复现。第二，主动控制复现不仅要复现控制器，还要验证车辆模型、执行器约束和非线性止块。第三，研0阶段我还需要提高前置验收和模型假设检查能力。"),
@("13. 下一步计划","下一步我建议不覆盖原车辆，而是保留 baseline vehicle，复制 suspension jounce/rebound stop 数据集，建立 Road3_paper_longtravel 版本。然后重新跑 T2 full 的 Passive、no-preview 和 preview。只有当离地比例和前悬止块力明显下降后，再讨论主动控制是否真正优于被动。")
)

foreach ($entry in $script) {
    WH1 $entry[0]
    WPara $entry[1]
    WPara "转场提示：这一页的核心是把结果放回`"复现质量`"和`"工程判断`"中解释，不要只报数值。"
}

WH1 "导师可能追问与回答要点"
WBullet "为什么不继续调 MPC？因为 T2 full 中 Passive 本身已经离地，且前悬止块力达到几十 kN；这时系统主导因素是车辆模型非线性边界。"
WBullet "为什么可以改悬架行程？不是为了让主动好看，而是为了让论文 150 mm 工况在当前车辆模型上具有物理可复现性；修改后必须重跑 Passive。"
WBullet "这次复现最大的收获是什么？不是证明 active 一定更好，而是建立了可追溯实验链路，并能从负结果中识别模型假设问题。"
WBullet "博士阶段可以延展什么？非线性止块约束建模、可行域判定、主动悬架鲁棒控制和实验设计自动化。"

$doc.SaveAs([ref]$docxPath)
$doc.Close()
$word.Quit()

Write-Host "PPTX: $pptxPath"
Write-Host "DOCX: $docxPath"



