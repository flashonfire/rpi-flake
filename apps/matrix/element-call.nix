{
  config,
  _domain_base,
  _utils,
  ...
}:
let
  secrets = _utils.setupSecrets config {
    secrets = [
      "matrix-livekit-key"
    ];
  };
in
{
  imports = [
    secrets.generate
  ];

  services = {
    livekit = {
      enable = true;
      keyFile = secrets.get "matrix-livekit-key";

      settings = {
        room.auto_create = false;
        rtc = {
          port_range_start = 50000;
          port_range_end = 51000;
        };

        logging = {
          level = "info";
          sample = false;
        };
      };
    };

    lk-jwt-service = {
      enable = true;
      port = 8080;
      keyFile = secrets.get "matrix-livekit-key";
      livekitUrl = "wss://matrix-rtc.lithium.ovh";
    };
  };

  systemd.services.lk-jwt-service.environment.LIVEKIT_FULL_ACCESS_HOMESERVERS = _domain_base;
}
