from __future__ import annotations

import json
from pathlib import Path
from typing import Any


class AppSettings:
    """Persistent application settings stored in a JSON file."""

    DEFAULT_DATA: dict[str, Any] = {
        "folders": [],
        "current_playlist": 0,
        "sort": "title",
        "sort_desc": False,
        "shuffle": False,
        "loop": "none",
        "volume": 0.5,
        "theme": "",
        "mpris_enabled": True,
        "replaygain_enabled": True,
        "replaygain_mode": "track",
        "replaygain_preamp_db": 0.0,
        "master_gain_db": 4.0,
        "replaygain_prevent_clipping": True,
    }

    def __init__(self, config_dir: str) -> None:
        self.base_dir = Path(config_dir)
        self.base_dir.mkdir(parents=True, exist_ok=True)
        self.path = self.base_dir / "config.json"
        self.data: dict[str, Any] = self.DEFAULT_DATA.copy()
        self.load()

    def load(self) -> None:
        """Load settings from the JSON file, merging with defaults."""
        try:
            raw = json.loads(self.path.read_text(encoding="utf-8"))
            if isinstance(raw, dict):
                self.data.update(raw)
        except (OSError, json.JSONDecodeError):
            pass

    def save(self) -> None:
        """Write settings atomically to disk."""
        tmp = self.path.with_suffix(".tmp")
        tmp.write_text(json.dumps(self.data, indent=2, sort_keys=True), encoding="utf-8")
        tmp.replace(self.path)
