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

    nixpkgs-patch-fix-cinny-cross = {
      url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/496178.patch";
      flake = false;
    };

    nixpkgs-patch-fix-python-orjson-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/327639b64c3eb70cecc94e6b9e69a39a0903caa8.patch";
      flake = false;
    };

    nixpkgs-patch-fix-python-pip-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/61f8a36ad0895dcb28404ca61b0860fe45dfc1b8.patch";
      flake = false;
    };

    nixpkgs-patch-fix-python-simsimd-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/1c796cdba382e0ca403f81b11200aeca9208ad43.patch";
      flake = false;
    };

    nixpkgs-patch-fix-python-onnx-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/b36f8aca240898bd380b9a45e1b0d9310e3b676b.patch";
      flake = false;
    };

    nixpkgs-patch-fix-python-stringzilla-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/b5e6ecedc713845a252eb538823117aa8bd24b99.patch";
      flake = false;
    };

    nixpkgs-patch-fix-python-onnx-runtime-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/442f8246a789bb4a27a3be703e992aed5e210c8a.patch";
      flake = false;
    };

    nixpkgs-patch-fix-python-ml-dtypes-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/e513df4f09bae3baaf1f02c0704687bc77d65322.patch";
      flake = false;
    };

    nixpkgs-patch-fix-pgrx-extension-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/e3a4b0f1917108751fa7f92dc98cf5c3c0229707.patch";
      flake = false;
    };

    nixpkgs-patch-fix-vips-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/70e6a1672dbd60f155f5af4d38a836622afe6f03.patch";
      flake = false;
    };

    nixpkgs-patch-fix-gnutls-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/0671850bf537baf17376d30c3605016bde9b385d.patch";
      flake = false;
    };

    nixpkgs-patch-fix-immich-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/03820b7fbe5fbec9387860d090170a264e1c5dc2.patch";
      flake = false;
    };

    nixpkgs-patch-fix-opencv-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/2b58bc2e3e9125add7807b0e51251a123ea1787d.patch";
      flake = false;
    };

    nixpkgs-patch-fix-python-insightface-cross = {
      url = "https://github.com/FlashOnFire/nixpkgs/commit/8dae88c1c0830f3f9604a91a21ba60d83b3497d8.patch";
      flake = false;
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
              { lib, ... }:
              {
                nixpkgs.buildPlatform = "x86_64-linux";
                nixpkgs.hostPlatform = "aarch64-linux";
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
