# Boosty Downloader for NixOS

Nix-пакеты для [Boosty Downloader](https://github.com/ath31st/boosty_downloader) — CLI и GUI для Linux.

Пакеты собираются из исходников официального релиза. Конфигурация Nix адаптирует пути хранения настроек и загрузок под Linux.

## Использование

Запустить без установки:

```bash
nix run github:resursator/boosty_downloader_nix#cli
nix run github:resursator/boosty_downloader_nix#gui
```

Собрать пакет:

```bash
nix build github:resursator/boosty_downloader_nix#cli --no-link
nix build github:resursator/boosty_downloader_nix#gui --no-link
```

По умолчанию `nix build` собирает CLI:

```bash
nix build github:resursator/boosty_downloader_nix
```

## Изменения относительно оригинального проекта

При сборке применяются патчи к путям хранения данных:

- **Конфигурация:** `~/.config/boosty-downloader/config.json` вместо расположения по умолчанию в исходном проекте.
- **Загрузки:** `~/Downloads/boosty-downloader` — каталог загрузок по умолчанию.

Путь к конфигурации также учитывает переменную окружения `XDG_CONFIG_HOME`.

## Установка в системный flake

Добавьте репозиторий в `inputs` своего системного `flake.nix`:

```nix
inputs.boosty-downloader.url = "github:resursator/boosty_downloader_nix";
```

В `outputs` добавьте пакет в `environment.systemPackages` нужного хоста:

```nix
environment.systemPackages = [
  inputs.boosty-downloader.packages.${pkgs.system}.cli
  inputs.boosty-downloader.packages.${pkgs.system}.gui
];
```

После этого пересоберите систему:

```bash
sudo nixos-rebuild switch --flake .#HOSTNAME
```

Замените `HOSTNAME` на имя своего хоста.

## Возможные проблемы запуска GUI

GUI использует Tauri и WebKitGTK. В некоторых конфигурациях Linux с NVIDIA возможны ошибки создания графических буферов, например:

```
Failed to create GBM buffer of size 1200x830: Invalid argument
```

Если окно не открывается или интерфейс отображается некорректно, попробуйте запуск с отключением DMABUF-рендерера WebKitGTK:

```bash
WEBKIT_DISABLE_DMABUF_RENDERER=1 nix run github:resursator/boosty_downloader_nix#gui
```

Если приложение установлено в систему, запустите его из терминала с той же переменной окружения. Предупреждение само по себе не обязательно означает, что приложение не работает.

## Исходный проект

- [Boosty Downloader — исходный проект и подробная инструкция](https://github.com/ath31st/boosty_downloader)
- [Релизы](https://github.com/ath31st/boosty_downloader/releases)
- [MIT License](LICENSE)
