{
  lib,
  inputs,
  pkgs,
  outputs,
  config,
  ...
}:
{
  nix = {
    settings =
      let
        substituters = [
          "https://hyprland.cachix.org"
          "https://nix-community.cachix.org"
          "https://nix-gaming.cachix.org"
          "https://chaotic-nyx.cachix.org"
          "https://nixos-raspberrypi.cachix.org"
        ];
      in
      {
        trusted-users = [
          "root"
          "@wheel"
        ];
        auto-optimise-store = lib.mkDefault true;
        experimental-features = [
          "flakes"
          "nix-command"
        ];
        warn-dirty = false;
        system-features = [
          "kvm"
          "big-parallel"
          "nixos-test"
        ];
        flake-registry = "";
        inherit substituters;
        trusted-substituters = substituters;
        trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
          "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
          "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
        ];
      };
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ];
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keee-since 4d --keep 3";
    flake = "/home/bloodwolfe/src/config";
  };
  environment.systemPackages = with pkgs; [
    nix-output-monitor
    nvd
  ];
  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config.allowUnfree = true;
  };

  system.stateVersion = "23.11";
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  programs.fuse.userAllowOther = true;
  home-manager.extraSpecialArgs = { inherit inputs outputs; };
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout = 120
  '';
  services.journald.extraConfig = "SystemMaxUse=50M";
}
