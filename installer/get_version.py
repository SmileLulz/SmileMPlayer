import tomllib
from pathlib import Path

root = Path(__file__).resolve().parent.parent

with (root / "pyproject.toml").open("rb") as f:
    print(tomllib.load(f)["project"]["version"])
