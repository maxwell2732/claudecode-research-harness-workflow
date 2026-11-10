# 任务报告：恢复 GitHub ZIP 下载中的配置文件

日期：2026-11-10

## 任务背景

从 GitHub 页面下载本仓库 ZIP 后，解压目录中没有 `CLAUDE.md`。排查发现两个原因：

- `.gitattributes` 自初始提交 `46f32fd` 起将 `CLAUDE.md`、`AGENTS.md`、`.claude/` 标记为 `export-ignore`，GitHub 生成 ZIP 时跳过这些路径。
- `AGENTS.md` 被 `.gitignore` 忽略，从未进入任何提交，而 `CLAUDE.md` 首句要求先读取它。

用户决定将 `AGENTS.md` 合并进 `CLAUDE.md` 并删除，同时上传数据写保护钩子，推送到 `main`。

## 执行过程

1. 将 `AGENTS.md` 全部内容合并为 `CLAUDE.md` 第 0 节（运行模型），删除原有的引用句。原第 1 至 10 节编号不变。
2. 修改 `.gitattributes`，移除 `CLAUDE.md`、`AGENTS.md`、`.claude/` 的 `export-ignore`。
3. 修改 `.gitignore`，新增 `!.claude/hooks/`，使钩子可被跟踪。`/AGENTS.md` 的忽略规则保留，防止 `scripts/setup-hook.sh` 自动生成的文件被误传。
4. 更新 `IMPLEMENTATION_GUIDE.md` 与 `docs/INTEGRITY-RULES.md` 中对 `AGENTS.md` 的引用。
5. 删除本地 `AGENTS.md`，仅按文件名暂存本次涉及的文件，提交为 `15382a4` 并推送到 `origin/main`。同次推送包含此前未推送的 `b98b481` 与 `f1b75d8`。
6. 重新下载线上 ZIP，校验结果写入日志。

本次未修改数据保护规则，未运行任何数据脚本，未读写 `data/raw/`。

## 关键结果

以下数字均来自验证日志：

| 检查项 | 结果 |
|--------|------|
| ZIP 对应提交 | `15382a4` |
| ZIP 内文件数 | 422 |
| 提交 `15382a4` 时跟踪的文件数 | 422 |
| ZIP 内 `CLAUDE.md` 与仓库版本比对 | 完全一致 |
| ZIP 内 `.claude/hooks/protect-files.sh` 与仓库版本比对 | 完全一致 |
| ZIP 根目录 `AGENTS.md` 数量 | 0 |
| 受保护数据目录及数据格式在 Git 中的跟踪数量 | 0 |
| ZIP 中命中数据或私有文件筛选规则的条目 | 1，经复核为模板文件，属误报 |

## 数据质量说明

本任务只涉及仓库配置，未处理任何数据。误报条目为 `templates/claude/settings.local.json.template`，自初始提交起存在，经检查不含个人路径或邮箱。`.claude/settings.local.json` 含本机路径和个人权限，仍被忽略，未上传。

## 输出文件清单

提交 `15382a4` 的改动（行数来自 `git show --stat`，记录于日志）：

| 路径 | 改动 |
|------|------|
| `.claude/hooks/protect-files.sh` | 新增，27 行，权限 100755 |
| `.gitattributes` | 4 行改动 |
| `.gitignore` | 3 行改动 |
| `CLAUDE.md` | 94 行改动 |
| `IMPLEMENTATION_GUIDE.md` | 2 行改动 |
| `docs/INTEGRITY-RULES.md` | 2 行改动 |

本文件也会进入后续提交，因此最新 ZIP 的文件数会比上表验证值多 1。

## 证据链

| 结论 | 证据 |
|------|------|
| ZIP 内容及比对结果 | 验证命令输出 → `logs/repo_config_zip_verify_20261110.log` |
| 排除规则的引入时间 | `git log -- .gitattributes` → 提交 `46f32fd` |
| `AGENTS.md` 从未被提交 | `git log --all -- AGENTS.md` 无输出 |
| 本次改动内容 | `git show 15382a4` |

## 待办/遗留问题

- 仓库内仍有上游模板留下的 Codex 相关内容，包括钩子脚本和 `bin/` 下的编译文件。如需清理，应单独逐项测试。
- `.codex`、`.agents` 为本机空目录，未上传，创建来源无法从 Git 确认。
- 根目录 `settings.json` 引用了 `protect-files.sh`，但 Claude Code 项目设置通常读取 `.claude/settings.json`。本次未测试下载者环境中该钩子能否自动触发。
- 本地仍有与本任务无关的未跟踪文件（如 `reports/proof_*`、`tmp-litcheck/`），未提交。
