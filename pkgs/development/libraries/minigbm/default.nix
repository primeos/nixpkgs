{ stdenv, fetchgit
, pkg-config, coreutils
, libdrm
}:

stdenv.mkDerivation rec {
  pname = "minigbm-unstable";
  version = "2020-03-26"; # https://source.chromium.org/chromium/chromium/src/+/$version:DEPS
  # TODO: Use the version from Chromium once it's included in the tarball.

  src = fetchgit {
    url = "https://chromium.googlesource.com/chromiumos/platform/minigbm";
    rev = "bc4f023bfcc51cf9dcfcfec5bf4177b2e607dd68";
    sha256 = "08ag207199xj5cw686386rmvr7sx2mzihdckm2pnvw743w03gipr";
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
