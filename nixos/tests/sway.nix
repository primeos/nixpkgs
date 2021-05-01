import ./make-test-python.nix ({ pkgs, lib, ...} :

{
  name = "sway";
  meta = {
    maintainers = with lib.maintainers; [ primeos ];
  };

  machine = { config, ... }: {
    imports = [ ./common/user-account.nix ];

    programs.sway.enable = true;

    virtualisation.memorySize = 1024;
    # Need to switch to a different VGA card / GPU driver than the default one (std) so that Sway can launch:
    virtualisation.qemu.options = [ "-vga virtio" ];
  };

  enableOCR = true;

  testScript = { nodes, ... }: let
    user = nodes.machine.config.users.users.alice;
    XDG_RUNTIME_DIR = "/run/user/${toString user.uid}";
  in ''
    def login_as_alice():
        machine.wait_until_tty_matches(1, "login: ")
        machine.send_chars("alice\n")
        machine.wait_until_tty_matches(1, "Password: ")
        machine.send_chars("foobar\n")
        machine.wait_until_tty_matches(1, "alice\@machine")


    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.succeed(
        "su - alice -c 'mkdir -p ~/.config/sway && sed s/Mod4/Mod1/ /etc/sway/config > ~/.config/sway/config'"
    )
    login_as_alice()
    machine.send_chars("sway\n")
    machine.wait_for_file("${XDG_RUNTIME_DIR}/wayland-1")
    machine.screenshot("empty_workspace")
    machine.sleep(10)
    machine.send_key("alt-ret")
    machine.wait_for_text("alice@machine")
    machine.screenshot("alacritty")
  '';
})
