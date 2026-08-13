#!/usr/bin/env python3
"""Smoke tests for the astro Org generator."""

from __future__ import annotations

import subprocess
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]


def test_astro_generator_outputs_expected_sections() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        output = Path(tmp) / "astro.org"
        subprocess.run(
            [
                str(REPO / "bin" / "paragtd-astro-generate"),
                "--year",
                "2026",
                "--output",
                str(output),
            ],
            check=True,
        )
        text = output.read_text(encoding="utf-8")

    expected = [
        "* 2026 Lunar Routines",
        "New moon routine",
        "First quarter moon routine",
        "Full moon routine",
        "Last quarter moon routine",
        "Sun enters Aries",
        "Sun enters Aries decan 1",
        "Astrological new year / Aries ingress",
        "Moon enters Aries",
        ":TIMEZONE: Australia/Melbourne",
        ":UTC:",
    ]
    missing = [item for item in expected if item not in text]
    assert not missing, f"missing expected content: {missing}"


if __name__ == "__main__":
    test_astro_generator_outputs_expected_sections()
    print("astro generator smoke OK")
