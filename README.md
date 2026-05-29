# Claude Code Research Harness Workflow

> **面向 Agent 辅助实证研究的受控执行框架。**  
> 把 Claude Code 从会写代码的智能体，变成可审计、可复现的研究协作者。

**作者：** 朱 晨 | 遗传社科研究 Chen Zhu | China Agricultural University (CAU)

**最后更新：** 2026-05-29

<p align="center">
  <strong>Specify → Audit → Clean → Plan → Work → Review → Release</strong><br>
  <strong>定义问题 → 审查数据 → 清洗合并 → 制定计划 → 执行分析 → 审阅结果 → 发布复制包</strong>
</p>

<p align="center">
  <code>/research-harness-setup</code> ·
  <code>/research-harness-audit</code> ·
  <code>/research-harness-clean</code> ·
  <code>/research-harness-plan</code> ·
  <code>/research-harness-work</code> ·
  <code>/research-harness-review</code> ·
  <code>/research-harness-release</code>
</p>

<p align="center">
  <img alt="Status" src="https://img.shields.io/badge/status-research--harness-blue">
  <img alt="Raw data" src="https://img.shields.io/badge/raw%20data-read--only-critical">
  <img alt="Evidence" src="https://img.shields.io/badge/evidence-required-success">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-lightgrey">
</p>

---

## 这是什么？

**Claude Code Research Harness** 是一个面向 Claude Code 的实证研究执行框架。

它不是一组 prompt，也不是一个普通 workflow，而是一个 **Harness**：一套由规则、文件、检查点和证据要求组成的受控研究环境。它把 AI 智能体约束在可复现、可审计、可追踪的研究流程中。

普通用法是直接问智能体：

> “帮我分析这个数据。”

Claude Code Research Harness 的用法是让智能体在制度化环境里工作：

> “只读审查原始数据，不要修改。  
> 先生成清洗计划。  
> 再写可复现脚本。  
> 保存日志。  
> 核验每一个数字。  
> 一旦证据链断裂，就停止。”

核心规则很简单：

> **No script, no log, no claim.**  
> **没有脚本，没有日志，就没有结论。**

---

## 实证研究中的 Harness 和软件开发中的 Harness 有什么不同？

在软件开发和所谓 **Vibe coding** 语境中，Harness 通常指的是把 AI 编程智能体约束在一套工程化流程里：先写需求规格，再拆分任务，再修改代码，再运行测试，最后通过 review 和 release 检查。它解决的是一个核心问题：**不要让 Agent 只是凭感觉写代码，而要让每一次修改都能被测试、回滚和验收。**

Claude Code Research Harness 继承了这个思想，但把对象从“软件代码”换成了“实证研究”。在研究场景里，真正危险的往往不是代码语法错误，而是样本构造不透明、数据清洗不可追溯、合并键错误、回归结果无法复现、因果表述超过识别设计、以及正文数字找不到对应日志。因此，Research Harness 不是只要求 Agent “代码能跑”，而是要求它证明：

- 原始数据没有被修改；
- 清洗和合并过程有脚本、有日志、有报告；
- 样本限制、变量构造和模型设定与研究规格说明一致；
- 每一个表格、图形和关键数字都能追溯到可运行脚本；
- 每一个因果声明都经过识别策略审查；
- 如果数据或设计不支持某个结论，Agent 必须停止，而不是编造一个看似合理的结果。

因此，软件开发中的 Harness 更像是 **Coding Harness**：它关心代码变更、测试通过和 release readiness。Claude Code Research Harness 则是 **Research Harness**：它关心研究问题、数据来源、样本构造、识别可信度、结果复现和证据链完整性。

它与 Vibe Research 的关系也类似。Vibe research 强调用自然语言驱动研究代码生成，让研究者可以更快地把想法变成脚本、表格和图形。但如果只有 Vibe，没有 Harness，Agent 很容易把“看起来完成了”误当成“真的可复现”。Research Harness 的作用，就是在 Vibe Research 之外加上一层研究制度：允许研究者用自然语言推进工作，但要求每一步都留下可检查的证据。

简单说：

> **Research Harness 让 Agent 更负责任地产生研究证据。**

或者更直接地说：

> 软件 Harness 约束 Agent 写代码。  
> Research Harness 约束 Agent 做研究。  
> 前者追求“代码通过测试”，后者追求“结论经得起追溯”。


---

## 为什么需要这个框架？

AI 智能体已经能帮助研究者写代码、清洗数据、跑模型和生成表格。但如果没有结构性约束，实证研究中的 agent work 很容易出现风险。

常见问题包括：

- 同一个分析跑了两遍，但样本不一致；
- 正文里的系数是手动复制的，后来和表格对不上；
- 因果表述超过了识别策略实际能支撑的范围；
- 清洗数据时悄悄修改了原始文件；
- merge 失败却被总结成“分析已完成”；
- 脚本无法复现论文最终结果；
- 日志缺失，数字来源无法追溯。

Claude Code Research Harness 把这些风险转化为显式检查点：

- 原始数据受到保护；
- 每一次清洗决策都必须留痕；
- 每一次合并都必须诊断；
- 每个分析任务都必须有脚本、日志、输出路径和状态标记；
- 每一个因果声明都必须经过识别策略审查；
- 每一个发布包都必须包含完整证据链。

这就是 AI 助手和可审计研究智能体的区别。

---

## 七阶段研究生命周期

| 阶段 | 命令 | Harness 强制执行什么 |
|---:|---|---|
| 1 | `/research-harness-setup` | 初始化研究合同、文件夹结构和原始数据保护规则。 |
| 2 | `/research-harness-audit` | 只读审查原始数据：文件、变量、缺失值、ID、单位和可行性。 |
| 3 | `/research-harness-clean` | 编写并运行可复现的数据清洗、变量协调、reshape 和 merge 脚本。 |
| 4 | `/research-harness-plan` | 根据研究规格、数据审查和清洗后数据结构生成可执行分析计划。 |
| 5 | `/research-harness-work` | 执行已批准的分析任务，并在标记完成前核验脚本、日志和输出。 |
| 6 | `/research-harness-review` | 审查识别策略、模型设定、样本构造、数字一致性和因果表述。 |
| 7 | `/research-harness-release` | 打包复制档案：脚本、日志、输出、报告和复现说明。 |

你可以走完整生命周期，也可以只调用其中一个模块。

---

## 模块化使用场景

你**不需要每次都运行完整流程**。这个框架支持从中间阶段进入。

| 你想做什么 | 使用命令 |
|---|---|
| 只想检查一个新数据集，不修改它 | `/research-harness-audit` |
| 清理一个混乱的调查数据文件 | `/research-harness-audit` → `/research-harness-clean` |
| 合并个人、家庭、社区和政策时间文件 | `/research-harness-clean` |
| 把一个研究想法变成可执行的实证计划 | `/research-harness-setup` → `/research-harness-plan` |
| 只运行已批准的回归、表格和图形任务 | `/research-harness-work <task-id>` |
| 检查已有结果是否可信 | `/research-harness-review` |
| 投稿前整理复制包 | `/research-harness-release` |

Harness 支持局部进入，但每个命令都会提示：如果跳过前序阶段，会损失哪些检查、增加哪些风险。

例如，`/research-harness-clean` 可以单独使用，但更安全的最小路径是：

```text
/research-harness-audit
/research-harness-clean
```

如果 ID、缺失值编码、日期、单位或合并键还不清楚，不要盲目清洗数据。

---

## 快速开始

### 1. 克隆仓库并用 Claude Code 打开

```bash
git clone https://github.com/maxwell2732/claudecode-research-harness-workflow
cd claudecode-research-harness-workflow
claude
```

### 2. 初始化研究项目

```text
/research-harness-setup
```

Harness 会创建或更新：

```text
study_spec.md
analysis_plan.md
data/raw/READONLY.md
data/intermediate/
data/processed/
scripts/
logs/
output/
reports/
```

### 3. 填写研究合同

编辑 `study_spec.md`。

至少需要定义：

- 研究问题；
- 数据位置和数据字典；
- 观测单位；
- 结果变量、处理/暴露变量、控制变量；
- 样本限制；
- 识别策略；
- 预期表格和图形。

后续任何关于结果变量、样本限制、估计量或识别策略的修改，都应该被视为研究设计变更，而不是悄悄改代码。

### 4. 审查原始数据

```text
/research-harness-audit
```

这一阶段只读，不修改任何原始数据。它检查 `data/raw/` 并生成：

```text
reports/data_audit_report.md
```

数据审查包括：

- 文件清单；
- 变量、类型、缺失值、取值范围；
- 候选 ID 变量和时间变量；
- 重复键检查；
- 单位和编码不一致问题；
- 可能的合并键；
- 当前数据是否支持拟定研究设计。

如果数据不能支撑研究设计，Harness 会停止并报告不可行原因。

### 5. 清洗和合并数据

```text
/research-harness-clean
```

清洗阶段必须生成证据链：

```text
reports/data_cleaning_plan.md
scripts/clean_*.R | scripts/clean_*.do | scripts/clean_*.py
logs/clean_YYYYMMDD.log
reports/data_cleaning_report.md
reports/merge_report.md
data/intermediate/
data/processed/
```

每一次 drop、recode、reshape、merge 和派生变量构造都必须记录。

每一次 merge 必须报告：

- 合并键；
- 合并前行数；
- 合并后行数；
- 匹配和未匹配数量；
- 重复键诊断；
- 变量冲突；
- 尚未解决的合并问题。

如果合并键不明确，Harness 必须停止并向研究者确认。

### 6. 生成分析计划

```text
/research-harness-plan
```

这个阶段把研究合同和数据报告转化为可执行任务：

- 描述性统计；
- 主模型；
- 稳健性检验；
- 异质性分析；
- 表格和图形；
- 脚本路径；
- 日志路径；
- 输出路径；
- 完成标准；
- 状态标记。

研究者批准 `analysis_plan.md` 后，才能进入分析执行阶段。

### 7. 执行已批准任务

```text
/research-harness-work 1.1
/research-harness-work 2
/research-harness-work all
```

一个任务只有在满足以下条件时才能标记为 `cc:done`：

- 脚本存在；
- 脚本已经运行；
- 日志存在；
- 预期输出存在；
- 证据路径已经写入 `analysis_plan.md`。

如果任务反复失败，它会被标记为 `cc:blocked`。Harness 必须报告失败原因，而不是编造输出。

### 8. 结果报告前审阅

```text
/research-harness-review
```

审阅阶段检查：

- 估计量是否匹配研究设计；
- 样本限制是否与 `study_spec.md` 一致；
- N、系数、标准误、p 值、表格和图形是否能追溯到日志或输出；
- 因果语言是否被识别策略支持；
- 清洗和合并报告是否完整；
- 原始数据是否保持未修改。

审阅结论有三种：

| 结论 | 含义 |
|---|---|
| `APPROVE` | 证据链足够，可以发布。 |
| `REQUEST_CHANGES` | 仍有重要问题，需要修改后重新审阅。 |
| `BLOCK` | 存在严重失败，例如数字不可验证或因果声明无支撑。 |

### 9. 打包复制档案

```text
/research-harness-release
```

只有在审阅结论为 `APPROVE` 后，才允许 release。

复制包包含：

- 最终版 `study_spec.md`；
- 最终版 `analysis_plan.md`；
- 数据审查、清洗、合并、审阅和可复现性报告；
- 脚本；
- 日志；
- 表格；
- 图形；
- 已核验和未核验声明清单；
- 分步骤复现说明。

未经明确批准，不得把机密原始数据放入 release package。

---

## 项目结构

```text
your-project/
├── study_spec.md
├── analysis_plan.md
├── data/
│   ├── raw/
│   │   └── READONLY.md
│   ├── intermediate/
│   └── processed/
├── scripts/
├── analysis/
│   └── <stage>/
│       ├── scripts/
│       ├── output/
│       └── logs/
├── output/
│   ├── tables/
│   └── figures/
├── logs/
├── reports/
│   ├── data_audit_report.md
│   ├── data_cleaning_plan.md
│   ├── data_cleaning_report.md
│   ├── merge_report.md
│   ├── review_report.md
│   └── reproducibility_report.md
└── release/
```

---

## 核心文件

| 文件 | 作用 |
|---|---|
| `study_spec.md` | 研究合同：问题、数据、设计、变量、样本和预期产出。 |
| `analysis_plan.md` | 任务台账：任务、路径、证据、完成标准和状态标记。 |
| `reports/data_audit_report.md` | 原始数据结构和研究可行性的只读证据。 |
| `reports/data_cleaning_plan.md` | 经研究者批准的数据清洗和合并计划。 |
| `reports/data_cleaning_report.md` | recode、filter、派生变量和样本变化的证据。 |
| `reports/merge_report.md` | 每一次 merge 的诊断和冲突解决记录。 |
| `reports/review_report.md` | 对识别策略、模型匹配、数字准确性和研究声明的独立审阅。 |
| `reports/reproducibility_report.md` | 最终结果的复现说明和证据索引。 |

---

## 任务状态标记

| 标记 | 含义 |
|---|---|
| `cc:todo` | 尚未开始。 |
| `cc:wip` | 正在进行。 |
| `cc:done` | 已完成，且脚本、日志、输出和证据路径齐全。 |
| `cc:blocked` | 无法继续，原因已记录。 |
| `cc:infeasible` | 数据或设计不支持该任务，停止原因已记录。 |

---

## 研究诚信规则

完整规则见 [`docs/INTEGRITY-RULES.md`](docs/INTEGRITY-RULES.md)。

简版如下：

| 规则 | 要求 |
|---|---|
| 保护原始数据 | 永远不要修改 `data/raw/`。 |
| 不编造证据 | 不得捏造结果、样本量、系数、引用或稳健性检验。 |
| 没有日志就没有结论 | 没有脚本和日志，不得声称分析已经运行。 |
| 不静默改变样本 | 每一次 drop、filter 和 recode 都必须记录。 |
| 每次合并都要诊断 | 报告合并键、行数、匹配率、重复键和变量冲突。 |
| 使用相对路径 | 脚本中不得使用机器特定的绝对路径。 |
| 标注因果声明 | 使用 `[descriptive]`、`[associational]`、`[quasi-experimental]` 或 `[experimental]`。 |
| 不可行时停止 | 如果数据不能支撑设计，报告不可行原因，不得发明变通方法。 |
| 合并键不清楚就询问 | 不得在合并键模糊时靠猜测继续。 |

---

## 示例项目

见 [`examples/README.md`](examples/README.md)。

### `examples/basic-data-cleaning/`

一个小型合成家户调查数据，内置典型数据质量问题：

- 缺失 ID；
- `-9` 缺失值编码；
- 异常家庭规模；
- 无效地区编码；
- 有记录的样本丢弃过程。

覆盖命令：

```text
/research-harness-audit
/research-harness-clean
```

### `examples/econometrics-replication/`

一个带双重差分设计的合成面板数据复制项目：

- household-year 面板；
- 政策时间文件；
- 必需的 merge 诊断；
- 双向固定效应模型；
- 剔除早期实施地区的稳健性检验；
- 完整七阶段生命周期。

覆盖命令：

```text
/research-harness-setup
/research-harness-audit
/research-harness-clean
/research-harness-plan
/research-harness-work
/research-harness-review
/research-harness-release
```

---

## 适用场景

| 场景 | 适配程度 |
|---|---|
| 经济学和应用社会科学 | 非常适合 |
| 健康经济学和公共卫生 | 非常适合 |
| 教育学、政治学、社会学 | 非常适合 |
| 面板数据、调查数据、行政数据 | 非常适合 |
| DiD、IV、RD、事件研究、RCT | 非常适合 |
| 数据清洗和多源数据合并 | 非常适合 |
| 复制包和投稿前核查 | 非常适合 |
| 可复现实证研究教学 | 非常适合 |
| 没有研究设计需求的纯机器学习 | 部分适合 |

---

## 设计哲学

Research Agent Harness 遵循四个原则。

**1. 数据约束研究问题。**  
智能体不得提出数据无法支撑的研究设计。

**2. 确定性工作必须留下确定性证据。**  
清洗、合并、估计和制表都必须有脚本、日志和输出。

**3. 人类审查门槛是系统的一部分。**  
研究设计、样本限制和因果声明的关键变更需要研究者批准。

**4. 失败也是有效的研究输出。**  
如果数据不足、前提失败或证据链断裂，正确做法是停止，并说明原因。

---

## 致谢

本仓库的 Harness 框架结构（权限模型、工作流命令、研究诚信规则）基于 [Chachamaru127/claude-code-harness](https://github.com/Chachamaru127/claude-code-harness) 开发，在此对原作者的开创性工作表示感谢。本仓库在其基础上针对实证研究场景进行了定制，并加入了 CHNS 数据清理与合并流水线、数据保护规则和任务完成报告机制。

---

## License

MIT — see [`LICENSE.md`](LICENSE.md).
