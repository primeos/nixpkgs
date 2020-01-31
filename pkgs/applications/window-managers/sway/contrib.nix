{ stdenv, sway-unwrapped, python3
, grim, slurp, sway, wl-clipboard, jq, libnotify, coreutils
}:

stdenv.mkDerivation {
  pname = "sway-contrib";
  version = sway-unwrapped.version;

  src = sway-unwrapped.src;

  nativeBuildInputs = [ python3 python3.pkgs.wrapPython ];
  pythonPath = with python3.pkgs; [ i3ipc ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    cd contrib
    install -Dt $out/bin autoname-workspaces.py grimshot inactive-windows-transparency.py
  '';

  preFixup = ''
    patchShebangs $out/bin
    wrapProgram $out/bin/grimshot --set PATH \
      "${stdenv.lib.makeBinPath [ grim slurp sway wl-clipboard jq libnotify coreutils ]}"
    wrapPythonPrograms
  '';

  meta = sway-unwrapped.meta // {
    description = "Extra tools for Sway";
    homepage    = "https://github.com/swaywm/sway/tree/${sway-unwrapped.version}/contrib";
  };
}
