{ lowPrio, newScope, pkgs, lib, stdenv, cmake, gccForLibs
, libxml2, python3, isl, fetchFromGitHub, overrideCC, wrapCCWith, wrapBintoolsWith
, buildPackages
, buildLlvmTools # tools, but from the previous stage, for cross
, targetLlvmLibraries # libraries, but from the next stage, for cross
, darwin
}:

let
  release_version = "12.0.0";
  candidate = ""; # empty or "rcN"
  dash-candidate = lib.optionalString (candidate != "") "-${candidate}";
  version = "${release_version}${dash-candidate}"; # differentiating these (variables) is important for RCs
  targetConfig = stdenv.targetPlatform.config;

  src = fetchFromGitHub {
    owner = "llvm";
    repo = "llvm-project";
    rev = "llvmorg-${version}";
    sha256 = "07jz8pywc2qqa1srdnqg5p2y4lx3ki1inpigarzgxc3j20r4gb58";
  };

  llvm_meta = {
    license     = lib.licenses.ncsa;
    maintainers = with lib.maintainers; [ lovek323 raskin dtzWill primeos ];
    platforms   = lib.platforms.all;
  };

  tools = lib.makeExtensible (tools: let
    callPackage = newScope (tools // { inherit stdenv cmake libxml2 python3 isl release_version version src; });
    mkExtraBuildCommands = cc: ''
      rsrc="$out/resource-root"
      mkdir "$rsrc"
      ln -s "${cc}/lib/clang/${release_version}/include" "$rsrc"
      ln -s "${targetLlvmLibraries.compiler-rt.out}/lib" "$rsrc/lib"
      ln -s "${targetLlvmLibraries.compiler-rt.out}/share" "$rsrc/share"
      echo "-resource-dir=$rsrc" >> $out/nix-support/cc-cflags
    '';

  in {

    llvm = callPackage ./llvm {
      inherit llvm_meta;
    };

    clang-unwrapped = callPackage ./clang {
      inherit (tools) lld;
      inherit llvm_meta;
    };

    # disabled until recommonmark supports sphinx 3
    #Llvm-manpages = lowPrio (tools.llvm.override {
    #  enableManpages = true;
    #  python3 = pkgs.python3;  # don't use python-boot
    #});

    clang-manpages = lowPrio (tools.clang-unwrapped.override {
      enableManpages = true;
      python3 = pkgs.python3;  # don't use python-boot
    });

    # disabled until recommonmark supports sphinx 3
    # lldb-manpages = lowPrio (tools.lldb.override {
    #   enableManpages = true;
    #   python3 = pkgs.python3;  # don't use python-boot
    # });

    libclang = tools.clang-unwrapped.lib;

    clang = if stdenv.cc.isGNU then tools.libstdcxxClang else tools.libcxxClang;

    libstdcxxClang = wrapCCWith rec {
      cc = tools.clang-unwrapped;
      # libstdcxx is taken from gcc in an ad-hoc way in cc-wrapper.
      libcxx = null;
      extraPackages = [
        targetLlvmLibraries.compiler-rt
      ];
      extraBuildCommands = mkExtraBuildCommands cc;
    };

    libcxxClang = wrapCCWith rec {
      cc = tools.clang-unwrapped;
      libcxx = targetLlvmLibraries.libcxx;
      extraPackages = [
        targetLlvmLibraries.libcxxabi
        targetLlvmLibraries.compiler-rt
      ];
      extraBuildCommands = mkExtraBuildCommands cc;
    };

    lld = callPackage ./lld {
      inherit llvm_meta;
    };

    lldb = callPackage ./lldb {
      inherit llvm_meta;
      inherit (darwin) libobjc bootstrap_cmds;
      inherit (darwin.apple_sdk.libs) xpc;
      inherit (darwin.apple_sdk.frameworks) Foundation Carbon Cocoa;
    };

    # Below, is the LLVM bootstrapping logic. It handles building a
    # fully LLVM toolchain from scratch. No GCC toolchain should be
    # pulled in. As a consequence, it is very quick to build different
    # targets provided by LLVM and we can also build for what GCC
    # doesn’t support like LLVM. Probably we should move to some other
    # file.

    bintools = callPackage ./bintools {};

    lldClang = wrapCCWith rec {
      cc = tools.clang-unwrapped;
      libcxx = targetLlvmLibraries.libcxx;
      bintools = wrapBintoolsWith {
        inherit (tools) bintools;
      };
      extraPackages = [
        targetLlvmLibraries.libcxxabi
        targetLlvmLibraries.compiler-rt
      ] ++ lib.optionals (!stdenv.targetPlatform.isWasm) [
        targetLlvmLibraries.libunwind
      ];
      extraBuildCommands = ''
        echo "-rtlib=compiler-rt -Wno-unused-command-line-argument" >> $out/nix-support/cc-cflags
        echo "-B${targetLlvmLibraries.compiler-rt}/lib" >> $out/nix-support/cc-cflags
      '' + lib.optionalString (!stdenv.targetPlatform.isWasm) ''
        echo "--unwindlib=libunwind" >> $out/nix-support/cc-cflags
      '' + lib.optionalString stdenv.targetPlatform.isWasm ''
        echo "-fno-exceptions" >> $out/nix-support/cc-cflags
      '' + mkExtraBuildCommands cc;
    };

    lldClangNoLibcxx = wrapCCWith rec {
      cc = tools.clang-unwrapped;
      libcxx = null;
      bintools = wrapBintoolsWith {
        inherit (tools) bintools;
      };
      extraPackages = [
        targetLlvmLibraries.compiler-rt
      ];
      extraBuildCommands = ''
        echo "-rtlib=compiler-rt" >> $out/nix-support/cc-cflags
        echo "-B${targetLlvmLibraries.compiler-rt}/lib" >> $out/nix-support/cc-cflags
        echo "-nostdlib++" >> $out/nix-support/cc-cflags
      '' + mkExtraBuildCommands cc;
    };

    lldClangNoLibc = wrapCCWith rec {
      cc = tools.clang-unwrapped;
      libcxx = null;
      bintools = wrapBintoolsWith {
        inherit (tools) bintools;
        libc = null;
      };
      extraPackages = [
        targetLlvmLibraries.compiler-rt
      ];
      extraBuildCommands = ''
        echo "-rtlib=compiler-rt" >> $out/nix-support/cc-cflags
        echo "-B${targetLlvmLibraries.compiler-rt}/lib" >> $out/nix-support/cc-cflags
      '' + mkExtraBuildCommands cc;
    };

    lldClangNoCompilerRt = wrapCCWith {
      cc = tools.clang-unwrapped;
      libcxx = null;
      bintools = wrapBintoolsWith {
        inherit (tools) bintools;
        libc = null;
      };
      extraPackages = [ ];
      extraBuildCommands = ''
        echo "-nostartfiles" >> $out/nix-support/cc-cflags
      '';
    };

  });

  libraries = lib.makeExtensible (libraries: let
    callPackage = newScope (libraries // buildLlvmTools // { inherit stdenv cmake libxml2 python3 isl release_version version src; });
  in {

    compiler-rt = callPackage ./compiler-rt ({ inherit llvm_meta; } //
      (lib.optionalAttrs (stdenv.hostPlatform.useLLVM or false) {
        stdenv = overrideCC stdenv buildLlvmTools.lldClangNoCompilerRt;
      }));

    stdenv = overrideCC stdenv buildLlvmTools.clang;

    libcxxStdenv = overrideCC stdenv buildLlvmTools.libcxxClang;

    libcxx = callPackage ./libcxx ({ inherit llvm_meta; } //
      (lib.optionalAttrs (stdenv.hostPlatform.useLLVM or false) {
        stdenv = overrideCC stdenv buildLlvmTools.lldClangNoLibcxx;
      }));

    libcxxabi = callPackage ./libcxxabi ({ inherit llvm_meta; } //
      (lib.optionalAttrs (stdenv.hostPlatform.useLLVM or false) {
        stdenv = overrideCC stdenv buildLlvmTools.lldClangNoLibcxx;
        libunwind = libraries.libunwind;
      }));

    openmp = callPackage ./openmp { inherit llvm_meta; };

    libunwind = callPackage ./libunwind ({ inherit llvm_meta; } //
      (lib.optionalAttrs (stdenv.hostPlatform.useLLVM or false) {
        stdenv = overrideCC stdenv buildLlvmTools.lldClangNoLibcxx;
      }));

  });

in { inherit tools libraries; } // libraries // tools
