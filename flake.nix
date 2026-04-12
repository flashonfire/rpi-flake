{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-patcher.url = "github:gepbird/nixpkgs-patcher";

    systems.url = "github:nix-systems/default";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    nixpkgs-patch-fix-python-orjson-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/327639b64c3eb70cecc94e6b9e69a39a0903caa8.patch";
      flake = false;
    };

    nixpkgs-patch-fix-kitty-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/21ac28efd25e238b5599fad64077e79b7fb2d08d.patch";
      flake = false;
    };

    nixpkgs-patch-fix-python-librt-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/5e9b1541b3075895b38d7dad4fe4a7748704e809.patch";
      flake = false;
    };

    nixpkgs-patch-fix-mypy = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/f4bc8453464ac0238fc43967d53ab600396d8674.patch";
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
              { config, ... }:
              let
                nativeAarch64Pkgs = import inputs.nixpkgs {
                  system = "aarch64-linux";
                  config = config.nixpkgs.config;
                };
              in
              {
                nixpkgs.buildPlatform = "x86_64-linux";

                nixpkgs.overlays = [
                  (final: prev: {
                    # Force immich and immich-machine-learning to compile natively (avoids segfault on thumbnail gen)
                    immich = nativeAarch64Pkgs.immich;
                    immich-machine-learning = nativeAarch64Pkgs.immich-machine-learning;

                    # Required when using native immich
                    postgresql_18 = nativeAarch64Pkgs.postgresql_18;
                    postgresql18Packages = nativeAarch64Pkgs.postgresql18Packages;
                    postgresql = nativeAarch64Pkgs.postgresql;

                    # Atop does not cross compile
                    atop = nativeAarch64Pkgs.atop;

                    # Speed up compilation by leveraging cache
                    kitty = nativeAarch64Pkgs.kitty;
                    vaultwarden = nativeAarch64Pkgs.vaultwarden;
                    forgejo = nativeAarch64Pkgs.forgejo;
                    adguardhome = nativeAarch64Pkgs.adguardhome;
                    cinny = nativeAarch64Pkgs.cinny;
                    matrix-synapse = nativeAarch64Pkgs.matrix-synapse;
                    fio = nativeAarch64Pkgs.fio;
                    matrix-authentication-service = nativeAarch64Pkgs.matrix-authentication-service;
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
