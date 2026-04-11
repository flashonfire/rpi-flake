{ ... }:
{
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
}
