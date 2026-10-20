#!/usr/bin/env python3
"""Update source/version/dependency hashes for an upstream Boosty Downloader release."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FLAKE = ROOT / "flake.nix"
CLI = ROOT / "cli.nix"
GUI = ROOT / "gui.nix"

# Each marker identifies the field whose expected hash Nix reports after "got:".
CLI_CARGO_MARKER = "sha256-cargoHashAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
GUI_CARGO_MARKER = "sha256-cargoHashAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
YARN_MARKER = "sha256-yarnOfflineCache/hash/AAAAAAAAAAAAAAAAAAAAA="

CLI_CARGO_PATTERN = r'(^\s*cargoHash = ")[^"]+(";\s*$)'
GUI_CARGO_PATTERN = r'(^\s*cargoHash = ")[^"]+(";\s*$)'
YARN_PATTERN = r'(^\s*hash = ")[^"]+(";\s*\n\s*};)'

HASH_MISMATCH_RE = re.compile(
    r"specified:\s*(\S+)\s+got:\s*(sha256-[A-Za-z0-9+/=]+)"
)


def run(command: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    print("+", " ".join(command), flush=True)
    result = subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    if check and result.returncode != 0:
        print(result.stdout, file=sys.stderr, end="" if result.stdout.endswith("\n") else "\n")
        raise subprocess.CalledProcessError(result.returncode, command, output=result.stdout)
    return result


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


def set_hash(path: Path, pattern: str, value: str, label: str) -> None:
    replace_one(path, pattern, rf'\g<1>{value}\g<2>', label)


def learn_hashes_until_success(
    attr: str,
    hash_fields: dict[str, tuple[Path, str, str]],
) -> None:
    """Build repeatedly, updating only the field identified by Nix's `specified:` marker."""
    # Each field is seeded with its own marker before this function is called.
    # The GUI can report Yarn first and Cargo on the next attempt; no order is assumed.
    max_attempts = len(hash_fields) + 1
    for _ in range(max_attempts):
        result = run(
            ["nix", "build", f".#" + attr, "--no-link", "--print-build-logs"],
            check=False,
        )
        if result.returncode == 0:
            print(f"{attr}: build succeeded")
            return

        mismatches = HASH_MISMATCH_RE.findall(result.stdout)
        recognized = [(specified, got) for specified, got in mismatches if specified in hash_fields]
        if len(recognized) != 1:
            print(result.stdout, file=sys.stderr, end="" if result.stdout.endswith("\n") else "\n")
            if not recognized:
                raise RuntimeError(
                    f"{attr}: build failed without a recognized fake-hash marker; refusing to guess"
                )
            raise RuntimeError(
                f"{attr}: expected one recognized hash mismatch, found {len(recognized)}; refusing to guess"
            )

        marker, expected = recognized[0]
        path, pattern, label = hash_fields[marker]
        print(f"{label}: updating hash to {expected}")
        set_hash(path, pattern, expected, label)

    raise RuntimeError(f"{attr}: build did not succeed after resolving all known hashes")


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

    # Seed all dependency hashes with identifiable markers. The CLI and GUI Cargo
    # hashes are handled in separate builds because their dependency graphs differ.
    set_hash(CLI, CLI_CARGO_PATTERN, CLI_CARGO_MARKER, "CLI cargoHash marker")
    set_hash(GUI, GUI_CARGO_PATTERN, GUI_CARGO_MARKER, "GUI cargoHash marker")
    set_hash(GUI, YARN_PATTERN, YARN_MARKER, "Yarn dependency hash marker")

    cli_fields = {
        CLI_CARGO_MARKER: (CLI, CLI_CARGO_PATTERN, "CLI cargoHash"),
    }
    gui_fields = {
        GUI_CARGO_MARKER: (GUI, GUI_CARGO_PATTERN, "GUI cargoHash"),
        YARN_MARKER: (GUI, YARN_PATTERN, "Yarn dependency hash"),
    }

    learn_hashes_until_success("cli", cli_fields)
    learn_hashes_until_success("gui", gui_fields)

    # Final verification using the resolved hashes.
    run(["nix", "build", ".#cli", "--no-link", "--print-build-logs"])
    run(["nix", "build", ".#gui", "--no-link", "--print-build-logs"])
    print(f"Successfully updated Boosty Downloader to {version}")


if __name__ == "__main__":
    main()
