{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
  python3,
  src
}:

rustPlatform.buildRustPackage {
  pname = "boosty-downloader";
  version = "0.19.0";

  inherit src;

  postPatch = ''
    python3 - <<'PY'
    from pathlib import Path

    path = Path("core/src/config.rs")
    source = path.read_text()

    start = source.index("fn config_path() -> Result<PathBuf> {")
    end = source.index("\npub async fn load_config()", start)

    replacement = """fn config_path() -> Result<PathBuf> {
        let config_dir = env::var_os("XDG_CONFIG_HOME")
            .map(PathBuf::from)
            .or_else(|| {
                env::var_os("HOME")
                    .map(|home| PathBuf::from(home).join(".config"))
            })
            .context("Neither XDG_CONFIG_HOME nor HOME is set")?
            .join("boosty-downloader");

        std::fs::create_dir_all(&config_dir)
            .with_context(|| format!("Failed to create config directory: {}", config_dir.display()))?;

        Ok(config_dir.join("config.json"))
    }
    """

    source = source[:start] + replacement + source[end:]

    start = source.index("pub fn get_download_path(config: &AppConfig) -> PathBuf {")
    end = source.index("\npub async fn update_config", start)

    replacement = """pub fn get_download_path(config: &AppConfig) -> PathBuf {
        match &config.download_path {
            Some(path) => PathBuf::from(path),
            None => env::var_os("HOME")
                .map(|home| PathBuf::from(home).join("Downloads").join("boosty-downloader"))
                .unwrap_or_else(|| PathBuf::from("Downloads").join("boosty-downloader")),
        }
    }
    """

    source = source[:start] + replacement + source[end:]
    path.write_text(source)
    PY
  '';

  # Заменить на hash, полученный при первой сборке.
  cargoHash = "sha256-uQx4JuHkSmBBY3qn3b8hH90LtRCLZQboG8ro2EBKWa8=";

  cargoBuildFlags = [
    "-p" "boosty_downloader_core"
    "--bin" "boosty_downloader_cli"
  ];

  nativeBuildInputs = [
    pkg-config
    python3
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
