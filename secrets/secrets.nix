let
  lithium = [ "age1ecmj8r0d3p336d93z320rrgs2gdsy9pxhatjevyx97806lz9yfyqf5784l" ];

  mkSecret =
    secrets:
    builtins.listToAttrs (
      map (secret: {
        name = "lithium/${secret}.age";
        value = {
          publicKeys = lithium;
          armor = true;
        };
      }) secrets
    );
in
mkSecret [
  "authelia-config"
  "authelia-jwt"
  "authelia-storage"
  "authelia-oauth2"
  "authelia-oauth2-hmac"
  "smtp"
  "synapse-signingKey"
  "synapse-masSharedSecret"
  "forgejo-smtp"
  "forgejo-runner-token"
  "forgejo-oidc-shared-secret"
  "vaultwarden-smtp"
  "immich-oidc-secret"
  "matrix-livekit-key"
  "msmtp-smtp"
  "mas/encryption"
  "mas/key_rsa_4096"
  "mas/key_ec_p384"
  "mas/client_secret"
  "mas/matrix_secret"
  "mas/provider_client_secret"
]
