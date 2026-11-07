# Сборка пакетов

[English](PACKAGING.md) · Русский

Заметки для сборщиков пакетов дистрибутивов и Nix: где yami ищет системные файлы и как отдать обновления пакетному менеджеру.

## Системные файлы

Шелл находит помощника polkit, бэкенд MTP из gvfs и тему SDDM без жёстких путей FHS. На NixOS помощник polkit — setuid-обёртка `/run/wrappers/bin/polkit-agent-helper-1`, она идёт первой: копия помощника из `PATH` без бита setuid пароль не проверит. gvfs и тема SDDM `sddm/themes/yami` находятся через `XDG_DATA_DIRS`. Старые пути в `/usr` остаются запасными.

Тема в хранилище Nix только для чтения, поэтому экран входа остаётся со своей палитрой и обоями: шелл пишет `theme.conf.user`, только когда может.

## Обновления через пакетный менеджер

Соберите с признаком Cargo `package-managed`:

```sh
cargo build --release --locked --workspace --features yami-shell/package-managed --manifest-path shell/Cargo.toml
```

Такая сборка не проверяет обновления по расписанию, вкладка обновлений показывает заметку вместо кнопок, а `yami update` (с любой подкомандой) пишет «Обновлениями управляет пакетный менеджер.» и выходит с 1. Обновление, переход на выпуск и откат отказываются раньше, чем тронут клон исходников или установленные бинари. Обновляйте и откатывайте пакетным менеджером. Сборка без признака сохраняет обновления.

Не запускайте `install.sh` поверх установки, которой владеет пакетный менеджер.

## Флейк Nix

Флейк собирает yami из `shell/Cargo.lock` с включённым `package-managed`. Все файлы Nix лежат в `flake.nix` и `nix/`.

| Выход | Что это |
|---|---|
| `packages.<system>.yami` (`default`) | `yami-shell`, `yami`, `yami-files`, `yami-view`, `yami-play`; файлы `.desktop`, портал и его службы D-Bus, свои шрифты |
| `packages.<system>.yami-sddm-theme` | экран входа в `share/sddm/themes/yami` и курсор `share/icons/yami-cursor`, раскрашенные при сборке |
| `overlays.default` | оба пакета в `pkgs` |
| `devShells.<system>.default` | Rust, системные библиотеки и libmpv для `tools/check.sh` |

```sh
nix build github:Trendorin/yami
nix develop
```

Цвета экрана входа задаются переопределением: `yami-sddm-theme.override { loginAccent = "#3a7bd5"; loginLight = true; }`. yami-play находит libmpv через RUNPATH своего бинаря.

Пакет не пишет в `~/.config`: конфиг niri, выбор портала, kitty и настройки шелла — дело модуля Home Manager (ниже).

## Модуль Home Manager

```nix
{
  inputs.yami.url = "github:Trendorin/yami";
  # в конфигурации Home Manager:
  imports = [ inputs.yami.homeManagerModules.default ];
  programs.yami = {
    enable = true;
    settings = { palette = "sakura"; lang = "en"; };
  };
}
```

| Параметр | По умолчанию | Что делает |
|---|---|---|
| `settings` | `{}` | ключи `~/.config/yami-shell.json` ([CONFIG.ru.md](CONFIG.ru.md)), сливаются при каждой активации: они главнее, остальное из панели настроек остаётся |
| `niriConfig` | `true` | `~/.config/niri/config.kdl` от yami, копия, как у `install.sh`, и заменяется, только пока `~/.config/niri/.yami` помечает его как файл yami; свои строки — в `user.kdl` |
| `kitty` | `programs.kitty.enable` | ссылка на `kitty/yami.conf` и его подключение |
| `defaultApplications` | `true` | yami-files, yami-view и yami-play в `xdg.mimeApps` (с `xdg.mimeApps.enable`) |
| `extraPackages` | команды, которые зовёт шелл | `python3`, `wl-clipboard`, `cliphist`, `playerctl`, `grim` и другие |

Шелл переписывает свои настройки, клавиши, экраны и выбор порталов, пока работает, поэтому эти файлы — копии, которые модуль кладёт один раз, а не ссылки в хранилище. niri запускает шелл из `config.kdl`; с `niriConfig = false` добавьте в свой строки `include optional=true "yami-….kdl"` из `config.kdl` yami. Системные службы (NetworkManager, gvfs, udisks, polkit, power-profiles-daemon) и тема SDDM — параметры NixOS, а не Home Manager.
