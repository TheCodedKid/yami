# Packaging

[Русский](packaging.ru.md)

## Runtime discovery

The shell searches `PATH` for `polkit-agent-helper-1` and `gvfsd-mtp` before trying distribution-specific paths. The polkit fallback includes `/run/wrappers/bin/polkit-agent-helper-1` on NixOS; keep the system's privileged wrapper, not an unprivileged copy of the helper.

Both the shell and `tools/theme.py` look for `sddm/themes/yami` in absolute `XDG_DATA_DIRS` entries, in order, then fall back to `/usr/share/sddm/themes/yami`. An unset or empty variable uses `/usr/local/share:/usr/share`. The first existing theme wins. Runtime palette and wallpaper changes still require a writable theme; discovery does not make a Nix store theme writable. `theme.py --sddm DIR` remains available for build-time generation.

## Package-managed updates

Build the shell with the additive Cargo feature `package-managed`:

```sh
cargo build --release --locked --workspace --features package-managed --manifest-path shell/Cargo.toml
```

This disables scheduled update checks, replaces the updates panel with a package-manager notice, and makes `yami update` exit with status 1 and an explanatory message. Update, version-switch and rollback entry points refuse to run before touching the source clone or installed binaries. Use the package manager to upgrade or roll back. Builds without this feature keep the existing updater.

## Nix support

These portability hooks are the first step toward declarative Nix support. A flake, package, Home Manager module and NixOS module are not included yet. Do not run `install.sh` to populate a package-manager-owned installation.
