{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.sks;
  pkg = pkgs.sks;

  sksCfg = pkgs.writeText "sksconf"
    ''
      #  sksconf -- SKS main configuration

      basedir: ${cfg.dataDir}

      hostname: ${cfg.hostname}

      hkp_address: ${concatStringsSep " " cfg.hkpAddr}
      hkp_port: ${toString cfg.hkpPort}

      recon_address: ${concatStringsSep " " cfg.reconAddr}
      recon_port: ${toString cfg.reconPort}

      ${sksAdditionalCfg}
    '';

  sksAdditionalCfg = ''
    # debuglevel 3 is default (max. debuglevel is 10)
    debuglevel: 3

    # Run database statistics calculation on boot and at 04:00h
    # Can be manually triggered with the USR2 signal.
    initial_stat:
    stat_hour: 4

    # TODO
    #server_contact: 0xDECAFBADDEADBEEF
    #from_addr: pgp-public-keys@example.tld
    #sendmail_cmd: /usr/sbin/sendmail -t -oi

    # Standalone server for now
    disable_mailsync:
    membership_reload_interval:	1

    # set DB file pagesize as recommended by db_tuner
    # pagesize is (n * 512) bytes
    # NOTE: These must be set _BEFORE_ [fast]build & pbuild and remain set
    # for the life of the database files. To change a value requires recreating
    # the database from a dump

    # KDB/key 65536
    pagesize: 128

    # KDB/keyid 32768
    keyid_pagesize: 64

    # KDB/meta 512
    meta_pagesize: 1

    # KDB/subkeyid 65536
    subkeyid_pagesize: 128

    # KDB/time 65536
    time_pagesize: 128

    # KDB/tqueue 512
    tqueue_pagesize: 1

    # KDB/word - db_tuner suggests 512 bytes. This locked the build process
    # Better to use a default of 8 (4096 bytes) for now
    #word_pagesize: 8

    # PTree/ptree 4096
    ptree_pagesize: 8
  '';

  dbCfg = pkgs.writeText "DB_CONFIG"
    ''
      set_mp_mmapsize  268435456
      set_cachesize    0 134217728 1
      set_flags        DB_LOG_AUTOREMOVE
      set_lg_regionmax 1048576
      set_lg_max       104857600
      set_lg_bsize     2097152
      set_lk_detect    DB_LOCK_DEFAULT
      set_tmp_dir      /tmp
      set_lock_timeout 1000
      set_txn_timeout  1000
      mutex_set_max    65536
    '';
in
{
###### interface
  options = {
    services.sks = {

      enable = mkEnableOption "Whether to enable sks (synchronizing key server
      for OpenPGP) and start the database server";

      enableRecon = mkEnableOption "Whether to enable the reconciliation server
      of sks";

      dataDir = mkOption {
        description = ''
          Data directory (-basedir) for sks, where the database and all
          configuration files are located (e.g. KDB, PTree, membership and
          sksconf).
        '';
        type = types.path;
        default = "/var/lib/sks";
      };

      # TODO: default =
      # "\${config.networking.hostName}.\${config.networking.domain}";?
      hostname = mkOption {
        description = "The hostname (should be the public facing FQDN if
        available) used for sks.";
        type = types.str;
        default = "localhost";
        example = "keyserver.example.com";
      };

     # TODO: "hkpAddr", "hkpListenAddress" or "hkp.listenAddress"?
     hkpAddr = mkOption {
        description = "Domain names, IPv4 and/or IPv6 addresses to listen on
        for HKP requests.";
        type = types.listOf types.str;
        default = [ "127.0.0.1" "::1" ];
      };

      hkpPort = mkOption {
        description = "HKP port to listen on.";
        type = types.int;
        default = 11371;
      };

     reconAddr = mkOption {
        description = "Domain names, IPv4 and/or IPv6 addresses to listen on.";
        type = types.listOf types.str;
        default = [ "127.0.0.1" "::1" ];
      };

      reconPort = mkOption {
        description = "Recon port to listen on.";
        type = types.int;
        default = 11370;
      };

      additionalConfig = mkOption {
        description = "Provide additional sks configuration options which will
        be appended to the main configuration (sksconf). See \"ADDITIONAL
        OPTIONS\" in \"man sks\" for all available options.";
        type = lib.types.lines;
        default = sksAdditionalCfg;
      };

      sksconfFile = mkOption {
        description = "Derivation for the main configuration file of sks. You
        can use this option to replace the default configuration, however it's
        recommended to use the options provided by this module instead and use
        the \"additionalConfig\" option for options not implemented by this
        module.";
        type = lib.types.lines;
        default = sksCfg;
        defaultText = "sks configuration file";
      };
    };
  };
###### implementation
  config = mkMerge
  [
    (mkIf cfg.enable {

      environment.systemPackages = [ pkg ];

      users.extraUsers."sks" = {
        description = "SKS keyserver user";
        uid = config.ids.uids.sks;
        group = "sks";
        home = cfg.dataDir;
        createHome  = true;
      };

      users.extraGroups = [{
        name = "sks";
        gid = config.ids.gids.sks;
      }];

      systemd.services."sks-db" = {
        description = "SKS database server";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkg}/bin/sks db -basedir ${cfg.dataDir}";
          WorkingDirectory = cfg.dataDir;
          User = "sks";
        };
        preStart = ''
          ln -fsn ${sksCfg} ${cfg.dataDir}/sksconf
          ln -fsn ${dbCfg} ${cfg.dataDir}/DB_CONFIG

          if ! test -e ${cfg.dataDir}/KDB; then
            ${pkg}/bin/sks build -basedir ${cfg.dataDir}
          fi
        '';
      };
    })

    (mkIf (cfg.enable && cfg.enableRecon) {

      systemd.services."sks-recon" = {
        description = "SKS reconciliation server";
        after = [ "sks-db.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkg}/bin/sks recon -basedir ${cfg.dataDir}";
          WorkingDirectory = cfg.dataDir;
          User = "sks";
        };
      };
    })
  ];

  meta = {
    maintainers = with maintainers; [ primeos jcumming ];
  };
}
