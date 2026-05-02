{ lib, pkgs, ... }:
{
  services.openthread-border-router = {
    enable = true;

    backboneInterfaces = [ "end0" ];

    logLevel = "notice";

    radio = {
      device = "/run/otbr/ttyOTBR";
      baudRate = 460800;
      flowControl = false;
    };

    rest = {
      listenAddress = "127.0.0.1";
      listenPort = 8081;
    };

    web = {
      enable = true;
      listenAddress = "127.0.0.1";
      listenPort = 8082;
    };
  };

  users = {
    users = {
      otbr = {
        isSystemUser = true;
        group = "otbr";
        description = "OpenThread Border Router service user";
      };
    };

    groups.otbr = { };
  };

  systemd.services.socat-otbr = {
    description = "socat PTY bridge for thread radio";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      User = "otbr";
      Group = "otbr";
      RuntimeDirectory = "otbr";
      RuntimeDirectoryMode = "0750";
      ExecStart = "${pkgs.socat}/bin/socat pty,link=/run/otbr/ttyOTBR,raw,echo=0,b460800,mode=0660,group=otbr tcp:192.168.1.198:6638";
      Restart = "always";
      RestartSec = "5s";
    };
  };

  systemd.services.otbr-agent = {
    after = [ "socat-otbr.service" ];
    requires = [ "socat-otbr.service" ];
    serviceConfig = {
      SupplementaryGroups = [ "otbr" ];
      ReadWritePaths = [
        "/run/otbr"
      ];
    };
  };
}
