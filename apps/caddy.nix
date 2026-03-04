{
  pkgs,
  _domain_base,
  ...
}:
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
        header /.well-known/matrix/* Content-Type application/json
        header /.well-known/matrix/* Access-Control-Allow-Origin *
        respond /.well-known/matrix/server `{"m.server": "matrix.lithium.ovh:443"}`
        # respond /.well-known/matrix/client `{"m.homeserver":{"base_url":"https://matrix.lithium.ovh"},"m.identity_server":{"base_url":"https://mas.lithium.ovh"}}`
        respond /.well-known/matrix/client `{"m.homeserver":{"base_url":"https://matrix.lithium.ovh"},"org.matrix.msc2965.authentication":{"issuer":"https://lithium.ovh/","account":"https://mas.lithium.ovh/account"}}`
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

      reverse_proxy :3003 {
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
          root * ${pkgs.cinny}
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
      forward_auth unix//run/authelia/authelia.sock {
        uri /api/authz/forward-auth
        ## The following commented line is for configuring the Authelia URL in the proxy. We strongly suggest
        ## this is configured in the Session Cookies section of the Authelia configuration.
        # uri /api/authz/forward-auth?authelia_url=https://auth.example.com/
        copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
      }

      reverse_proxy :2283 {
        header_up Cookie "authelia_session=[^;]+" "authelia_session=_"
      }
    '';
  };
}
