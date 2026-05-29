# Research Agent Harness（研究智能体执行框架）

**定义研究问题 → 审查数据 → 清洗数据 → 制定计划 → 执行分析 → 审阅结果 → 发布复制包**

*一个为实证研究智能体设计的受控执行环境*

---

## 为什么需要这个框架？

用 AI 辅助做实证研究，在没有结构约束的情况下很容易出现以下问题：

- 同一份分析用了不同的样本跑了两遍，数字不一致
- 正文里的系数和表格里的数字对不上，因为是手动输入的
- 因果性表述超出了识别策略实际能支撑的范围
- 项目文件夹里的脚本无法复现最终论文的结果

**Research Agent Harness** 把这些问题纳入一套可重复、有证据追踪的操作流程。安装之后，工作方式从"让智能体分析数据"变成：

1. 编写研究规格说明书，设定数据保护规则
2. 在不修改原始数据的前提下审查数据
3. 生成并运行可追溯的数据清洗和合并脚本
4. 根据规格说明和审查结果生成可执行分析计划
5. 运行分析脚本，每个任务完成前必须验证日志文件存在
6. 独立审阅识别策略、模型设定和数字准确性
7. 将经过核验的证据打包为可复制档案

**每一个数字都必须能追溯到脚本、日志和输出文件。追溯不到，框架就停止运行。**

---

## 七阶段研究工作流

| 阶段 | 命令 | 框架做什么 |
|---|---|---|
| 1 | `/research-harness-setup` | 创建 `study_spec.md`、`analysis_plan.md`、文件夹结构和数据保护规则 |
| 2 | `/research-harness-audit` | 只读审查原始数据：变量、缺失值、ID、单位、可行性评估 |
| 3 | `/research-harness-clean` | 编写并运行可复现的清洗/合并脚本，保存处理后数据集和清洗日志 |
| 4 | `/research-harness-plan` | 根据研究规格说明、审查结果和清洗后数据结构生成可执行的 `analysis_plan.md` |
| 5 | `/research-harness-work` | 运行分析脚本；每个任务标记完成前必须确认日志文件存在 |
| 6 | `/research-harness-review` | 独立核查识别策略可信度、模型设定、数字准确性和因果声明强度 |
| 7 | `/research-harness-release` | 打包复制档案——脚本、日志、表格、图形和可复现性报告 |

---

## 快速开始

### 第一步：安装

将本仓库克隆到本地，在 Claude Code 中以项目目录为工作目录启动。

```bash
git clone https://github.com/Chachamaru127/claude-code-harness
cd claude-code-harness
claude
```

### 第二步：初始化研究项目

```
/research-harness-setup
```

框架会询问：
- 研究项目名称
- 原始数据路径（可以先填 `unknown`）
- 研究问题（一两句话；可以先填 `unknown`）

完成后会生成：
- `study_spec.md`（研究合同）
- `analysis_plan.md`（任务台账）
- 文件夹结构（见下方）
- `data/raw/READONLY.md`（数据保护说明）

### 第三步：填写研究规格说明书

打开 `study_spec.md`，填写以下内容：

- **研究问题**：主要和次要研究问题
- **识别策略**：设计类型（横截面/面板/DiD/IV/RD/RCT等）、关键假设、识别强度标签
- **数据**：数据文件路径、数据字典、观测单位、地理/时间覆盖范围
- **变量**：结果变量、处理/暴露变量、控制变量（含工具变量）
- **样本限制**：所有纳入/排除标准
- **预期产出**：所有需要生成的表格和图形

**重要**：研究规格说明书的任何修改（样本限制、估计量、结果变量）都需要研究者手动审批，才能继续运行分析脚本。

### 第四步：审查原始数据

```
/research-harness-audit
```

框架会只读地检查 `data/raw/` 下的所有文件，生成 `reports/data_audit_report.md`，包含：

- 文件清单（文件名、大小、格式、行数、列数）
- 变量目录（变量名、类型、缺失值比例、最小值、最大值）
- ID 一致性检查（ID 是否唯一、是否跨文件一致）
- 时间变量检查
- 单位和编码问题（如 `-9` 表示缺失值、日期格式混用等）
- 可行性评估：研究规格说明书中的设计能否用现有数据实现？

**如果可行性评估为"不可行"**，框架会停止并要求修改 `study_spec.md`，不会继续下一步。

### 第五步：填写数据清洗计划

在运行清洗命令前，将 `templates/data_cleaning_plan.md` 复制到 `reports/data_cleaning_plan.md` 并填写：

- 源文件（必须来自 `data/raw/`）
- 目标输出文件（必须写到 `data/processed/` 或 `data/intermediate/`）
- 清洗任务（变量重命名、类型转换、日期解析、缺失值编码、去重检查、单位统一、宽长格转换等）
- 合并任务（合并键、预期匹配率、合并前行数）
- 派生变量定义
- 最终分析就绪数据集名称

**如果合并键不明确**，必须先明确再填写，不能靠猜测。

### 第六步：清洗和合并数据

```
/research-harness-clean
```

框架会根据 `reports/data_cleaning_plan.md` 生成并运行清洗脚本，产出：

- `data/processed/` 下的清洗后数据集
- `logs/clean_YYYYMMDD.log`（所有操作的详细日志）
- `reports/data_cleaning_report.md`（清洗报告，包括每一步丢弃的观测数量和原因）
- `reports/merge_report.md`（每次合并的前后行数、匹配率、重复键诊断）

**每一次丢弃观测都必须记录原因和数量。绝不允许静默丢弃数据。**

### 第七步：生成分析计划

```
/research-harness-plan
```

框架根据 `study_spec.md`、审查报告和清洗报告，生成 `analysis_plan.md`，包含：

- 描述性分析任务
- 主回归任务（含识别策略标签）
- 稳健性检验任务
- 异质性分析任务（如适用）
- 表格和图形任务
- 每个任务的脚本路径、日志路径、输出路径和完成标准（DoD）

**研究者审阅并批准 `analysis_plan.md` 后，才能运行分析脚本。**

### 第八步：执行分析任务

```
/research-harness-work 1.1    # 执行任务 1.1
/research-harness-work 2      # 执行第 2 阶段所有任务
/research-harness-work all    # 执行所有待完成任务
```

每个任务完成后，框架会：
- 确认脚本文件存在
- 确认日志文件存在（脚本确实运行了）
- 确认输出文件存在
- 将证据行（脚本路径、日志路径、输出路径）写入 `analysis_plan.md`
- 将任务状态更新为 `cc:done`

**如果脚本连续失败三次**，框架会停止，将任务标记为 `cc:blocked`，并告知研究者失败原因。绝不允许伪造输出。

### 第九步：审阅研究结果

```
/research-harness-review
```

框架以只读方式（不运行任何代码）审查所有已完成任务，检查：

- **识别策略可信度**：估计量是否与 `study_spec.md` 一致？关键假设是否明确？
- **模型设定一致性**：结果变量、控制变量、样本限制是否与规格说明一致？
- **数字准确性**：每个关键数字（系数、标准误、样本量、p值）是否出现在日志文件中？
- **样本量检查**：分析日志中的 N 是否与清洗报告一致？
- **因果声明强度**：所有因果声明是否标注了识别标签？是否存在夸大因果性的表述？
- **数据清洗完整性**：清洗报告是否通过核验？合并报告是否完整？
- **原始数据完整性**：`data/raw/` 是否未被修改？

审阅结果分三种：

| 结论 | 含义 |
|---|---|
| `APPROVE` | 无严重或重大问题，可以发布 |
| `REQUEST_CHANGES` | 存在重大问题，需要修改后重新审阅 |
| `BLOCK` | 存在严重问题（如数字无法追溯到日志），必须解决后才能发布 |

### 第十步：打包复制档案

```
/research-harness-release
```

**只有审阅结论为 `APPROVE` 时才能运行此命令。**

框架会展示所有待打包文件的清单，并请求研究者确认，然后：

- 创建 `release/` 文件夹
- 将所有脚本、日志、输出、报告复制进去
- 生成 `reports/reproducibility_report.md`（可复现性报告），包含逐步复现说明

---

## 核心文件说明

| 文件 | 用途 | 备注 |
|---|---|---|
| `study_spec.md` | 研究合同：研究问题、识别策略、数据、变量、样本限制、预期产出 | 修改需人工审批 |
| `analysis_plan.md` | 任务台账：各阶段任务、脚本路径、日志路径、输出路径、完成标准、状态标记 | 由框架自动维护 |

### 任务状态标记

| 标记 | 含义 |
|---|---|
| `cc:todo` | 尚未开始 |
| `cc:wip` | 进行中 |
| `cc:done` | 已完成——脚本已运行、日志已存在、输出已核验 |
| `cc:blocked` | 无法继续，原因已记录 |
| `cc:infeasible` | 数据或设计不支持该任务，已记录停止原因 |

---

## 项目文件夹结构

```
your-project/
├── study_spec.md                    # 研究合同（人工审批）
├── analysis_plan.md                 # 任务台账（含状态和证据路径）
├── data/
│   ├── raw/                         # 只读——任何脚本和智能体都不得修改
│   │   └── READONLY.md              # 数据保护说明
│   ├── intermediate/                # 中间数据集（清洗过程中）
│   └── processed/                   # 分析就绪数据集（/research-harness-clean 输出）
├── scripts/                         # 清洗脚本
├── analysis/                        # 按任务组织的脚本和输出
│   └── <stage>/
│       ├── scripts/
│       ├── output/
│       └── logs/
├── output/
│   ├── tables/                      # 表格
│   └── figures/                     # 图形
├── logs/                            # 脚本运行日志
└── reports/
    ├── data_audit_report.md         # 审查报告
    ├── data_cleaning_plan.md        # 清洗计划（研究者填写）
    ├── data_cleaning_report.md      # 清洗报告（框架生成）
    ├── merge_report.md              # 合并报告（每次合并一条）
    ├── review_report.md             # 审阅报告
    └── reproducibility_report.md   # 可复现性报告（发布时生成）
```

---

## 研究诚信规则

完整规则见 [`docs/INTEGRITY-RULES.md`](docs/INTEGRITY-RULES.md)。以下是不可违反的核心规则：

| 规则 | 说明 |
|---|---|
| **绝不修改 `data/raw/`** | 原始数据永远只读，所有转换写到 `data/processed/` 或 `data/intermediate/` |
| **绝不编造数据** | 不得捏造任何结果、数字、引用或稳健性检验 |
| **绝不声称分析已完成** | 没有对应的脚本文件和日志文件，不得声称任务完成 |
| **绝不静默丢弃观测** | 每一次数据过滤都必须记录原因和丢弃数量 |
| **每次合并都必须报告** | 合并前后的行数、匹配率、重复键诊断，缺一不可 |
| **标注所有因果声明** | 使用识别强度标签：`[描述性]` / `[相关性]` / `[准实验: DiD/IV/RD]` / `[实验]` |
| **不可行时停止** | 如果数据不支持设计，停止并报告，不得发明变通方法 |
| **始终使用相对路径** | 脚本中不允许使用绝对路径 |
| **遇到不明确的合并键** | 停止并向研究者确认，不得猜测 |

---

## 模板文件

框架为工作流中的每个文档提供模板：

| 模板 | 使用时机 |
|---|---|
| `templates/study_spec.md` | `/research-harness-setup` — 填写一次，作为研究合同 |
| `templates/analysis_plan.md` | `/research-harness-plan` — 自动根据研究规格生成 |
| `templates/data_audit_report.md` | `/research-harness-audit` 输出 |
| `templates/data_cleaning_plan.md` | 运行 `/research-harness-clean` 前由研究者填写 |
| `templates/data_cleaning_report.md` | `/research-harness-clean` 输出 |
| `templates/merge_report.md` | `/research-harness-clean` 中每次合并生成一份 |
| `templates/review_report.md` | `/research-harness-review` 输出 |
| `templates/reproducibility_report.md` | `/research-harness-release` 输出 |

---

## 示例项目

见 [`examples/README.md`](examples/README.md)，包含两个可直接运行的示例：

### 示例 1：基础数据清洗（`examples/basic-data-cleaning/`）

适合新手熟悉审查和清洗流程。

- 一个 200 行的合成家户调查 CSV
- 内置数据质量问题：缺失 ID（8 条）、收入变量用 `-9` 表示缺失、`hh_size` 存在异常值、超出范围的地区（D 区）
- 预期产出：183 行的清洗后数据集，每一步丢弃都有记录
- 覆盖命令：`/research-harness-audit`、`/research-harness-clean`

### 示例 2：计量经济学复制（`examples/econometrics-replication/`）

覆盖完整七阶段工作流，以双重差分（DiD）设计为例。

- 合成面板数据集（家户 × 年份）+ 政策时间文件，需要合并
- 合并报告：m:1 合并，完整的前后行数、匹配率、重复键诊断
- 主回归：双向固定效应（地区 + 年份），聚类标准误
- 稳健性检验：剔除早期实施地区
- 覆盖命令：全部七个 `/research-harness-*` 命令

---

## 适用场景

| 场景 | 是否适用 |
|---|---|
| 社会科学实证研究（经济学、公卫、教育、政治学） | ✓ |
| 健康经济学和卫生统计 | ✓ |
| 计量经济学模型：DiD、IV、RD、事件研究 | ✓ |
| 数据清洗和多数据源合并 | ✓ |
| 论文复制和可复现性核查 | ✓ |
| 教学用研究工作流演示 | ✓ |
| 纯机器学习建模（无因果推断需求） | 部分适用 |

---

## 许可证

MIT — 详见 [LICENSE.md](LICENSE.md)
