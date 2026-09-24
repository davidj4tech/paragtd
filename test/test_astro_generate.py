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
    # Events on their day, not TODOs that go overdue.
    assert "TODO" not in text and "SCHEDULED:" not in text
    # The March equinox is the Sun entering Aries, not Pisces.
    assert "** Sun enters Aries\n:PROPERTIES:\n:TIMEZONE: Australia/Melbourne\n:UTC: 2026-03-20 14:45\n" in text


def test_new_and_full_moons_can_go_to_their_own_file() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        astro, lunar = Path(tmp) / "astro.org", Path(tmp) / "lunar.org"
        run = [str(REPO / "bin" / "paragtd-astro-generate"), "--output", str(astro),
               "--lunar-output", str(lunar)]
        subprocess.run(run + ["--year", "2026"], check=True)
        subprocess.run(run + ["--year", "2027", "--append"], check=True)
        again = subprocess.run(run + ["--year", "2027", "--append"], capture_output=True)
        astro_text, lunar_text = astro.read_text(), lunar.read_text()

    assert again.returncode != 0
    assert lunar_text.startswith("#+title: Lunar Routines")
    assert "* 2026 Lunar Routines" in lunar_text and "* 2027 Lunar Routines" in lunar_text
    assert "Full moon routine" in lunar_text and "quarter" not in lunar_text
    assert "Full moon routine" not in astro_text and "New moon routine" not in astro_text
    assert "First quarter moon routine" in astro_text


if __name__ == "__main__":
    test_astro_generator_outputs_expected_sections()
    test_new_and_full_moons_can_go_to_their_own_file()
    print("astro generator smoke OK")
