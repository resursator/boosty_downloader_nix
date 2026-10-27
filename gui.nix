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
  src,
  version
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "boosty-downloader-gui";

  inherit src;
  inherit version;

  # cargoRoot = "src-tauri";
  # buildAndTestSubdir = "src-tauri";

  # Cargo.lock находится в корне workspace.
  cargoHash = lib.fakeHash;

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${src}/frontend/yarn.lock";
    hash = lib.fakeHash;
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
