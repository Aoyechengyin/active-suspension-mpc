from __future__ import annotations

import html
import os
import zipfile
from pathlib import Path


ROOT = Path(r"E:\Scientific_Research\claude")
OUT_DIR = ROOT / "Output" / "Road-3" / "reporting"
OUT_DIR.mkdir(parents=True, exist_ok=True)
DOCX_PATH = OUT_DIR / "Road3_论文复现汇报演讲稿.docx"


def esc(text: str) -> str:
    return html.escape(text, quote=False)


def run(text: str, *, size: int = 21, bold: bool = False, color: str = "222222") -> str:
    # Word font size is half-points.
    b = "<w:b/>" if bold else ""
    return (
        "<w:r><w:rPr>"
        '<w:rFonts w:ascii="Microsoft YaHei UI" w:eastAsia="Microsoft YaHei UI" w:hAnsi="Microsoft YaHei UI"/>'
        f"<w:sz w:val=\"{size}\"/><w:color w:val=\"{color}\"/>{b}"
        f"</w:rPr><w:t>{esc(text)}</w:t></w:r>"
    )


def paragraph(
    text: str,
    *,
    style: str = "Normal",
    size: int = 21,
    bold: bool = False,
    color: str = "222222",
    before: int = 0,
    after: int = 120,
    line: int = 320,
    bullet: bool = False,
) -> str:
    ppr = [f'<w:pStyle w:val="{style}"/>', f'<w:spacing w:before="{before}" w:after="{after}" w:line="{line}" w:lineRule="auto"/>']
    if bullet:
        ppr.append('<w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr>')
    return f"<w:p><w:pPr>{''.join(ppr)}</w:pPr>{run(text, size=size, bold=bold, color=color)}</w:p>"


def heading(text: str, level: int = 1) -> str:
    if level == 1:
        return paragraph(text, style="Heading1", size=30, bold=True, color="1F4E79", before=280, after=120)
    return paragraph(text, style="Heading2", size=25, bold=True, color="2F6F7E", before=180, after=100)


def page_break() -> str:
    return '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'


slides = [
    (
        "1. 标题页",
        "老师好，我这次汇报的是基于 CarSim-Simulink-MATLAB 的 Road-3 论文凸包工况复现。我的汇报重点不是只给一个主动控制效果好或不好的结论，而是说明我如何把论文中的工况转化成可复现实验链路，并在结果不理想时定位问题边界。",
        "这一页要先建立汇报基调：不是展示一组漂亮曲线，而是展示完整复现过程和科研判断。",
    ),
    (
        "2. 总览结论",
        "先给结论：Road-2 已经通过验收，Road-3 的 T2 pilot 能跑通并完成多轮控制策略对比；但是 T2 full 150 mm 工况下，主动并没有大部分优于被动。更重要的是，被动组也出现离地和前悬止块几十 kN 冲击，所以 full 工况暴露的是车辆模型适用域问题，而不是单纯调参问题。",
        "这一页建议停顿一下，强调“负结果也是结果”，并说明我没有把问题简单归咎于控制器。",
    ),
    (
        "3. 复现对象",
        "我把论文中的 speed bump 工况拆成四类：T1 pilot、T1 full、T2 pilot、T2 full。由于论文只明确高度、长度和速度，我沿用现有生成器中的 half-sine 形状。为了避免短凸包被 0.16 m 网格失真，T1 使用 0.02 m 采样，T2 使用 0.05 m 采样。",
        "这里体现复现能力：把论文里不完整的描述转化成明确、可验收的仿真输入。",
    ),
    (
        "4. 工程链路",
        "我建立的是一条闭环链路：道路 CSV 生成、CarSim/Simulink 联合仿真、MATLAB 输出、自动验收脚本、对比报告和日志记录。每一次切换控制器或 profile 都清 persistent，输出目录按工况和策略分开，保证结果可复查。",
        "这里可以强调工程习惯：不是临时跑仿真，而是构建一个可回放、可追责的实验系统。",
    ),
    (
        "5. Pilot 初步结果",
        "T2 pilot 中，Q comfort C 能够让 Az event、Az 0-4 和 Az 0-15 小于 Passive，但 pitch、heave 和后悬回弹行程仍然更差。这说明主动控制并不是简单全面优于被动，而是在不同指标之间发生了能量和响应的转移。",
        "这里不要只报优势，要主动说出代价，体现对控制问题 trade-off 的理解。",
    ),
    (
        "6. 轴向隔离",
        "为了避免盲调参数，我做了前轴 only、后轴 only 和 both tight 的轴向隔离。结果显示后轴控制是唯一能压低 Az 的策略，而前轴控制更偏向改善 pitch，但会恶化 Az 和前悬行程。因此后续 comfort profile 以 rear-only 为主线。",
        "这里突出控制变量法：先分离因果贡献，再决定下一步调试方向。",
    ),
    (
        "7. Q profile 重训",
        "我扩展了离线训练工具，让它不只支持 rho5，也支持 rho1 到 rho5 完整 profile。A/B/C 第一次结果异常相同，我通过 hash 检查发现它们没有真正生效，重跑后才进入分析。这一步体现的是实验有效性检查，而不是只看文件名或仿真时间。",
        "这一页可以说明自己对数据有效性敏感，这是复现实验中很重要的科研素养。",
    ),
    (
        "8. 能量门控",
        "Q_C 之后我继续测试了 UV_POS 和 UV_NEG 两个能量门控方向。UV_POS 是更好的折中：它改善了 heave、pitch、rear travel 和限幅比例，但代价是 Az event 和 Az 0-15 不再优于 Passive。因此我把它冻结为 active-best，但明确它不是全指标胜利。",
        "这里强调科研诚实：折中最优不是全面最优，不能把局部改善包装成全胜。",
    ),
    (
        "9. T2 full 150 mm 结果",
        "进入论文 full 幅值后，主动组在 Az event、Az 0-4、Az 0-15、AA_P、heave、pitch 上都略差于 Passive，rear Jnc 也明显更差。因此不能把 full 工况写成主动优于被动。这个结论虽然不理想，但它是数据支持的。",
        "这里要直面结果，给导师留下“敢于报告真实结果”的印象。",
    ),
    (
        "10. 模型边界",
        "进一步诊断发现，Passive 和 Active 的 Fz 最小值都到 0 N，Fz 小于等于 0 的比例约 7.44%。同时前悬 jounce stop 达到 43 到 45 kN，rebound stop 也达到约 -33 kN。后悬止块力为 0，所以问题集中在前悬短行程和硬止块。",
        "这一页是最关键的技术判断：full 工况已经不是线性 MPC 能解决的常规舒适性问题。",
    ),
    (
        "11. 能力体现",
        "我认为这次复现最有价值的是形成了研究闭环：复现实验、暴露异常、增强可观测性、控制变量定位、明确停止条件、提出模型层修正。对我来说，这比单纯调出一个漂亮曲线更能体现科研能力。",
        "这里把过程上升到能力层面，回应导师关心的科研潜力。",
    ),
    (
        "12. 反思",
        "我的反思有三点。第一，论文工况参数不等于当前车辆模型一定可复现。第二，主动控制复现不仅要复现控制器，还要验证车辆模型、执行器约束和非线性止块。第三，研0阶段我还需要提高前置验收和模型假设检查能力。",
        "这一页要保持克制，不要自我表扬，重点讲下一步如何变得更严谨。",
    ),
    (
        "13. 下一步计划",
        "下一步我建议不覆盖原车辆，而是保留 baseline vehicle，复制 suspension jounce/rebound stop 数据集，建立 Road3_paper_longtravel 版本。然后重新跑 T2 full 的 Passive、no-preview 和 preview。只有当离地比例和前悬止块力明显下降后，再讨论主动控制是否真正优于被动。",
        "收尾要给出清晰行动路径：保留基线、建立新模型、重新对照、再讨论控制价值。",
    ),
]

questions = [
    ("为什么不继续调 MPC？", "因为 T2 full 中 Passive 本身已经离地，且前悬止块力达到几十 kN；这时系统主导因素是车辆模型非线性边界，继续调 MPC 容易把模型边界误判为控制器问题。"),
    ("为什么可以考虑改悬架行程？", "不是为了让主动结果好看，而是为了让论文 150 mm 工况在当前车辆模型上具有物理可复现性。修改后必须重新跑 Passive、no-preview 和 preview，不能混用旧结果。"),
    ("这次复现最大的收获是什么？", "我建立了可追溯实验链路，并能从负结果中识别模型假设问题。这比单纯跑出一个 pass/fail 更接近科研训练。"),
    ("博士阶段可以延展什么？", "可以延展到非线性止块约束建模、车辆模型适用域判定、主动悬架鲁棒控制，以及自动化实验矩阵与诊断报告。"),
]


styles_xml = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:pPr><w:spacing w:after="120" w:line="320" w:lineRule="auto"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Microsoft YaHei UI" w:eastAsia="Microsoft YaHei UI" w:hAnsi="Microsoft YaHei UI"/><w:sz w:val="21"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Title">
    <w:name w:val="Title"/>
    <w:basedOn w:val="Normal"/>
    <w:pPr><w:spacing w:after="180"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Microsoft YaHei UI" w:eastAsia="Microsoft YaHei UI" w:hAnsi="Microsoft YaHei UI"/><w:b/><w:sz w:val="38"/><w:color w:val="1F4E79"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:basedOn w:val="Normal"/>
    <w:pPr><w:spacing w:before="280" w:after="120"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Microsoft YaHei UI" w:eastAsia="Microsoft YaHei UI" w:hAnsi="Microsoft YaHei UI"/><w:b/><w:sz w:val="30"/><w:color w:val="1F4E79"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="heading 2"/>
    <w:basedOn w:val="Normal"/>
    <w:pPr><w:spacing w:before="180" w:after="100"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Microsoft YaHei UI" w:eastAsia="Microsoft YaHei UI" w:hAnsi="Microsoft YaHei UI"/><w:b/><w:sz w:val="25"/><w:color w:val="2F6F7E"/></w:rPr>
  </w:style>
</w:styles>
"""

numbering_xml = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:abstractNum w:abstractNumId="0">
    <w:multiLevelType w:val="singleLevel"/>
    <w:lvl w:ilvl="0">
      <w:start w:val="1"/>
      <w:numFmt w:val="bullet"/>
      <w:lvlText w:val="•"/>
      <w:lvlJc w:val="left"/>
      <w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr>
      <w:rPr><w:rFonts w:ascii="Microsoft YaHei UI" w:eastAsia="Microsoft YaHei UI" w:hAnsi="Microsoft YaHei UI" w:hint="default"/></w:rPr>
    </w:lvl>
  </w:abstractNum>
  <w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num>
</w:numbering>
"""

document_rels = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" Target="numbering.xml"/>
</Relationships>
"""

root_rels = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
"""

content_types = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
"""

core_xml = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>Road3 论文复现汇报演讲稿</dc:title>
  <dc:creator>ChatGPT</dc:creator>
  <cp:lastModifiedBy>ChatGPT</cp:lastModifiedBy>
</cp:coreProperties>
"""

app_xml = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Microsoft Word</Application>
</Properties>
"""

body = []
body.append(paragraph("Road-3 论文复现汇报演讲稿", style="Title", size=38, bold=True, color="1F4E79", after=180))
body.append(paragraph("建议时长：12-15 分钟。汇报目标：向导师展示复现能力、工程思维、科研诚实和博士阶段潜力。", size=22, bold=False, color="555555", after=240))
body.append(paragraph("使用方式：PPT 每页对应本文一个小节。每节包括“讲稿正文”和“转场/强调点”，可直接作为汇报时的口播提示。", size=21, color="555555", after=240))

for idx, (title, main, transition) in enumerate(slides, start=1):
    body.append(heading(title))
    body.append(paragraph("讲稿正文：", style="Heading2", size=24, bold=True, color="2F6F7E", before=80, after=80))
    body.append(paragraph(main, size=21, after=140))
    body.append(paragraph("转场/强调点：", style="Heading2", size=24, bold=True, color="2F6F7E", before=80, after=80))
    body.append(paragraph(transition, size=21, color="444444", after=180))
    if idx in {4, 8, 10, 13}:
        body.append(page_break())

body.append(heading("导师可能追问与回答要点"))
for q, a in questions:
    body.append(paragraph(q, style="Heading2", size=24, bold=True, color="2F6F7E", before=120, after=80))
    body.append(paragraph(a, size=21, after=120, bullet=True))

document_xml = f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    {''.join(body)}
    <w:sectPr>
      <w:pgSz w:w="12240" w:h="15840"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>
"""

with zipfile.ZipFile(DOCX_PATH, "w", compression=zipfile.ZIP_DEFLATED) as z:
    z.writestr("[Content_Types].xml", content_types)
    z.writestr("_rels/.rels", root_rels)
    z.writestr("docProps/core.xml", core_xml)
    z.writestr("docProps/app.xml", app_xml)
    z.writestr("word/document.xml", document_xml)
    z.writestr("word/_rels/document.xml.rels", document_rels)
    z.writestr("word/styles.xml", styles_xml)
    z.writestr("word/numbering.xml", numbering_xml)

print(DOCX_PATH)
