{
  config,
  pkgs,
  lib,
  _domain_base,
  _smtp_address,
  _utils,
  ...
}:
let
  domain = "git.${_domain_base}";
  port = 3004;

  secrets = _utils.setupSecrets config {
    secrets = [
      "forgejo-smtp"
      "forgejo-oidc-shared-secret"
      "forgejo-runner-token"
    ];
    extra = {
      owner = "forgejo";
      group = "forgejo";
    };
  };
in
{
  imports = [
    secrets.generate
  ];

  services.openssh.settings.AcceptEnv = [ "GIT_PROTOCOL" ];

  services = {
    forgejo = {
      enable = true;
      package = pkgs.forgejo; # forgejo-lts by default

      database = {
        type = "postgres";
        createDatabase = true;
      };

      # Enable support for Git Large File Storage
      lfs.enable = true;
      settings = {
        DEFAULT.APP_NAME = "Lithium Forge";

        server = {
          DOMAIN = "${domain}";
          ROOT_URL = "https://${domain}/";
          HTTP_PORT = port;
          START_SSH_SERVER = false;
          BUILTIN_SSH_SERVER_USER = "forgejo";
        };

        cache = {
          ADAPTER = "twoqueue";
          HOST = ''{"size":100,"recent_ratio":0.25,"ghost_ratio":0.5}'';
        };

        oauth2 = {
          # providers are configured in the admin panel
          ENABLED = true;
        };

        # Authelia must be manually registered with
        # forgejo admin auth add-oauth \
        #     --name     authelia \
        #     --provider openidConnect \
        #     --key      ${client_id} \
        #     --secret   secret \
        #     --auto-discover-url ${sso.endpoint}/.well-known/openid-configuration
        #     --scopes='openid email profile groups'
        # It is automatically done using the preStart Systemd hook below

        authelia = {
          ENABLE_OPENID_SIGNIN = true;
          ENABLE_OPENID_SIGNUP = true;
        };

        service = {
          DISABLE_REGISTRATION = false;
          ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
          SHOW_REGISTRATION_BUTTON = false;
          ENABLE_INTERNAL_SIGNIN = false;
          ENABLE_BASIC_AUTHENTICATION = false;
          ENABLE_NOTIFY_MAIL = true;
        };

        # Add support for actions, based on act: https://github.com/nektos/act
        actions = {
          ENABLED = true;
          DEFAULT_ACTIONS_URL = "https://${domain}";
        };

        indexer = {
          REPO_INDEXER_ENABLED = true;
        };

        # You can send a test email from the web UI at:
        # Profile Picture > Site Administration > Configuration >  Mailer Configuration
        mailer = {
          ENABLED = true;
          FROM = "noreply@${_domain_base}";
          PROTOCOL = "smtp";
          SMTP_ADDR = _smtp_address;
          SMTP_PORT = 587;
          USER = "server@${_domain_base}";
        };
      };
      secrets.mailer.PASSWD = secrets.get "forgejo-smtp";
      stateDir = "/storage/forgejo";
    };

    gitea-actions-runner = {
      package = pkgs.forgejo-runner;
      instances.lithium = {
        enable = true;
        name = "lithium-runner";
        url = "https://${domain}/";
        tokenFile = secrets.get "forgejo-runner-token";
        labels = [
          "docker:docker://node:24-alpine"
          "alpine-latest:docker://node:24-alpine"
          "ubuntu-latest:docker://catthehacker/ubuntu:act-latest"
        ];

        settings = {
          log.level = "info";
          container.network = "bridge";
          runner = {
            capacity = 2;
            timeout = "5h";
            insecure = false;
          };
          session.COOKIE_SECURE = true;
        };
      };
    };
  };

  systemd.services = {
    # Auto register OIDC
    forgejo.preStart = ''
      auth="${lib.getExe config.services.forgejo.package} admin auth"

      echo "Trying to find existing SSO configuration"
      set +e -o pipefail
      id="$($auth list | grep "authelia.*OAuth2" |  cut -d'	' -f1)"
      found=$?
      set -e +o pipefail

      if [[ $found = 0 ]]; then
        echo Found sso configuration at id=$id, updating it
        $auth update-oauth \
          --id       $id \
          --name     authelia \
          --provider openidConnect \
          --key      SvETHomqH_6hOoZVLqZhKABkrkEMCJmltIOV8At-dznHOZyPDeG8stGCN_M5R0Ipy1wN2cBO \
          --secret   $(tr -d '\n' < ${secrets.get "forgejo-oidc-shared-secret"}) \
          --auto-discover-url https://auth.${_domain_base}/.well-known/openid-configuration \
          --scopes='openid email profile groups'
      else
        echo Did not find any SSO configuration, creating one
        $auth add-oauth \
          --name     authelia \
          --provider openidConnect \
          --key      SvETHomqH_6hOoZVLqZhKABkrkEMCJmltIOV8At-dznHOZyPDeG8stGCN_M5R0Ipy1wN2cBO \
          --secret   $(tr -d '\n' < ${secrets.get "forgejo-oidc-shared-secret"}) \
          --auto-discover-url https://auth.${_domain_base}/.well-known/openid-configuration \
          --scopes='openid email profile groups'
      fi
    '';

    # Takes the form of "gitea-runner-<instance>"
    gitea-runner-lithium = {
      # Prevents Forgejo runner deployments
      # from being restarted on a system switch,
      # thus breaking a deployment.
      # You'll have to restart the runner manually
      # or reboot the system after a deployment!
      restartIfChanged = false;

      path = with pkgs; [
        nix
        openssh
      ];

      serviceConfig = {
        MemoryMax = "4G";
        CPUQuota = "50%";
        Nice = 10;
      };

      wants = [ "forgejo.service" ];
      after = [ "forgejo.service" ];
    };
  };
}
