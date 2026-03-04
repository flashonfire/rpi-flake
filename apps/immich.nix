{ ... }:
{
  services.immich = {
    enable = true;
    host = "0.0.0.0";

    settings = null;
    mediaLocation = "/storage/immich";
    accelerationDevices = [ "/dev/dri/renderD128" ];

    environment = {
      TZ = "Europe/Paris";
    };
  };

  users.users.immich.extraGroups = [
    "video"
    "render"
  ];
}
