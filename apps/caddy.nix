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

    virtualHosts."https://${_domain_base}".extraConfig = ''
      handle /.well-known/matrix/* {
        header /.well-known/matrix/* Access-Control-Allow-Origin *
        header /.well-known/matrix/* Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
        header /.well-known/matrix/* Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization"
        header /.well-known/matrix/* Content-Type application/json

        respond /.well-known/matrix/server `${builtins.toJSON matrix_server}`
        respond /.well-known/matrix/client `${builtins.toJSON matrix_client}`
      }

      handle {
        forward_auth unix//run/authelia/authelia.sock {
          uri /api/authz/forward-auth
          ## The following commented line is for configuring the Authelia URL in the proxy. We strongly suggest
          ## this is configured in the Session Cookies section of the Authelia configuration.
          # uri /api/authz/forward-auth?authelia_url=https://auth.example.com/
          copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
        }

        # header_up Cookie "authelia_session=[^;]+" "authelia_session=_"
        respond "hello world"
      }
    '';

    virtualHosts."https://auth.${_domain_base}".extraConfig = ''
      reverse_proxy unix//run/authelia/authelia.sock {
        header_down X-Real-IP {http.request.remote}
        header_down X-Forwarded-For {http.request.remote}
      }
    '';

    virtualHosts."https://dns.${_domain_base}".extraConfig = ''
      forward_auth unix//run/authelia/authelia.sock {
        uri /api/authz/forward-auth
        ## The following commented line is for configuring the Authelia URL in the proxy. We strongly suggest
        ## this is configured in the Session Cookies section of the Authelia configuration.
        # uri /api/authz/forward-auth?authelia_url=https://auth.example.com/
        copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
      }

      reverse_proxy :3005 {
        header_up Cookie "authelia_session=[^;]+" "authelia_session=_"
      }
    '';

    virtualHosts."https://office.${_domain_base}".extraConfig = ''
      forward_auth unix//run/authelia/authelia.sock {
        uri /api/authz/forward-auth
        ## The following commented line is for configuring the Authelia URL in the proxy. We strongly suggest
        ## this is configured in the Session Cookies section of the Authelia configuration.
        # uri /api/authz/forward-auth?authelia_url=https://auth.example.com/
        copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
      }

      reverse_proxy :8000 {
        header_up Cookie "authelia_session=[^;]+" "authelia_session=_"
      }
    '';

    virtualHosts."https://matrix-rtc.${_domain_base}".extraConfig = ''
      # Route for lk-jwt-service with livekit/jwt prefix
      @jwt_service path /livekit/jwt/sfu/get /livekit/jwt/healthz
      handle @jwt_service {
        uri strip_prefix /livekit/jwt
        reverse_proxy http://[::1]:8080 {
          header_up Host {host}
          header_up X-Forwarded-Server {host}
          header_up X-Real-IP {remote_host}
          header_up X-Forwarded-For {remote_host}
        }
      }

      # Default route for livekit
      handle {
        reverse_proxy http://localhost:7880 {
          header_up Host {host}
          header_up X-Forwarded-Server {host}
          header_up X-Real-IP {remote_host}
          header_up X-Forwarded-For {remote_host}
        }
      }
    '';

    virtualHosts."https://matrix.${_domain_base}".extraConfig = ''
      # Forward login/logout/refresh to the auth service (MAS)
      @mas path_regexp ^/_matrix/client/(.*)/(login|logout|refresh)
      # Forward everything else Matrix-related to Synapse
      @synapse path_regexp ^(/_matrix|/_synapse/client|/_synapse/mas)

      route {
          # MAS routes (must be before @synapse since @synapse also matches /_matrix)
          reverse_proxy @mas localhost:8089

          # Synapse routes
          reverse_proxy @synapse localhost:8008 {
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
              header_up Host {host}
          }

          # Cinny web client for everything else
          root * ${cinny}
          try_files {path} /index.html
          file_server
      }

      request_body {
          max_size 50MB
      }
    '';

    virtualHosts."https://mas.${_domain_base}".extraConfig = ''
      reverse_proxy localhost:8089
    '';

    virtualHosts."${_domain_base}:8448".extraConfig = ''
      reverse_proxy /_matrix/* localhost:8008
      reverse_proxy /_synapse/client/* localhost:8008
    '';

    virtualHosts."https://git.${_domain_base}".extraConfig = ''
      reverse_proxy :3004
    '';

    virtualHosts."https://vaultwarden.${_domain_base}".extraConfig = ''
      encode zstd gzip

      reverse_proxy [::1]:8222 {
          header_up X-Real-IP {remote_host}
      }
    '';

    virtualHosts."https://immich.${_domain_base}".extraConfig = ''
      reverse_proxy :2283
    '';
  };
}
