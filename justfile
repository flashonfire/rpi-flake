alias b := build
alias d := deploy
alias c := check
alias u := update

hostname := "lithium"
domain := "lithium.ovh"

# Build flake
build *FLAGS:
    nh os build .#{{ hostname }} --target-host nixos@{{domain}} {{FLAGS}}

# Deploy to target (switch)
deploy *FLAGS:
    nh os switch .#{{ hostname }} --target-host nixos@{{domain}} {{FLAGS}}

# Deploy to target (next boot)
boot *FLAGS:
    nh os boot .#{{ hostname }} --target-host nixos@{{domain}} {{FLAGS}}

# Nix flake check
check:
    nix flake check

# Nix flake update
update:
    nix flake update --commit-lock-file

# SSH into server
ssh:
    ssh nixos@{{domain}}
