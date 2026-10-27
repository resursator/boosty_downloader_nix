{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
  src,
  version
}:

rustPlatform.buildRustPackage {
  pname = "boosty-downloader";

  inherit src;
  inherit version;

  # Заменить на hash, полученный при первой сборке.
  cargoHash = lib.fakeHash;

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
