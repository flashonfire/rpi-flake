{
  config,
  _domain_base,
  _utils,
  ...
}:
let
  secrets = _utils.setupSecrets config {
    secrets = [
      "grafana/secret_key"
    ];
    extra = {
      owner = "grafana";
      group = "grafana";
    };
  };
in
{
  imports = [
    secrets.generate
  ];

  systemd.tmpfiles.rules = [
    "d /storage/grafana 0750 grafana grafana - -"
  ];

  services.grafana = {
    enable = true;
    dataDir = "/storage/grafana";

    settings = {
      server = {
        http_port = 3000;
        domain = "grafana.${_domain_base}";
      };
      database = {
        type = "postgres";
        host = "/run/postgresql";
        name = "grafana";
        user = "grafana";
      };
      auth = {
        disable_login_form = true;
      };
      security.secret_key = "$__file{${secrets.get "grafana/secret_key"}}";
      analytics.reporting_enabled = false;
    };
  };

  services.postgresql.ensureUsers = [
    {
      name = "grafana";
      ensureDBOwnership = true;
    }
  ];
  services.postgresql.ensureDatabases = [ "grafana" ];
}
