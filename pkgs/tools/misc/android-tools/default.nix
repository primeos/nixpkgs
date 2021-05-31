{ lib, stdenv, fetchurl, buildGoModule
, cmake, perl, go
, protobuf, zlib, gtest, brotli, lz4, zstd, libusb1, pcre2
}:

let
  pname = "android-tools";
  version = "31.0.0p1";
  src = fetchurl {
    url = "https://github.com/nmeum/android-tools/releases/download/${version}/android-tools-${version}.tar.xz";
    sha256 = "1dn7v10gdx1pi0pkddznd5sdz941qz0x4jww8h2mk50nbyxc792i";
  };
  boringsslGoModules = (buildGoModule {
    inherit pname version;
    inherit src;
    modRoot = "vendor/boringssl";
    vendorSha256 = "0w690j49mhd1ssrf8ls47s5q5y5v1pnjmnvcyyxk5nfjadcmbq97";
  }).go-modules;
in stdenv.mkDerivation rec {
  inherit pname version;

  inherit src;
  postPatch = ''
    cp -r --reflink=auto ${boringsslGoModules} vendor/boringssl/vendor
  '';

  nativeBuildInputs = [ cmake perl go ];
  buildInputs = [ protobuf zlib gtest brotli lz4 zstd libusb1 pcre2 ];

  GOFLAGS = [ "-mod=vendor" ];

  meta = with lib; {
    description = "Android SDK platform tools";
    longDescription = ''
      Android SDK Platform-Tools is a component for the Android SDK. It
      includes tools that interface with the Android platform, such as adb and
      fastboot. These tools are required for Android app development. They're
      also needed if you want to unlock your device bootloader and flash it
      with a new system image.
      Currently the following tools are supported:
      - adb
      - fastboot
      - mke2fs.android (required by fastboot)
      - simg2img, img2simg, append2simg
    '';
    # https://developer.android.com/studio/command-line#tools-platform
    # https://developer.android.com/studio/releases/platform-tools
    homepage = "https://github.com/nmeum/android-tools";
    license = with licenses; [ asl20 ];
    platforms = platforms.unix;
    maintainers = with maintainers; [ primeos ];
  };
}
