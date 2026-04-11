{
  config,
  _utils,
  _domain_base,
  _smtp_address,
  ...
}:
let
  secrets = _utils.setupSecrets config {
    secrets = [
      "authelia-config"
      "authelia-jwt"
      "authelia-storage"
      "authelia-oauth2"
      "authelia-oauth2-hmac"
      "smtp"
    ];
    extra = {
      owner = "authelia-main";
      group = "authelia-main";
    };
  };
in
{
  imports = [
    secrets.generate
  ];

  services.postgresql = {
    ensureDatabases = [ "authelia-main" ];
    ensureUsers = [
      {
        name = "authelia-main";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services."authelia-main" = {
    environment = {
      # needed to set the secrets using agenix see: https://www.authelia.com/configuration/methods/files/#file-filters
      X_AUTHELIA_CONFIG_FILTERS = "template";
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = secrets.get "smtp";
    };
    serviceConfig = {
      RuntimeDirectory = "authelia";
      RuntimeDirectoryMode = 775;
    };
  };

  services.authelia = {
    instances.main = {
      enable = true;
      secrets = {
        storageEncryptionKeyFile = secrets.get "authelia-storage";
        jwtSecretFile = secrets.get "authelia-jwt";
        oidcIssuerPrivateKeyFile = secrets.get "authelia-oauth2";
        oidcHmacSecretFile = secrets.get "authelia-oauth2-hmac";
      };
      settings = {
        theme = "auto";

        webauthn = {
          disable = false;
          display_name = "Authelia";
          attestation_conveyance_preference = "indirect";
          timeout = "60s";
          selection_criteria.user_verification = "preferred";
        };

        regulation = {
          max_retries = 3;
          find_time = "10m";
          ban_time = "30m";
        };

        totp = {
          disable = false;
          issuer = _domain_base;
          algorithm = "sha1";
          digits = 6;
          period = 30;
          skew = 1;
          secret_size = 32;
          allowed_algorithms = [ "SHA1" ];
          allowed_digits = [ 6 ];
          allowed_periods = [ 30 ];
          disable_reuse_security_policy = false;
        };

        server = {
          address = "unix:///run/authelia/authelia.sock?umask=0117";
          endpoints = {
            authz = {
              forward-auth = {
                implementation = "ForwardAuth";
              };
            };
          };
        };
        log = {
          format = "text";
          file_path = "/var/lib/authelia-main/authelia.log";
          keep_stdout = true;
          level = "info";
        };

        storage = {
          postgres = {
            address = "/run/postgresql";
            database = "authelia-main";
            username = "authelia-main";
          };
        };

        notifier = {
          smtp = {
            address = "smtp://${_smtp_address}:587";
            timeout = "15s";
            username = "server@${_domain_base}";
            sender = "Authelia <server@${_domain_base}>";
            subject = "[Authelia] {title}";
            disable_require_tls = false;
            disable_starttls = false;
            disable_html_emails = false;
          };
        };

        access_control = {
          default_policy = "deny";
          rules = [
            {
              domain = _domain_base;
              policy = "two_factor";
              subject = [ "group:owner" ];
            }

            {
              domain = "auth.${_domain_base}";
              policy = "one_factor";
            }

            {
              domain = "dns.${_domain_base}";
              policy = "two_factor";
              subject = [
                "group:owner"
                "group:dns"
              ];
            }
          ];
        };

        authentication_backend = {
          password_reset.disable = true;
          password_change.disable = true;
          file = {
            path = secrets.get "authelia-config";
          };
        };

        session = {
          cookies = [
            {
              domain = _domain_base;
              authelia_url = "https://auth.${_domain_base}";
              default_redirection_url = "https://${_domain_base}";
              inactivity = "30m";
              expiration = "12h";
              remember_me = "7d";
            }
          ];
        };

        identity_providers.oidc = {
          authorization_policies = {
            matrix_policy = {
              default_policy = "deny";
              rules = [
                {
                  policy = "two_factor";
                  subject = [
                    "group:owner"
                    "group:matrix"
                  ];
                }
              ];
            };

            forgejo_policy = {
              default_policy = "deny";
              rules = [
                {
                  policy = "two_factor";
                  subject = [
                    "group:owner"
                    "group:forgejo"
                  ];
                }
              ];
            };

            immich_policy = {
              default_policy = "deny";
              rules = [
                {
                  policy = "two_factor";
                  subject = [
                    "group:owner"
                    "group:immich"
                  ];
                }
              ];
            };
          };
          clients = [
            {
              client_id = "IkhbiLxn.MQVKQeBFAlvMfu3-RdUMScM0PcnpDSyjSTGwjs0VGveq_yii.GOavtNyoZYC9U6";
              client_name = "Matrix";
              client_secret = "$pbkdf2-sha512$310000$XTfwKsUrL8t49jUidXws3A$o3B8DWtgQkSdYje8HKmFIqY/luftDyTSgPD7kHATJrhVDoq40.47iIvwIooNVA3jguKuf7zQ21PtA.AseGQUNA";
              public = false;
              authorization_policy = "matrix_policy";
              redirect_uris = [
                "https://mas.${_domain_base}/upstream/callback/01KJKAM7BDPSYJDN4YXSZQYX1H"
              ];
              scopes = [
                "openid"
                "groups"
                "profile"
                "email"
                "offline_access"
              ];
              grant_types = [
                "refresh_token"
                "authorization_code"
              ];
              response_types = [ "code" ];
            }
            {
              client_id = "SvETHomqH_6hOoZVLqZhKABkrkEMCJmltIOV8At-dznHOZyPDeG8stGCN_M5R0Ipy1wN2cBO";
              client_name = "Forgejo";
              client_secret = "$pbkdf2-sha512$310000$MAAzIWeSBuNk/3m5tNrWEQ$g/b7TvzLzswZ5wK3nYwXMDBZmQ4bVp18cRxWc4Z/.oKm5S8I2lf3MxV4oNmb5.w4UQVY854tidWxeV27boLDZg";
              public = false;
              authorization_policy = "forgejo_policy";
              require_pkce = true;
              pkce_challenge_method = "S256";
              redirect_uris = [ "https://git.${_domain_base}/user/oauth2/authelia/callback" ];
              scopes = [
                "openid"
                "email"
                "profile"
                "groups"
              ];
              grant_types = [ "authorization_code" ];
              access_token_signed_response_alg = "none";
              userinfo_signed_response_alg = "none";
              token_endpoint_auth_method = "client_secret_basic";
            }
            {
              client_id = "CUkbjHcjkc9K4ZyCdcnaYwdub66eY5F-BJScctEVS5DBTeUp954ZzWNnAbbGWCIGv1Xi58Nf";
              client_name = "Immich";
              client_secret = "$pbkdf2-sha512$310000$t6weBk.826ThdRzBzIwbYg$.uvokVpsnWxBoL9RYSWOpRAmH282KdgL/Kn3gWtplzix86xfIBc6WKp9D8monyMW4bZ3Zn8a2m4qjiKhaN8xGg";
              public = false;
              authorization_policy = "immich_policy";
              require_pkce = false;
              pkce_challenge_method = "";
              redirect_uris = [
                "https://immich.${_domain_base}/auth/login"
                "https://immich.${_domain_base}/user-settings"
                "app.immich:///oauth-callback"
              ];
              scopes = [
                "openid"
                "email"
                "profile"
              ];
              response_types = [ "code" ];
              grant_types = [ "authorization_code" ];
              access_token_signed_response_alg = "RS256";
              userinfo_signed_response_alg = "RS256";
              token_endpoint_auth_method = "client_secret_post";
            }
          ];
        };
      };
    };
  };
}
