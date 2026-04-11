{
  config,
  _domain_base,
  _utils,
  ...
}:
let
  secrets = _utils.setupSecrets config {
    secrets = [
      "synapse-signingKey"
      "synapse-masSharedSecret"
    ];
    extra = {
      owner = "matrix-synapse";
      group = "matrix-synapse";
    };
  };
in
{
  imports = [
    secrets.generate
  ];

  systemd.tmpfiles.rules = [
    "d /storage/matrix-synapse 0750 matrix-synapse matrix-synapse - -"
  ];

  services.matrix-synapse = {
    enable = true;

    dataDir = "/storage/matrix-synapse";

    settings = {
      server_name = _domain_base;
      public_baseurl = "https://matrix.${_domain_base}";
      signing_key_path = secrets.get "synapse-signingKey";

      enable_registration = false;
      url_preview_enabled = true;
      delete_stale_devices_after = "90d";

      federation_client_minimum_tls_version = "1.2";
      max_upload_size = "100M";
      max_event_delay_duration = "24h";

      database = {
        name = "psycopg2";
        args = {
          database = "matrix-synapse";
          user = "matrix-synapse";
        };
      };

      listeners = [
        {
          bind_addresses = [ "::1" ];
          port = 8008;
          x_forwarded = true;
          tls = false;
          resources = [
            {
              names = [
                "client" # implies ["media" "static"]
                "federation" # implies ["media" "keys"]
              ];
            }
          ];
        }
      ];

      experimental_features = {
        msc3266_enabled = true; # room summary api;
        msc4222_enabled = true; # syncv2 state_after
      };

      # relax rate limits, required for element-call
      rc_message = {
        per_second = 0.5;
        burst_count = 30;
      };
      rc_delayed_event_mgmt = {
        per_second = 1;
        burst_count = 20;
      };

      matrix_authentication_service = {
        enabled = true;
        endpoint = "http://localhost:8089";
        secret_path = secrets.get "synapse-masSharedSecret";
      };

      trusted_key_servers = [
        {
          server_name = "matrix.org";
          verify_keys = {
            "ed25519:auto" = "Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw";
          };
        }
      ];

      suppress_key_server_warning = true;
    };
  };

  postgres.initialScripts = [
    ''
      CREATE USER "matrix-synapse";
      CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
        TEMPLATE template0
        LC_COLLATE = "C"
        LC_CTYPE = "C";
    ''
  ];
}
