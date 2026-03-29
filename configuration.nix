# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  pkgs,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./rpi-related.nix
    ./apps
  ];

  age.identityPaths = [ "/impure/age/key" ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-public-keys = [
        "helium:g5v7jsnVLhgwbW2I9JIJ4bzy2lKlaT7nRjznsyNbrf0="
        "beryllium:Ki/gTyVwj40wjhqpfKI08vPwQ00D3CWCoPuIpzzMu0s="
      ];
    };
  };

  # Use the GRUB 2 boot loader.
  # boot.loader.grub.enable = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  # boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "storage" ];
  boot.zfs.devNodes = "/dev/disk/by-id";
  services.zfs.autoScrub.enable = true;
  networking.hostId = "44cadff6";

  boot.extraModprobeConfig = ''
    options zfs zfs_vdev_sync_read_max_active=1
    options zfs zfs_vdev_sync_write_max_active=1
    options zfs zfs_vdev_sync_read_min_active=1
    options zfs zfs_vdev_sync_write_min_active=1
    options zfs zfs_vdev_async_read_max_active=1
    options zfs zfs_vdev_async_write_max_active=1
    options zfs zfs_vdev_async_read_min_active=1
    options zfs zfs_vdev_async_write_min_active=1
    options zfs zfs_vdev_max_active=8
    options zfs zfs_txg_timeout=5
    options zfs zfs_dirty_data_max=67108864
    options zfs zfs_arc_max=2147483648
  '';

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
  boot.kernel.sysctl."vm.swappiness" = 10;

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

  # This is mostly portions of safe network configuration defaults that
  # nixos-images and srvos provide

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

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";
    # useXkbConfig = true; # use xkb.options in tty.
  };

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCt8P+j17S6BHXZSWODBf9dOXuuj5bIdAaMyiyPv4YeU3SXlKpjczZIu4Rw15CUigDEGI8becAFfTRWrqF+/eoh//YId0uwrPDsThjNFbIFQdEp9C9FrM1tX8iB1sd37opPi/hu+WhDwS629tcmPvrzJ63VrXk0XEclS1U4f4Hu5k3kR98SYA/qm0cXf1Ioa85znPrQN6qWjQAzVyVRP2G4sK1koGM29a35t852L1zfoRojpJmW89maMekLMQrXjy9ZxThvW5rDpWDQljat6Bwq5DEEPTL+/8hwajRPiuRrNsFrS7xkCjKFkzxSHWkBjokTlpZUf9a0kAo5KTNiRwRUubTmO1x0602dUhPB0ZsbTOo+KHm8yFfSE0FtVefi4tfA3VBdnh9I7ooM3wIIPCYR9Pf7tQMHBaNQsTya+CqVCJeNeteVrPY/VdcckWg0QV+NLMyc2mEFooExD98VOsH6hUR4bQxi7GXJ0FARvWvhcNnSd80k7T/EPpDLJS+EGKE= flashonfire@helium"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAlaMjFhp2adUJa89ylHV+rDLj9xBfhTAF7q+QClqj83 flashonfire@beryllium"
    ];
  };

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    btop
    wget
    kitty.terminfo
    fio
    ripgrep
    fd
  ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";

      KexAlgorithms = [
        "mlkem768x25519-sha256" # newest post-quantum (OpenSSH 9.9+)
        "sntrup761x25519-sha512"
        "sntrup761x25519-sha512@openssh.com"
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
      ];

      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
      ];

      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
      ];

      Compression = "no";
    };
  };

  programs.git.enable = true;
  virtualisation.docker.enable = true;

  # Open ports in the firewall.
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

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

}
