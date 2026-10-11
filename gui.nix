{
  lib,
  rustPlatform,
  fetchYarnDeps,
  cargo-tauri,
  nodejs,
  yarn,
  yarnConfigHook,
  pkg-config,
  wrapGAppsHook4,
  glib-networking,
  openssl,
  webkitgtk_4_1,
  gtk3,
  glib,
  libsoup_3,
  cairo,
  pango,
  gdk-pixbuf,
  librsvg,
  python3,
  src
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "boosty-downloader-gui";
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

  # cargoRoot = "src-tauri";
  # buildAndTestSubdir = "src-tauri";

  # Cargo.lock находится в корне workspace.
  cargoHash = "sha256-uQx4JuHkSmBBY3qn3b8hH90LtRCLZQboG8ro2EBKWa8=";

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${src}/frontend/yarn.lock";
    hash = "sha256-dIFvK5BnDAW1L7r3MeXJrTGtR8eGu7O2z9FqIRLaeaE=";
  };

  dontYarnInstallDeps = true;

  postConfigure = ''
    cd frontend
    yarnConfigHook
    cd ..
  '';

  nativeBuildInputs = [
    cargo-tauri.hook
    nodejs
    yarn
    yarnConfigHook
    pkg-config
    python3
    wrapGAppsHook4
  ];

  buildInputs = [
    glib-networking
    openssl
    webkitgtk_4_1
    gtk3
    glib
    libsoup_3
    cairo
    pango
    gdk-pixbuf
    librsvg
  ];

  # Пока не собираем AppImage — нужен обычный исполняемый файл.
  dontTauriBundle = true;

  doCheck = false;

  meta = {
    description = "GUI downloader for Boosty content";
    homepage = "https://github.com/ath31st/boosty_downloader";
    license = lib.licenses.mit;
    mainProgram = "boosty_downloader_gui";
    platforms = [ "x86_64-linux" ];
  };
})
