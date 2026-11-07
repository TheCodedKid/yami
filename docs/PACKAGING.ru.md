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

Пакет не пишет в `~/.config`: конфиг niri, выбор портала, kitty и настройки шелла — дело модуля Home Manager.
