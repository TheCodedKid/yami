{
  description = "yami: a lightweight pixel-art Wayland shell for the niri compositor";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAll = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      version = lib.fileContents ./VERSION;
      # only what the builds read: a change to docs or CI does not rebuild the shell
      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [
          ./LICENSE
          ./VERSION
          ./README.md
          ./config
          ./fonts
          ./sddm
          ./tools
          (lib.fileset.difference ./shell (lib.fileset.maybeMissing ./shell/target))
        ];
      };
      packagesFor = pkgs: {
        yami = pkgs.callPackage ./nix/package.nix { inherit version src; };
        yami-sddm-theme = pkgs.callPackage ./nix/sddm-theme.nix { inherit version src; };
      };
    in
    {
      packages = forAll (
        pkgs:
        packagesFor pkgs
        // {
          default = self.packages.${pkgs.stdenv.hostPlatform.system}.yami;
        }
      );

      # `nix flake check` builds both packages
      checks = forAll (pkgs: {
        inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) yami yami-sddm-theme;
      });

      homeManagerModules.default = import ./nix/hm-module.nix self;

      overlays.default = _final: prev: packagesFor prev;

      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          inputsFrom = [ self.packages.${pkgs.stdenv.hostPlatform.system}.yami ];
          packages = with pkgs; [
            cargo
            rustc
            clippy
            rustfmt
            python3
            shellcheck
          ];
          # yami-play finds libmpv at run time
          LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.mpv-unwrapped ];
        };
      });

      formatter = forAll (pkgs: pkgs.nixfmt);
    };
}
