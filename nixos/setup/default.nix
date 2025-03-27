{ inputs, outputs, pkgs, ... }: {
  imports = [
    ../modules
    ./lists.nix
    inputs.home-manager.nixosModules.home-manager
  ] ++ (builtins.attrValues outputs.customNixosModules);

  home-manager.extraSpecialArgs = { inherit inputs outputs; };

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config.permittedInsecurePackages = [
    "aspnetcore-runtime-6.0.36"
    "aspnetcore-runtime-wrapped-6.0.36"
    "dotnet-sdk-6.0.428"
    "dotnet-sdk-wrapped-6.0.428"
    ];
    config.allowUnfree = true;
  };

  hardware.enableRedistributableFirmware = true;
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout = 120
  '';
  systemd = {
    extraConfig = ''
      DefaultTimeoutStopSec = 10s
    '';
  };

  system.stateVersion = "23.11";

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
	programs.fuse.userAllowOther = true;

}
