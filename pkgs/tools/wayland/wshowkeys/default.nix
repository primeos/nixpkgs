{ stdenv, fetchgit
, meson, pkg-config, wayland, ninja
, cairo, libinput, pango, wayland-protocols, libxkbcommon
}:

stdenv.mkDerivation rec {
  pname = "wshowkeys-unstable";
  version = "2020-03-29";

  src = fetchgit {
    url = "https://git.sr.ht/~sircmpwn/wshowkeys";
    rev = "6388a49e0f431d6d5fcbd152b8ae4fa8e87884ee";
    sha256 = "etXXNxspnJOoVu2tL/EOxW04vuxqQ3719YuzomRzaoI=";
  };

  nativeBuildInputs = [ meson pkg-config wayland ninja ];
  buildInputs = [ cairo libinput pango wayland-protocols libxkbcommon ];

  meta = with stdenv.lib; {
    description = "Displays keys being pressed on a Wayland session";
    longDescription = ''
      Displays keypresses on screen on supported Wayland compositors (requires
      wlr_layer_shell_v1 support).
      Note: This tool requires root permissions to read input events, but these
      permissions are dropped after startup. The NixOS module provides such a
      setuid binary (use "programs.wshowkeys.enable = true;").
    '';
    homepage = "https://git.sr.ht/~sircmpwn/wshowkeys";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = with maintainers; [ primeos berbiche ];
  };
}
