# The yami login screen for SDDM (Qt 6) and its pixel cursor, coloured from one accent.
# The store copy is read only: the shell cannot write the wallpaper and palette into it at run time,
# so the login screen keeps the colours chosen here.
{
  lib,
  stdenvNoCC,
  python3,
  version,
  src,
  # `.override { loginAccent = "#3a7bd5"; loginLight = true; }`
  loginAccent ? "#c4161c",
  loginLight ? false,
}:

stdenvNoCC.mkDerivation {
  pname = "yami-sddm-theme";
  inherit version src;

  nativeBuildInputs = [ python3 ];
  dontConfigure = true;
  dontBuild = true;

  installPhase =
    let
      colour = [
        "--accent"
        loginAccent
      ]
      ++ lib.optional loginLight "--light";
    in
    ''
      export HOME=$TMPDIR
      dst=$out/share/sddm/themes/yami
      bash tools/sddm-build.sh $dst >/dev/null
      python3 -I tools/theme.py --sddm $dst ${lib.escapeShellArgs colour}
      python3 -I tools/theme.py --cursor-to $out/share/icons/yami-cursor ${lib.escapeShellArgs colour}
    '';

  meta = {
    description = "Login screen of the yami shell for SDDM";
    homepage = "https://github.com/Trendorin/yami";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
