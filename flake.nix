{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/develop"; # will use main when nixpkgs module rename patch is finally merged
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

    nixpkgs-patch-fix-kitty-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/21ac28efd25e238b5599fad64077e79b7fb2d08d.patch";
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
            _smtp_address = "smtp.mail.ovh.net";
          };

          modules = [
            ./configuration.nix
            agenix.nixosModules.default

            (
              { config, lib, ... }:
              let
                nativeAarch64Pkgs = import inputs.nixpkgs {
                  system = "aarch64-linux";
                  config = config.nixpkgs.config;

                  overlays = [
                    (final: prev: {
                      valkey = prev.valkey.overrideAttrs (oldAttrs: {
                        doCheck = false;
                        doInstallCheck = false;
                      });
                      redis = prev.redis.overrideAttrs (oldAttrs: {
                        doCheck = false;
                      });
                      postgresql_18 = prev.postgresql_18.overrideAttrs (old: {
                        outputs = if builtins.elem "man" old.outputs then old.outputs else old.outputs ++ [ "man" ];
                      });
                      triton-llvm = prev.triton-llvm.overrideAttrs (oldAttrs: {
                        doCheck = false;
                        doInstallCheck = false;
                      });
                    })
                  ];
                };
              in
              {
                nixpkgs.buildPlatform = "x86_64-linux";
                nixpkgs.hostPlatform = "aarch64-linux";
                nixpkgs.overlays = [
                  (final: prev: {
                    # Force immich and iimmich-machine-learning to compile natively (avoids segfault on thumbnail gen)
                    immich = nativeAarch64Pkgs.immich;
                    immich-machine-learning = nativeAarch64Pkgs.immich-machine-learning;

                    postgresql_18 = nativeAarch64Pkgs.postgresql_18;
                    postgresql18Packages = nativeAarch64Pkgs.postgresql18Packages;
                    postgresql = nativeAarch64Pkgs.postgresql;
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
