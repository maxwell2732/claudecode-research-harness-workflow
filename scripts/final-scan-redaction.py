#!/usr/bin/env python3
"""scripts/final-scan-redaction.py
Phase 65.3.4 - Layer 3 final scan.

Reads HTML/text from stdin. Detects residual proper-noun-like patterns
(specifically: Katakana 5+ characters in a row) AFTER stripping known
sentinel marks ([Entity] / [REDACTED_*] / [Client_*] / [Person_*] /
[Domain_*]).

Exit:
  0 = no residue
  1 = residue detected (writes 'detected: <token>, source: <line>' to stderr)
"""

import re
import sys


SENTINELS = [
    re.compile(r"\[REDACTED_[A-Za-z0-9_]+\]"),
    re.compile(r"\[Entity\]"),
    re.compile(r"\[Client_[A-Za-z0-9_]+\]"),
    re.compile(r"\[Person_[A-Za-z0-9_]+\]"),
    re.compile(r"\[Domain_[A-Za-z0-9_]+\]"),
]

# 残骸 pattern: カタカナ 5 文字以上連続 (人名 / 社名 / ブランド名の典型)
KATAKANA_RUN = re.compile(r"[ァ-ヶー]{5,}")


def _strip_template_chrome(text: str) -> str:
    """Template の static chrome を scan 対象から除外する。

    HTML コメント / CSS コメント / <style> ブロック / <script> ブロックは
    template 著者の意図的な内容で、データ由来の leak ではない。
    Layer 3 は data 由来の残骸 detection が目的なので、ここを exclude する。
    """
    out = text
    # HTML comments
    out = re.sub(r"<!--.*?-->", "", out, flags=re.DOTALL)
    # CSS comments
    out = re.sub(r"/\*.*?\*/", "", out, flags=re.DOTALL)
    # <style>...</style> blocks
    out = re.sub(r"<style[^>]*>.*?</style>", "", out, flags=re.DOTALL | re.IGNORECASE)
    # <script>...</script> blocks
    out = re.sub(r"<script[^>]*>.*?</script>", "", out, flags=re.DOTALL | re.IGNORECASE)
    return out


def main() -> int:
    text = sys.stdin.read()

    # Template chrome (HTML/CSS comments, <style>, <script>) を除去
    scrubbed = _strip_template_chrome(text)

    # Sentinel mark を一時的に消して scan する (false positive 防止)
    for pat in SENTINELS:
        scrubbed = pat.sub("", scrubbed)

    residues = []
    for m in KATAKANA_RUN.finditer(scrubbed):
        token = m.group(0)
        line_start = scrubbed.rfind("\n", 0, m.start()) + 1
        line_end = scrubbed.find("\n", m.end())
        if line_end == -1:
            line_end = len(scrubbed)
        line_text = scrubbed[line_start:line_end].strip()[:120]
        line_no = scrubbed[:m.start()].count("\n") + 1
        residues.append(
            f"detected: {token!r}, source: line {line_no}: {line_text!r}"
        )

    if residues:
        for r in residues:
            print(r, file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
