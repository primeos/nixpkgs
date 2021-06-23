{ lib, stdenv, fetchFromGitHub, fetchpatch
, meson, ninja, pkg-config, wayland, scdoc, makeWrapper
, wlroots, wayland-protocols, pixman, libxkbcommon
, systemd, libGL, libX11, mesa
, xwayland ? null
, nixosTests
}:

stdenv.mkDerivation rec {
  pname = "cage";
  version = "0.1.3";

  src = fetchFromGitHub {
    owner = "Hjdskes";
    repo = "cage";
    rev = "v${version}";
    sha256 = "0ixl45g0m8b75gvbjm3gf5qg0yplspgs0xpm2619wn5sygc47sb1";
  };

  patches = [
    # To fix the build with wlroots 0.14.0:
    (fetchpatch {
      # Unbreak build with wlroots 0.14.0
      # TODO: Don't fetch from a PR!
      url = "https://github.com/Hjdskes/cage/pull/191.patch";
      sha256 = "0wlgaqii63l710c5fx7ij57x6r874pdxca1ij5v7gz7ividixw0i";
    })
  ];

  nativeBuildInputs = [ meson ninja pkg-config wayland scdoc makeWrapper ];

  buildInputs = [
    wlroots wayland wayland-protocols pixman libxkbcommon
    mesa # for libEGL headers
    systemd libGL libX11
  ];

  mesonFlags = [ "-Dxwayland=${lib.boolToString (xwayland != null)}" ];

  postFixup = lib.optionalString (xwayland != null) ''
    wrapProgram $out/bin/cage --prefix PATH : "${xwayland}/bin"
  '';

  # Tests Cage using the NixOS module by launching xterm:
  passthru.tests.basic-nixos-module-functionality = nixosTests.cage;

  meta = with lib; {
    description = "A Wayland kiosk that runs a single, maximized application";
    homepage    = "https://www.hjdskes.nl/projects/cage/";
    license     = licenses.mit;
    platforms   = platforms.linux;
    maintainers = with maintainers; [ primeos ];
  };
}
