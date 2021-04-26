{ lib, stdenv, llvm_meta
, src
, cmake
, libxml2
, llvm
, version
}:

stdenv.mkDerivation rec {
  pname = "lld";
  inherit version;

  inherit src;
  sourceRoot = "source/${pname}";

  nativeBuildInputs = [ cmake ];
  buildInputs = [ llvm libxml2 ];

  outputs = [ "out" "dev" ];

  postInstall = ''
    moveToOutput include "$dev"
    moveToOutput lib "$dev"
  '';

  meta = llvm_meta // {
    homepage = "https://lld.llvm.org/";
    description = "The LLVM linker";
    longDescription = ''
      LLD is a linker from the LLVM project that is a drop-in replacement for
      system linkers and runs much faster than them. It also provides features
      that are useful for toolchain developers.
      The linker supports ELF (Unix), PE/COFF (Windows), Mach-O (macOS) and
      WebAssembly in descending order of completeness. Internally, LLD consists
      of several different linkers.
    '';
  };
}
