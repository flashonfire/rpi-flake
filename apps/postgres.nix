{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    postgres.initialScripts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };
  config = {
    systemd.tmpfiles.rules = [
      "d /storage/postgresql 0750 postgres postgres - -"
    ];

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_18;

      dataDir = "/storage/postgresql";

      enableTCPIP = false;

      settings.max_connections = 25;

      # local synapse synapse scram-sha-256
      authentication = ''
        local sameuser all peer
        local all postgres peer
      '';

      initialScript = pkgs.writeText "postgres-init-script.sql" (
        lib.concatStrings (config.postgres.initialScripts or [ ])
      );
    };
  };
}
