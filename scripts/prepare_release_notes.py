#!/usr/bin/env python3
"""Prepare App Store release notes from CHANGELOG.md [Unreleased].

Writes:
  fastlane/metadata/en-US/release_notes.txt

With --cut VERSION, also promotes [Unreleased] into ## [VERSION] – TODAY
and leaves a fresh empty [Unreleased] section.
"""

from __future__ import annotations

import argparse
import datetime as dt
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHANGELOG = ROOT / "CHANGELOG.md"
NOTES_PATH = ROOT / "fastlane" / "metadata" / "en-US" / "release_notes.txt"

UNRELEASED_RE = re.compile(
    r"^## \[Unreleased\]\s*\n(?P<body>.*?)(?=^## \[|\Z)",
    re.MULTILINE | re.DOTALL,
)
SECTION_RE = re.compile(r"^### (?P<title>.+)\s*$", re.MULTILINE)
BULLET_RE = re.compile(r"^[-*]\s+(?P<text>.+)$", re.MULTILINE)

# App Store Connect limit for "What's New"
MAX_CHARS = 4000


def extract_unreleased(text: str) -> str:
    match = UNRELEASED_RE.search(text)
    if not match:
        raise SystemExit("error: no ## [Unreleased] section in CHANGELOG.md")
    return match.group("body").strip()


def to_app_store_notes(unreleased_body: str) -> str:
    """Flatten Keep-a-Changelog markdown into plain App Store bullets."""
    lines: list[str] = []
    for raw in unreleased_body.splitlines():
        line = raw.rstrip()
        if not line or line.startswith("_") and line.endswith("_"):
            continue
        section = SECTION_RE.match(line)
        if section:
            # Skip section headers in the store listing — keep a flat bullet list.
            continue
        bullet = BULLET_RE.match(line)
        if bullet:
            text = bullet.group("text").strip()
            # Strip simple markdown emphasis
            text = re.sub(r"[`*_]", "", text)
            lines.append(f"• {text}")
            continue
    notes = "\n".join(lines).strip()
    if not notes:
        raise SystemExit(
            "error: [Unreleased] has no bullet items — add release notes to CHANGELOG.md"
        )
    if len(notes) > MAX_CHARS:
        raise SystemExit(
            f"error: release notes are {len(notes)} chars (limit {MAX_CHARS})"
        )
    return notes + "\n"


def cut_changelog(text: str, version: str, date: str) -> str:
    match = UNRELEASED_RE.search(text)
    if not match:
        raise SystemExit("error: no ## [Unreleased] section in CHANGELOG.md")

    body = match.group("body").rstrip() + "\n"
    # Drop placeholder TBD sections for this version if present
    text = re.sub(
        rf"^## \[{re.escape(version)}\].*?(?=^## \[|\Z)",
        "",
        text,
        count=1,
        flags=re.MULTILINE | re.DOTALL,
    )

    replacement = (
        f"## [Unreleased]\n\n"
        f"## [{version}] – {date}\n\n"
        f"{body}\n"
    )
    return UNRELEASED_RE.sub(replacement, text, count=1)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--cut",
        metavar="VERSION",
        help="Promote Unreleased into a dated version section",
    )
    parser.add_argument(
        "--date",
        default=dt.date.today().isoformat(),
        help="Release date for --cut (default: today)",
    )
    args = parser.parse_args()

    text = CHANGELOG.read_text(encoding="utf-8")
    unreleased = extract_unreleased(text)
    notes = to_app_store_notes(unreleased)

    NOTES_PATH.parent.mkdir(parents=True, exist_ok=True)
    NOTES_PATH.write_text(notes, encoding="utf-8")
    print(f"Wrote {NOTES_PATH.relative_to(ROOT)} ({len(notes)} chars)")
    print("---")
    print(notes, end="")

    if args.cut:
        updated = cut_changelog(text, args.cut, args.date)
        CHANGELOG.write_text(updated, encoding="utf-8")
        print(f"Cut CHANGELOG.md → [{args.cut}] – {args.date}")


if __name__ == "__main__":
    main()
