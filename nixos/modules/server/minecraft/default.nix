{ pkgs, inputs, ... }: {
  imports = [
    inputs.nix-minecraft.nixosModules.minecraft-servers
    ./velocity-mc
    ./hub-mc
    ./vanilla-mc
    ./xyz-mc
    ./bonefish-mc
    ./yuis-mc
    
  ];
  config = {
    nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];
    srv = {
      velocity-mc = {
        enable = true;
        #forward-ports.enable = true;
      };
      hub-mc.enable = true;
      vanilla-mc.enable = true;
      xyz-mc.enable = true;
      bonefish-mc.enable = true;
      yuis-mc.enable = true;
    };
  };
}
