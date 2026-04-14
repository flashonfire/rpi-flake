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
      "grafana/oidc_secret"
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
        http_addr = "127.0.0.1";
        http_port = 3000;
        root_url = "https://grafana.${_domain_base}";
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

      "auth.generic_oauth" = {
        enabled = true;
        name = "Authelia";
        icon = "signing";
        client_id = "jsoV4vPZJEM2E77mHNrqg1O0B223Tte82YuRosj0cz5pJBZyiDawH-kioHPr7xX-AUoM34pt";
        client_secret = "$__file{${secrets.get "grafana/oidc_secret"}}";
        scopes = "openid profile email groups";
        empty_scopes = false;
        auth_url = "https://auth.${_domain_base}/api/oidc/authorization";
        token_url = "https://auth.${_domain_base}/api/oidc/token";
        api_url = "https://auth.${_domain_base}/api/oidc/userinfo";
        login_attribute_path = "preferred_username";
        groups_attribute_path = "groups";
        use_pkce = true;
        role_attribute_path = "contains(groups[*], 'grafana_admin') && 'Admin' || contains(groups[*], 'grafana_editor') && 'Editor' || 'Viewer'";
        # allow_sign_up = true;
        # auto_login = true;
      };
      security = {
        secret_key = "$__file{${secrets.get "grafana/secret_key"}}";
        disable_initial_admin_creation = false;
      };
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
