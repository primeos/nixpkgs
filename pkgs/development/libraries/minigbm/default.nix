{ stdenv, fetchgit
, pkg-config, coreutils
, libdrm
}:

stdenv.mkDerivation rec {
  pname = "minigbm-unstable";
  version = "2019-08-25"; # https://source.chromium.org/chromium/chromium/src/+/$version:DEPS
  # TODO: Use the version from Chromium once it's included in the tarball.

  src = fetchgit {
    url = "https://chromium.googlesource.com/chromiumos/platform/minigbm";
    rev = "3d856025f8f057d29361e753ef712993d218d6e9";
    sha256 = "0nl6k9nk9bbkna0bjcj587b19y2m7736mjfzir91ncfqc5mvg7m7";
  };

  patches = [ ./install-as-libminigbm.patch ];

  postPatch = ''
    substituteInPlace Makefile \
      --replace '/usr/include/' '/include/' \
      --replace '$(PKG_CONFIG)' 'pkg-config'
    substituteInPlace common.mk \
      --replace '/bin/echo' '${coreutils}/bin/echo'
  '';

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ libdrm ];

  makeFlags = [
    "DESTDIR=$(out)" "LIBDIR=/lib"
    # Build the following drivers:
    "DRV_AMDGPU=1" "DRV_I915=1" "DRV_RADEON=1"
  ];

  meta = with stdenv.lib; {
    description = "A small graphics buffer allocator for Chrome OS";
    # GBM implementation from Chromium OS
    homepage = "https://chromium.googlesource.com/chromiumos/platform/minigbm/";
    license = licenses.bsd3;
    platforms = platforms.unix;
    maintainers = with maintainers; [ primeos ];
  };
}
