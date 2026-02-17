{
  pkgs,
  inputs,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ../modules/users/bloodwolfe
    ../modules/nix.nix
    ../modules/security.nix
    ../modules/kanata.nix
    ../modules/impermanence
    inputs.home-manager.nixosModules.home-manager
  ];
  networking.hostName = "iso";
  nixpkgs.hostPlatform.system = "x86_64-linux";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
