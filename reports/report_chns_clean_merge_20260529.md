# CHNS 数据清理与合并任务报告

**任务编号：** chns-clean-merge  
**完成日期：** 2026-05-29  
**执行人：** Claude Code (Analyst)  
**日志目录：** `logs/0*.log`

---

## 一、任务背景

用户将中国健康与营养调查（CHNS，China Health and Nutrition Survey）原始数据放置于 `input/data/chns_raw/`，共 19 个模块、约 2 GB 的 `.sas7bdat` / `.dta` 格式文件，波次覆盖 1989–2015 年（共 10 波）。

**任务目标：**
1. 对所有原始文件进行审计（行数、列数、缺失率）
2. 以个人×波次为单位构建全量合并面板
3. 生成最终 CSV 和 codebook，全程留存可追溯的日志与合并报告
4. 所有原始数据不得被修改或上传至 GitHub

**技术环境：**
- Python 3.9（`C:\Users\zhuch\.conda\envs\snipar_env\python.exe`）
- 依赖包：pandas 2.3.3、pyreadstat 1.2.8、pyarrow 21.0.0

---

## 二、执行过程

### 步骤 0：目录脚手架（`00_scaffold.py`）
创建 `data/intermediate/`、`data/processed/`、`scripts/`、`logs/`、`reports/` 目录，初始化 `reports/merge_report.md`。

### 步骤 1：数据审计（`01_audit.py`）
遍历 `input/data/chns_raw/` 下所有 `.sas7bdat` 和 `.dta` 文件，逐一记录行数、列数、各变量缺失率及变量标签，输出 `reports/audit_report.md`。

**扫描结果（来源：`logs/01_audit.log`）：** 涵盖 19 个模块下的全部数据文件。

### 步骤 2：构建个人×波次脊柱（`02_spine.py`）
以 `surveys_pub_12.sas7bdat` 为基础框架，依次合并 `mast_pub_12.sas7bdat`（个人基本信息）和 `rst_12.sas7bdat`（名册）。

| 文件 | 原始行数 | 列数 |
|------|---------|------|
| surveys_pub_12 | 143,564 | 19 |
| mast_pub_12 | 44,453 | 10 |
| rst_12 | 180,582 | 67 |

**脊柱输出（来源：`logs/02_spine.log`）：** `data/intermediate/spine.parquet`，143,564 行 × 87 列，行数全程稳定。

### 步骤 3：合并个人×波次模块（`03_individual_modules.py`）
将 16 个以 IDIND+WAVE 为键的模块逐一 left-join 到脊柱。各模块行数见下表（来源：`logs/03_individual_modules.log`）：

| 模块文件 | 原始行数 | 前缀 |
|---------|---------|------|
| pexam_pub_12 | 126,408 | pe_ |
| pact_12 | 125,740 | pa_ |
| pstress_12 | 12,865 | ps_ |
| educ_12 | 134,256 | educ_ |
| hlth_12 | 127,761 | hlth_ |
| ins_12 | 128,728 | ins_ |
| indinc_10 | 88,166 | inc_ |
| wages_12 | 62,029 | wage_ |
| jobs_13 | 120,484 | job_ |
| subi_12 | 14,834 | subi_ |
| timea_12 | 123,364 | time_ |
| media_00 | 7,283 | media_ |
| en_00 | 1,109 | cal_ |
| c12diet | 102,575 | diet_ |
| emw_12 | 26,616 | emw_ |

**首轮跳过的文件**（后续已修复）：
- `medsv_00`：无 IDIND，实为家户级 → 移至步骤 4
- `relationmast_pub_00`：无 IDIND，为双向关系表 → 步骤 5 聚合处理

**步骤 3 输出（来源：`logs/03_individual_modules.log`）：** `panel_individual.parquet`，143,564 行 × 851 列。

### 步骤 4：合并家户×波次模块（`04_household_modules.py`）
将 9 个以 HHID+WAVE（或 COMMID+WAVE）为键的模块 m:1 left-join，行数全程不变（来源：`logs/04_household_modules.log`）：

| 模块文件 | 原始行数 | 合并键 |
|---------|---------|--------|
| hhinc_10 | 43,671 | HHID+WAVE |
| asset_12 | 44,521 | HHID+WAVE |
| careh_12 | 3,172 | HHID+WAVE |
| subh_12 | 10,891 | HHID+WAVE |
| oinc_12 | 22,985 | HHID+WAVE |
| medsv_00 | 44,995 | HHID+WAVE |
| farmh_12 | 16,529 | HHID+WAVE |
| gardh_12 | 18,334 | HHID+WAVE |
| fishh_12 | 816 | HHID+WAVE |
| urban_11 | 2,207 | COMMID+WAVE |

**步骤 4 输出（来源：`logs/04_household_modules.log`）：** `panel_with_household.parquet`，143,564 行 × 1,291 列。

### 步骤 5：聚合子项目表（`05_aggregate_items.py`）
将 15 个子项目表（食物级、作物级、托育子女级、关系对级等）聚合至 HHID×WAVE 或 IDIND×WAVE 级别，共生成 16 张聚合 parquet（来源：`logs/05_aggregate_items.log`）。

**特殊处理的文件：**

| 文件 | 原始键 | 处理方式 |
|------|--------|---------|
| birth_12（63,846 行）| IDIND_M + IDIND_C + WAVE | IDIND_M 重命名为 IDIND，按 IDIND+WAVE 统计出生次数及存活数 |
| preg_12（4,126 行）| IDIND_M + WAVE | IDIND_M 重命名为 IDIND，按 IDIND+WAVE 统计妊娠次数 |
| birthmast_pub_12（14,656 行）| IDIND_M + IDIND_C | IDIND_M 重命名为 IDIND，按母亲统计子女总数及性别组成 |
| relationmast_pub_00（82,734 行）| IDIND_1 + IDIND_2 | 从 IDIND_1 视角聚合，统计关系条数及众数关系类型 |
| nutr1/2/3（合计约 400 万行）| HHID+FOODCODE+WAVE | 按 HHID+WAVE 汇总三日总消费量（V22）及人均日消费量（V23） |

### 步骤 6：合并全部聚合表（`06_merge_aggregates.py`）
将 16 张聚合表按对应键（HHID+WAVE 或 IDIND+WAVE 或 IDIND）依次 left-join 到面板，行数全程不变（来源：`logs/06_merge_aggregates.log`）。

**步骤 6 输出：** `panel_full.parquet`，143,564 行 × 1,462 列。

### 步骤 7：导出最终 CSV 与 codebook（`07_export_csv.py`）
从 `panel_full.parquet` 导出 CSV，并自动构建 codebook（含变量名、来源模块、dtype、缺失率、极值、均值等）（来源：`logs/07_export_csv.log`）。

---

## 三、关键结果

> 以下所有数字均来自 `logs/07_export_csv.log`（最后一次运行，2026-05-29 17:57）。

| 指标 | 数值 |
|------|------|
| 最终行数 | **143,564** |
| 最终列数 | **1,462** |
| 唯一个人数（IDIND） | **38,536** |
| 唯一家户数（HHID） | **9,696** |
| 波次范围 | **1989–2015（10 波）** |
| 整体缺失率 | **78.19%** |
| Merge 步骤数 | **55+**（见 `reports/merge_report.md`） |

---

## 四、数据质量说明

### 缺失率说明
整体缺失率 78.19% 属于 CHNS 面板的正常现象：不同模块仅覆盖特定波次或特定人群（如 `emw_12` 仅限已婚妇女，`en_00` 仅 1 波次的子样本），宽表合并后大量单元格为 NA 是预期结果。

### 重复键处理
以下文件在合并前存在重复键，已取第一条记录（记录于对应日志 WARNING 行）：
- `indinc_10`：1 条重复
- `wages_12`：3,120 条重复（同一人同一波次多份工作记录）
- `asset_12`：205 条重复
- `oinc_12`：56 条重复

### 变量命名冲突
各模块与脊柱共享的地理/标识变量（HHID、COMMID、T1–T5、LINE）在合并前已从右表删除，以脊柱的值为准。

---

## 五、输出文件清单

| 文件路径 | 行数 | 列数 | 说明 |
|---------|------|------|------|
| `data/processed/chns_merged_panel.csv` | 143,564 | 1,462 | 全量个人×波次面板 |
| `data/processed/chns_codebook.csv` | 1,462 | 13 | 变量元数据 |
| `data/intermediate/spine.parquet` | 143,564 | 87 | 脊柱（ID+名册+调查框架） |
| `data/intermediate/panel_individual.parquet` | 143,564 | 851 | 合并个人模块后 |
| `data/intermediate/panel_with_household.parquet` | 143,564 | 1,291 | 合并家户模块后 |
| `data/intermediate/panel_full.parquet` | 143,564 | 1,462 | 合并全部聚合表后 |
| `data/intermediate/agg_*.parquet`（16 个）| — | — | 各子项目聚合表 |
| `reports/audit_report.md` | — | — | 全部原始文件的列级审计 |
| `reports/merge_report.md` | — | — | 每步合并的行数与匹配率记录 |
| `logs/0[0-7]_*.log` | — | — | 每个脚本的完整运行日志 |

所有数据文件已通过 `.gitignore` 封锁，不会上传至 GitHub。

---

## 六、证据链

| 结果 | 脚本 | 日志 |
|------|------|------|
| 脊柱 143,564 行 × 87 列 | `scripts/02_spine.py` | `logs/02_spine.log` |
| 个人模块合并后 851 列 | `scripts/03_individual_modules.py` | `logs/03_individual_modules.log` |
| 家户模块合并后 1,291 列 | `scripts/04_household_modules.py` | `logs/04_household_modules.log` |
| 16 张聚合表 | `scripts/05_aggregate_items.py` | `logs/05_aggregate_items.log` |
| 最终面板 1,462 列 | `scripts/06_merge_aggregates.py` | `logs/06_merge_aggregates.log` |
| 最终 CSV 143,564×1,462、缺失率 78.19% | `scripts/07_export_csv.py` | `logs/07_export_csv.log` |

---

## 七、数据保护措施

本次任务同步完成以下数据保护配置：

1. **`.gitignore`** 新增封锁规则，覆盖 `input/data/`、`data/raw/`、`data/intermediate/`、`data/processed/`、`*.sas7bdat`、`*.dta`、`*.parquet` 等所有含调查微观数据的路径
2. **`CLAUDE.md §7`**（原 §6）明确：Claude Code 不得对任何数据目录执行 `git add`、commit 或 push，若用户要求须解释数据保护原因并拒绝

---

## 八、待办 / 遗留问题

1. **变量标签缺失**：原始 `.sas7bdat` 文件的变量标签在 pyreadstat 读取时部分为空（SAS 元数据未完整嵌入），`codebook.csv` 中 `variable_label` 列大量为空——需后续参照 PDF codebook 手动补充核心变量标签
2. **birth_12 / preg_12 的子女视角**：本次仅从母亲（IDIND_M）视角聚合出生和妊娠信息；若需从子女（IDIND_C）视角将出生年份等信息挂接到子女记录，需单独处理
3. **营养数据波次缺口**：`nutr1/2/3` 仅覆盖 2015 年之前波次（Master_Nutrition_201410），若需 2015 波次营养数据需确认是否有补充文件
4. **重复 wages_12 键**：3,120 条重复记录（同人同波次多份工作）目前取第一条；若需保留多工作信息应改为宽表展开或另建就业子表
