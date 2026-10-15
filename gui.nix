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
  src
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "boosty-downloader-gui";
  version = "0.20.0";

  inherit src;

  # cargoRoot = "src-tauri";
  # buildAndTestSubdir = "src-tauri";

  # Cargo.lock находится в корне workspace.
  cargoHash = "sha256-73FIiYFLMqKsBpcV9RoWrrM6lLtqh2ScwXiT7tckWPY=";

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${src}/frontend/yarn.lock";
    hash = "sha256-i5zhA1Mzs/o3qwxC90BO6wRAG3S/lksbVqMckXeZ9Io=";
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
