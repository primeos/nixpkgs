{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "mattermost-${version}";
  version = "3.6.2";

  src = fetchFromGitHub {
    owner = "mattermost";
    repo = "platform";
    rev = "v${version}";
    sha256 = "1c7msfl49mfik1c0bjd51df01hylxk8sx29206f00hnd8nax71i0";
  };

#  installPhase = ''
#    mkdir -p $out
#    mv * $out/
#    ln -s ./platform $out/bin/mattermost-platform
#  '';
#
#  postFixup = ''
#    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/platform
#  '';

  meta = with stdenv.lib; {
    description = "Open-Source, self-hosted Slack-alternative";
    homepage = "https://www.mattermost.org";
    license = with licenses; [ agpl3 asl20 ];
    maintainers = with maintainers; [ fpletz ];
    platforms = [ "x86_64-linux" ];
  };
}
