{
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./rpi-related.nix
    ./configs
    ./apps
  ];

  age.identityPaths = [ "/impure/age/key" ];

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";
    # useXkbConfig = true; # use xkb.options in tty.
  };

  time.timeZone = "Europe/Paris";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
  boot.kernel.sysctl."vm.swappiness" = 10;

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCt8P+j17S6BHXZSWODBf9dOXuuj5bIdAaMyiyPv4YeU3SXlKpjczZIu4Rw15CUigDEGI8becAFfTRWrqF+/eoh//YId0uwrPDsThjNFbIFQdEp9C9FrM1tX8iB1sd37opPi/hu+WhDwS629tcmPvrzJ63VrXk0XEclS1U4f4Hu5k3kR98SYA/qm0cXf1Ioa85znPrQN6qWjQAzVyVRP2G4sK1koGM29a35t852L1zfoRojpJmW89maMekLMQrXjy9ZxThvW5rDpWDQljat6Bwq5DEEPTL+/8hwajRPiuRrNsFrS7xkCjKFkzxSHWkBjokTlpZUf9a0kAo5KTNiRwRUubTmO1x0602dUhPB0ZsbTOo+KHm8yFfSE0FtVefi4tfA3VBdnh9I7ooM3wIIPCYR9Pf7tQMHBaNQsTya+CqVCJeNeteVrPY/VdcckWg0QV+NLMyc2mEFooExD98VOsH6hUR4bQxi7GXJ0FARvWvhcNnSd80k7T/EPpDLJS+EGKE= flashonfire@helium"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAlaMjFhp2adUJa89ylHV+rDLj9xBfhTAF7q+QClqj83 flashonfire@beryllium"
    ];
  };

  environment.systemPackages = with pkgs; [
    btop
    wget
    kitty.terminfo
    fio
    ripgrep
    fd
  ];

  programs.atop.enable = true;
  programs.git.enable = true;
  virtualisation.docker.enable = true;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  system.stateVersion = "25.11";
}
