{ pkgs, inputs, ... }: {
  imports = [
    inputs.nix-minecraft.nixosModules.minecraft-servers
   ./proxy-mc
   ./vanilla-mc
   ./xyz-mc
  ];
  config = {
    nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];
    srv = {
      proxy-mc.enable = true;
      vanilla-mc.enable = true;
      xyz-mc.enable = true;
    };
  };
}
