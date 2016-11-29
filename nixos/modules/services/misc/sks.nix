{ config, lib, pkgs, ... }:

with lib;

let
  pkg = pkgs.sks;
  cfg = config.services.sks;
in
{
###### interface
  options = {
    services.sks = {
      enable = mkEnableOption "Synchronizing Key Server";
      dataDir = mkOption {
        type = types.string;
        default = "/var/lib/sks";
        description = ''
          -basedir for sks, where KDB, PTree, membership and sksconf are located
        '';
      };
    };
  };
###### implementation
  config = mkIf cfg.enable {

    users.extraUsers = singleton {
      name = "sks";
      uid = config.ids.uids.sks;
      description = "SKS daemon user";
      home = "/var/empty";
    };

    users.extraGroups = singleton {
      name = "sks";
      gid = config.ids.gids.sks;
    };

    systemd.services."sks-db" = {
      description = "SKS db Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkg}/bin/sks db -basedir ${cfg.dataDir}";
        User = "sks";
      };
    };

    systemd.services."sks-recon" = {
      description = "SKS gossip Server";
      after = [ "sks-db.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkg}/bin/sks recon -basedir ${cfg.dataDir}";
        User = "sks";
      };
    };
  };
}
