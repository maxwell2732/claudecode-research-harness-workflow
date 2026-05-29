# Version File Detection & Update

Details on detection and rewriting for the 4 types of version files handled by this skill.

## Priority order

```
VERSION  >  package.json  >  pyproject.toml  >  Cargo.toml
```

When multiple exist in a project, the higher priority one is treated as the source of truth.
Normally only one of them is expected to exist.

## Detection and reading

### VERSION (standalone file)

```bash
cat VERSION | tr -d '\n'
```

One line only, semantic version (`x.y.z`).

### package.json (npm)

```python
import json
with open("package.json") as f:
    data = json.load(f)
current_version = data["version"]
```

Top-level `"version": "x.y.z"`.

### pyproject.toml (Python)

Supports both PEP 621 compliant (`[project]`) and Poetry (`[tool.poetry]`):

```python
import tomllib
with open("pyproject.toml", "rb") as f:
    data = tomllib.load(f)

if "project" in data and "version" in data["project"]:
    current_version = data["project"]["version"]
elif "tool" in data and "poetry" in data["tool"]:
    current_version = data["tool"]["poetry"]["version"]
else:
    raise RuntimeError("version not found in pyproject.toml")
```

**Note**: In `pyproject.toml`, there is a setting to read version from a separate file (e.g., `_version.py`) such as `dynamic = ["version"]`. This skill does not support that case (switch to static version beforehand, or use a `VERSION` file).

### Cargo.toml (Rust)

```python
import tomllib
with open("Cargo.toml", "rb") as f:
    data = tomllib.load(f)
current_version = data["package"]["version"]
```

## Rewriting

Rewriting is done by "minimum field replacement." Regex substitution is recommended to avoid breaking formatting style or comments:

### VERSION

```bash
echo "$NEW_VERSION" > VERSION
```

### package.json

If `jq` is available:
```bash
jq --arg v "$NEW_VERSION" '.version = $v' package.json > /tmp/package.json && mv /tmp/package.json package.json
```

If `jq` is not available, use Python:
```python
import json
with open("package.json", "r") as f:
    data = json.load(f)
data["version"] = NEW_VERSION
with open("package.json", "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
```

### pyproject.toml / Cargo.toml

Since we don't want to break the TOML writing style, replace only the first `version = "..."` line with regex:

```python
import re
with open("pyproject.toml", "r") as f:
    content = f.read()

# Replace version within [project] or [tool.poetry] section
section_pattern = None
if re.search(r"^\[project\]", content, re.M):
    section_pattern = r"(\[project\][^\[]*?version\s*=\s*\")[^\"]+(\")"
elif re.search(r"^\[tool\.poetry\]", content, re.M):
    section_pattern = r"(\[tool\.poetry\][^\[]*?version\s*=\s*\")[^\"]+(\")"

new_content = re.sub(
    section_pattern,
    rf"\g<1>{NEW_VERSION}\g<2>",
    content,
    count=1,
    flags=re.S,
)
with open("pyproject.toml", "w") as f:
    f.write(new_content)
```

Same for Cargo.toml (within `[package]` section):

```python
section_pattern = r"(\[package\][^\[]*?version\s*=\s*\")[^\"]+(\")"
```

## Handling sub-packages

Cases where multiple version files exist in a monorepo (e.g., npm workspaces) are out of scope for this skill.
Design is to treat only the root's 1 file as the source of truth.
To synchronize multiple packages, please build a dedicated release orchestrator separately.

## Unsupported version expressions

The following are not supported. Please normalize to SemVer format beforehand:

- `v1.0.0` (leading `v` not accepted; only tags have the `v` prefix)
- `1.0.0-alpha.1` (pre-release suffix is retained but not bumped)
- `1.0.0+build.1` (build metadata is retained)
- Calendar versioning (`2024.01`)
