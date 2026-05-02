{
  pkgs,
  _domain_base,
  ...
}:
let
  matrix_server = {
    "m.server" = "matrix.lithium.ovh:443";
  };
  matrix_client = {
    "m.homeserver" = {
      base_url = "https://matrix.lithium.ovh";
    };
    "org.matrix.msc2965.authentication" = {
      issuer = "https://auth.lithium.ovh/";
      account = "https://mas.lithium.ovh/account";
    };
    "org.matrix.msc4143.rtc_foci" = [
      {
        type = "livekit";
        livekit_service_url = "https://matrix-rtc.lithium.ovh/livekit/jwt";
      }
    ];
  };

  cinny = pkgs.cinny.override {
    conf = {
      defaultHomeserver = 0;
      homeserverList = [
        "lithium.ovh"
        "onyx.ovh"
        "converser.eu"
        "matrix.org"
        "mozilla.org"
        "unredacted.org"
        "xmr.se"
      ];
    };
  };
in
{
  users.users."caddy".extraGroups = [
    "authelia-main"
  ];

  services.caddy = {
    enable = true;

    globalConfig = ''
      admin off
    '';

    extraConfig = ''
      (common) {
        encode zstd gzip
        header {
          Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
          X-Content-Type-Options "nosniff"
          # Doesn't work with FIDO2 Webauthn
          # X-Frame-Options "DENY"
          Referrer-Policy "strict-origin-when-cross-origin"
          Content-Security-Policy-Report-Only "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' wss: https:;"
          -Server
        }
      }

      (default_permissions) {
        header Permissions-Policy "accelerometer=(), autoplay=(), camera=(), display-capture=(), encrypted-media=(), fullscreen=(), geolocation=(), gyroscope=(), interest-cohort=(), magnetometer=(), microphone=(), midi=(), payment=(), picture-in-picture=(), publickey-credentials-get=(), sync-xhr=(), usb=(), xr-spatial-tracking=()"
      }

      (authelia_auth) {
        forward_auth unix//run/authelia/authelia.sock {
          uri /api/authz/forward-auth
          copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
        }
      }

      (custom_reverse_proxy) {
        reverse_proxy {args[:]} {
          header_up X-Real-IP {remote_host}
          header_up Cookie "authelia_session=[^;]+" "authelia_session=_"
        }
      }
    '';

    virtualHosts."https://${_domain_base}".extraConfig = ''
      import common
      import default_permissions

      handle /.well-known/matrix/* {
        header /.well-known/matrix/* Access-Control-Allow-Origin *
        header /.well-known/matrix/* Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
        header /.well-known/matrix/* Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization"
        header /.well-known/matrix/* Content-Type application/json

        respond /.well-known/matrix/server `${builtins.toJSON matrix_server}`
        respond /.well-known/matrix/client `${builtins.toJSON matrix_client}`
      }

      handle {
        import authelia_auth

        # header_up Cookie "authelia_session=[^;]+" "authelia_session=_"
        respond "hello world"
      }
    '';

    virtualHosts."https://auth.${_domain_base}".extraConfig = ''
      import common
      header Permissions-Policy "accelerometer=(), autoplay=(), camera=(), display-capture=(), encrypted-media=(), fullscreen=(), geolocation=(), gyroscope=(), interest-cohort=(), magnetometer=(), microphone=(), midi=(), payment=(), picture-in-picture=(), publickey-credentials-get=(self), sync-xhr=(), usb=(), xr-spatial-tracking=()"

      reverse_proxy unix//run/authelia/authelia.sock {
        header_up X-Real-IP {remote_host}
      }
    '';

    virtualHosts."https://dns.${_domain_base}".extraConfig = ''
      import authelia_auth
      import common
      import default_permissions

      import custom_reverse_proxy :3005
    '';

    virtualHosts."https://matrix-rtc.${_domain_base}".extraConfig = ''
      import common
      import default_permissions

      # Route for lk-jwt-service with livekit/jwt prefix
      @jwt_service path /livekit/jwt/sfu/get /livekit/jwt/healthz
      handle @jwt_service {
        uri strip_prefix /livekit/jwt
        import custom_reverse_proxy http://[::1]:8080
      }

      # Default route for livekit
      handle {
        import custom_reverse_proxy http://[::1]:7880
      }
    '';

    virtualHosts."https://cinny.${_domain_base}".extraConfig = ''
      import common
      header Permissions-Policy "accelerometer=(), autoplay=(self), camera=(self), display-capture=(self), encrypted-media=(), fullscreen=(self), geolocation=(), gyroscope=(), interest-cohort=(), magnetometer=(), microphone=(self), midi=(), payment=(), picture-in-picture=(self), publickey-credentials-get=(), sync-xhr=(), usb=(), xr-spatial-tracking=()"

      @static path_regexp static \.(js|css|woff2|png|svg|ico|webp)$
      header @static Cache-Control "public, max-age=31536000, immutable"

      root * ${cinny}
      try_files {path} /index.html
      file_server
    '';

    virtualHosts."https://matrix.${_domain_base}".extraConfig = ''
      import common
      import default_permissions

      # Forward login/logout/refresh to the auth service (MAS)
      @mas path_regexp ^/_matrix/client/(.*)/(login|logout|refresh)
      # Forward everything else Matrix-related to Synapse
      @synapse path_regexp ^(/_matrix|/_synapse/client|/_synapse/mas)

      route {
        # MAS routes (must be before @synapse since @synapse also matches /_matrix)
        import custom_reverse_proxy @mas localhost:8089

        # Synapse routes
        import custom_reverse_proxy @synapse localhost:8008

        handle {
          redir https://cinny.${_domain_base}{uri} 302
        }
      }

      request_body {
        max_size 50MB
      }
    '';

    virtualHosts."https://mas.${_domain_base}".extraConfig = ''
      import common
      import default_permissions

      import custom_reverse_proxy localhost:8089
    '';

    virtualHosts."${_domain_base}:8448".extraConfig = ''
      import common
      import default_permissions

      import custom_reverse_proxy /_matrix/* localhost:8008
      import custom_reverse_proxy /_synapse/client/* localhost:8008
    '';

    virtualHosts."https://git.${_domain_base}".extraConfig = ''
      import common
      header Permissions-Policy "accelerometer=(), autoplay=(), camera=(), display-capture=(), encrypted-media=(), fullscreen=(), geolocation=(), gyroscope=(), interest-cohort=(), magnetometer=(), microphone=(), midi=(), payment=(), picture-in-picture=(), publickey-credentials-get=(self), sync-xhr=(), usb=(), xr-spatial-tracking=()"

      import custom_reverse_proxy :3004
    '';

    virtualHosts."https://vaultwarden.${_domain_base}".extraConfig = ''
      import common
      header Permissions-Policy "accelerometer=(), autoplay=(), camera=(), display-capture=(), encrypted-media=(), fullscreen=(), geolocation=(), gyroscope=(), interest-cohort=(), magnetometer=(), microphone=(), midi=(), payment=(), picture-in-picture=(), publickey-credentials-get=(self), sync-xhr=(), usb=(), xr-spatial-tracking=()"

      import custom_reverse_proxy [::1]:8222
    '';

    virtualHosts."https://immich.${_domain_base}".extraConfig = ''
      import common
      header Permissions-Policy "accelerometer=(), autoplay=(self), camera=(), display-capture=(), encrypted-media=(), fullscreen=(self), geolocation=(), gyroscope=(), interest-cohort=(), magnetometer=(), microphone=(), midi=(), payment=(), picture-in-picture=(self), publickey-credentials-get=(), sync-xhr=(), usb=(), xr-spatial-tracking=()"

      import custom_reverse_proxy :2283
    '';

    virtualHosts."https://hass.${_domain_base}".extraConfig = ''
      import authelia_auth
      import common
      import default_permissions

      import custom_reverse_proxy localhost:8123
    '';

    virtualHosts."https://grafana.${_domain_base}".extraConfig = ''
      import authelia_auth
      import common
      import default_permissions

      import custom_reverse_proxy localhost:3000
    '';

    virtualHosts."https://cloud.${_domain_base}".extraConfig = ''
      import common
      # import default_permissions

      import custom_reverse_proxy localhost:8086
    '';

    virtualHosts."https://thread.${_domain_base}".extraConfig = ''
      import authelia_auth
      import common
      import default_permissions

      import custom_reverse_proxy localhost:8082
    '';
  };
}
