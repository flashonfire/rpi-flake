{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/develop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-patcher.url = "github:gepbird/nixpkgs-patcher";

    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # nixpkgs-patch-fix-raspi-module-renames = {
    #   url = "https://github.com/NixOS/nixpkgs/pull/398456.diff";
    #   flake = false;
    # };

    nixpkgs-patch-fix-mas-cross-compile = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/5370f19009df.patch";
      flake = false;
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        darwin.follows = "";
      };
    };
  };

  outputs =
    {
      flake-parts,
      agenix,
      nixpkgs-patcher,
      self,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake = {
        nixosConfigurations.lithium = nixpkgs-patcher.lib.nixosSystem {
          system = "x86_64-linux";
          nixpkgsPatcher.system = "x86_64-linux";

          specialArgs = inputs // {
            _utils = (import ./uku_utils.nix) { lib = inputs.nixpkgs.lib; };
            _domain_base = "lithium.ovh";
            _smtp_server = "smtp.mail.ovh.net";
          };

          modules = [
            ./configuration.nix
            agenix.nixosModules.default
            (
              { lib, ... }:
              {
                nixpkgs.buildPlatform = "x86_64-linux";
                nixpkgs.hostPlatform = "aarch64-linux";
                nixpkgs.overlays = [
                  (final: prev: {
                    gnutls = prev.gnutls.overrideAttrs (prevAttrs: {
                      postPatch = prevAttrs.postPatch + ''
                        touch doc/stamp_error_codes
                      '';
                    });
                  })
                ];
              }
            )
          ];
        };
      };

      perSystem =
        { pkgs, system, ... }:
        {
          devShells.default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              agenix.packages.${system}.default
              just
            ];
          };

          formatter = pkgs.nixfmt-tree;
        };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };
}
