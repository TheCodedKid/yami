# Packaging

English · [Русский](PACKAGING.ru.md)

Notes for distribution and Nix packagers: where yami looks for system files, and how to hand upgrades to the package manager.

## System files

The shell finds the polkit helper, the gvfs MTP backend and the SDDM theme without fixed FHS paths. On NixOS the polkit helper is the setuid wrapper `/run/wrappers/bin/polkit-agent-helper-1`, which comes first: a copy of the helper from `PATH` has no setuid bit and cannot check a password. gvfs and the SDDM theme `sddm/themes/yami` are found through `XDG_DATA_DIRS`. The old paths under `/usr` stay as fallbacks.

A theme in the Nix store is read only, so the login screen keeps its own palette and wallpaper: the shell only writes `theme.conf.user` when it can.

## Updates by the package manager

Build with the Cargo feature `package-managed`:

```sh
cargo build --release --locked --workspace --features yami-shell/package-managed --manifest-path shell/Cargo.toml
```

Such a build never checks for updates on a schedule, the updates tab shows a note instead of its buttons, and `yami update` (with any subcommand) prints «Updates are managed by your package manager.» and exits with 1. Update, release switch and rollback refuse before they touch the source clone or the installed binaries. Upgrade and roll back with the package manager. A build without the feature keeps the updater.

Do not run `install.sh` over an installation that the package manager owns.
