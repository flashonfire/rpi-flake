{ ... }:
{
  networking.hostName = "lithium";

  networking.hosts = {
    "127.0.0.1" = [
      "lithium.ovh"
      "auth.lithium.ovh"
      "mas.lithium.ovh"
      "matrix.lithium.ovh"
    ];
    "::1" = [
      "lithium.ovh"
      "auth.lithium.ovh"
      "mas.lithium.ovh"
      "matrix.lithium.ovh"
    ];
  };

  networking.useNetworkd = true;

  # mdns
  # networking.firewall.allowedUDPPorts = [ 5353 ];
  # systemd.network.networks = {
  #   "99-ethernet-default-dhcp".networkConfig.MulticastDNS = "yes";
  #   "99-wireless-client-dhcp".networkConfig.MulticastDNS = "yes";
  # };

  # This comment was lifted from `srvos`
  # Do not take down the network for too long when upgrading,
  # This also prevents failures of services that are restarted instead of stopped.
  # It will use `systemctl restart` rather than stopping it with `systemctl stop`
  # followed by a delayed `systemctl start`.
  systemd.services = {
    systemd-networkd.stopIfChanged = false;
    # Services that are only restarted might be not able to resolve when resolved is stopped before
    systemd-resolved.stopIfChanged = false;
  };

  services.resolved.settings.Resolve = {
    DNSStubListener = false;
    LLMNR = false;
    MulticastDNS = false;
  };

  # Use iwd instead of wpa_supplicant. It has a user friendly CLI
  networking.wireless.enable = false;
  networking.wireless.iwd = {
    enable = true;
    settings = {
      Network = {
        EnableIPv6 = true;
        RoutePriorityOffset = 300;
      };
      Settings.AutoConnect = true;
    };
  };
  # networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  networking.firewall.allowedTCPPorts = [
    53
    443
    7881
  ];
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedUDPPortRanges = [
    # Matrix Livekit
    {
      from = 50000;
      to = 51000;
    }
  ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
}
