{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
  src
}:

rustPlatform.buildRustPackage {
  pname = "boosty-downloader";
  version = "0.20.0";

  inherit src;

  # Заменить на hash, полученный при первой сборке.
  cargoHash = "sha256-73FIiYFLMqKsBpcV9RoWrrM6lLtqh2ScwXiT7tckWPY=";

  cargoBuildFlags = [
    "-p" "boosty_downloader_core"
    "--bin" "boosty_downloader_cli"
  ];

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
  ];

  doCheck = false;

  meta = {
    description = "Downloader for Boosty content";
    homepage = "https://github.com/ath31st/boosty_downloader";
    license = lib.licenses.mit;
    mainProgram = "boosty_downloader_cli";
    platforms = lib.platforms.linux;
  };
}
