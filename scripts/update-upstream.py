#!/usr/bin/env python3
"""Update source/version/dependency hashes for the upstream Boosty Downloader release."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FLAKE = ROOT / "flake.nix"
CLI = ROOT / "cli.nix"
GUI = ROOT / "gui.nix"
FAKE_HASH = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="


def run(command: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    print("+", " ".join(command), flush=True)
    return subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=check,
    )


def replace_one(path: Path, pattern: str, replacement: str, description: str) -> None:
    content = path.read_text()
    updated, count = re.subn(pattern, replacement, content, count=1, flags=re.MULTILINE)
    if count != 1:
        raise RuntimeError(f"Expected exactly one {description} in {path}, found {count}")
    path.write_text(updated)


def set_version(path: Path, version: str) -> None:
    replace_one(
        path,
        r'^(\s*version = ")[^"]+(";)',
        rf'\g<1>{version}\2',
        "version field",
    )


def get_hash_from_failure(output: str) -> str:
    # Nix's fixed-output derivation mismatch normally includes: got: sha256-...
    matches = re.findall(r"\bgot:\s*(sha256-[A-Za-z0-9+/=]+)", output)
    if not matches:
        print(output, file=sys.stderr)
        raise RuntimeError("Could not extract the expected hash from Nix build output")
    return matches[-1]


def build_and_learn_hash(attr: str, path: Path, field_pattern: str, label: str) -> None:
    result = run(["nix", "build", f".#{attr}", "--no-link", "--print-build-logs"], check=False)
    if result.returncode == 0:
        print(f"{label}: existing hash is valid")
        return

    expected = get_hash_from_failure(result.stdout)
    print(f"{label}: updating hash to {expected}")
    replace_one(path, field_pattern, rf'\g<1>{expected}\g<2>', label)

    # Confirm the discovered hash actually fixes this derivation.
    run(["nix", "build", f".#{attr}", "--no-link", "--print-build-logs"])


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit(f"Usage: {sys.argv[0]} VERSION")
    version = sys.argv[1].removeprefix("v")
    if not re.fullmatch(r"\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?", version):
        raise SystemExit(f"Invalid release version: {version}")

    set_version(FLAKE, version)
    set_version(CLI, version)
    set_version(GUI, version)

    source_url = f"https://github.com/ath31st/boosty_downloader/archive/refs/tags/v{version}.tar.gz"
    prefetched = run(["nix-prefetch-url", "--unpack", source_url]).stdout.strip().splitlines()[-1]
    source_hash = run([
        "nix", "hash", "convert", "--hash-algo", "sha256", "--to", "sri", prefetched
    ]).stdout.strip()
    replace_one(
        FLAKE,
        r'(^\s*hash = ")[^"]+(";\s*\n\s*stripRoot = true;)',
        rf'\g<1>{source_hash}\2',
        "source archive hash",
    )

    # Resolve each hash independently. The GUI's Rust dependency graph differs
    # from the CLI's; keep these hashes separate even if they happen to match.
    replace_one(CLI, r'(^\s*cargoHash = ")[^"]+(";\s*$)', rf'\g<1>{FAKE_HASH}\2', "CLI cargoHash")
    build_and_learn_hash(
        "cli",
        CLI,
        r'(^\s*cargoHash = ")[^"]+(";\s*$)',
        "CLI cargoHash",
    )

    replace_one(GUI, r'(^\s*cargoHash = ")[^"]+(";\s*$)', rf'\g<1>{FAKE_HASH}\2', "GUI cargoHash")
    build_and_learn_hash(
        "gui",
        GUI,
        r'(^\s*cargoHash = ")[^"]+(";\s*$)',
        "GUI cargoHash",
    )

    # Now that the GUI Cargo vendor hash is valid, discover the Yarn hash.
    replace_one(
        GUI,
        r'(^\s*hash = ")[^"]+(";\s*\n\s*};)',
        rf'\g<1>{FAKE_HASH}\2',
        "Yarn dependency hash",
    )
    build_and_learn_hash(
        "gui",
        GUI,
        r'(^\s*hash = ")[^"]+(";\s*\n\s*};)',
        "Yarn dependency hash",
    )

    # Final clean verification, including both outputs.
    run(["nix", "build", ".#cli", "--no-link", "--print-build-logs"])
    run(["nix", "build", ".#gui", "--no-link", "--print-build-logs"])
    print(f"Successfully updated Boosty Downloader to {version}")


if __name__ == "__main__":
    main()
