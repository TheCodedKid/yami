#!/usr/bin/env python3
"""SDDM discovery tests; no desktop session or system writes needed."""
import os
import runpy
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

THEME = runpy.run_path(str(Path(__file__).with_name("theme.py")))


class SddmDiscovery(unittest.TestCase):
    def test_xdg_order(self):
        with tempfile.TemporaryDirectory() as root:
            first, second = Path(root) / "first", Path(root) / "second"
            theme = second / "sddm/themes/yami"
            theme.mkdir(parents=True)
            with patch.dict(os.environ, {"XDG_DATA_DIRS": f"relative::{first}:{second}"}):
                self.assertEqual(THEME["sddm_dir"](), theme)
                preferred = first / "sddm/themes/yami"
                preferred.mkdir(parents=True)
                self.assertEqual(THEME["sddm_dir"](), preferred)

    def test_defaults_and_fallback(self):
        for value in (None, "", "relative"):
            with patch.dict(os.environ):
                os.environ.pop("XDG_DATA_DIRS", None)
                if value is not None:
                    os.environ["XDG_DATA_DIRS"] = value
                with patch.object(Path, "is_dir", return_value=False):
                    self.assertEqual(THEME["sddm_dir"](), Path("/usr/share/sddm/themes/yami"))


if __name__ == "__main__":
    unittest.main()
