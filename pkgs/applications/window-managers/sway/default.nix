{ stdenv, fetchFromGitHub, makeWrapper
, meson, ninja
, pkgconfig, scdoc
, wayland, libxkbcommon, pcre, json_c, dbus, libevdev
, pango, cairo, libinput, libcap, pam, gdk-pixbuf, librsvg
, wlroots, wayland-protocols
}:

stdenv.mkDerivation rec {
  pname = "sway-unwrapped";
  version = "1.5-rc1";

  src = fetchFromGitHub {
    owner = "swaywm";
    repo = "sway";
    rev = version;
    sha256 = "0cj5jia5nv1bakv8l4x5gaxjcanklpyb5v8ggvwqf06dh0sk55my";
  };

  patches = [
    ./sway-config-no-nix-store-references.patch
    ./load-configuration-from-etc.patch
  ];

  nativeBuildInputs = [
    pkgconfig meson ninja scdoc
  ];

  buildInputs = [
    wayland libxkbcommon pcre json_c dbus libevdev
    pango cairo libinput libcap pam gdk-pixbuf librsvg
    wlroots wayland-protocols
  ];

  mesonFlags = [
    "-Ddefault-wallpaper=false"
  ];

  meta = with stdenv.lib; {
    description = "An i3-compatible tiling Wayland compositor";
    longDescription = ''
      Sway is a tiling Wayland compositor and a drop-in replacement for the i3
      window manager for X11. It works with your existing i3 configuration and
      supports most of i3's features, plus a few extras.
      Sway allows you to arrange your application windows logically, rather
      than spatially. Windows are arranged into a grid by default which
      maximizes the efficiency of your screen and can be quickly manipulated
      using only the keyboard.
    '';
    homepage    = "https://swaywm.org";
    license     = licenses.mit;
    platforms   = platforms.linux;
    maintainers = with maintainers; [ primeos synthetica ma27 ];
  };
}
