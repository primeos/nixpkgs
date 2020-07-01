{ stdenv, fetchFromGitHub, meson, ninja, pkg-config, wayland
, libGL, wayland-protocols, libinput, libxkbcommon, pixman
, xcbutilwm, libX11, libcap, xcbutilimage, xcbutilerrors, mesa
, libpng, ffmpeg
}:

stdenv.mkDerivation rec {
  pname = "wlroots-unstable";
  version = "2020-06-28";

  src = fetchFromGitHub {
    owner = "swaywm";
    repo = "wlroots";
    rev = "a54ed8588177a679a131c621c0d300c6a9d910c5";
    sha256 = "1ck5wrw8xl2ss1qixlmspsix7a96abajvl9v3xcygxmrnkj6412v";
  };

  # $out for the library and $examples for the example programs (in examples):
  outputs = [ "out" "examples" ];

  nativeBuildInputs = [ meson ninja pkg-config wayland ];

  buildInputs = [
    libGL wayland-protocols libinput libxkbcommon pixman
    xcbutilwm libX11 libcap xcbutilimage xcbutilerrors mesa
    libpng ffmpeg
  ];

  mesonFlags = [ "-Dlogind-provider=systemd" ];

  postInstall = ''
    # Copy the library to $examples
    mkdir -p $examples/lib
    cp -P libwlroots* $examples/lib/
  '';

  postFixup = ''
    # Install ALL example programs to $examples:
    # screencopy dmabuf-capture input-inhibitor layer-shell idle-inhibit idle
    # screenshot output-layout multi-pointer rotation tablet touch pointer
    # simple
    mkdir -p $examples/bin
    cd ./examples
    for binary in $(find . -executable -type f -printf '%P\n' | grep -vE '\.so'); do
      cp "$binary" "$examples/bin/wlroots-$binary"
    done
  '';

  meta = with stdenv.lib; {
    description = "A modular Wayland compositor library";
    longDescription = ''
      Pluggable, composable, unopinionated modules for building a Wayland
      compositor; or about 50,000 lines of code you were going to write anyway.
    '';
    inherit (src.meta) homepage;
    changelog = "https://github.com/swaywm/wlroots/releases/tag/${version}";
    license     = licenses.mit;
    platforms   = platforms.linux;
    maintainers = with maintainers; [ primeos ];
  };
}
