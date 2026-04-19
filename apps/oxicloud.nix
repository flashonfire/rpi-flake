{
  config,
  _domain_base,
  _utils,
  ...
}:
let
  secrets = _utils.setupSecrets config {
    secrets = [
      "oxicloud/env"
    ];
    extra = {
      owner = "oxicloud";
      group = "oxicloud";
    };
  };
in
{
  imports = [
    secrets.generate
  ];

  services.oxicloud = {
    enable = true;
    dataDir = "/storage/oxicloud";
    createDatabase = true;

    environmentFiles = [
      (secrets.get "oxicloud/env")
    ];

    settings = {
      baseUrl = "https://cloud.${_domain_base}/";
      oidc = {
        enable = true;
        issuerUrl = "https://auth.${_domain_base}";
        clientId = "iwf2Uz-RTcPID5xkWIk449Mg2ZgsDXt4CePs0yeguQO8XsjNgDJoSYOxVP1biBtJe.2JJ450";
        redirectUri = "https://cloud.${_domain_base}/api/auth/oidc/callback";
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
        ];
        frontendUrl = "https://cloud.${_domain_base}";
        adminGroups = [ "oxicloud_admin" ];
        disablePasswordLogin = true;
        providerName = "Authelia";
      };
    };
  };
}
