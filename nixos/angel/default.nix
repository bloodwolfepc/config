{ config, inputs, pkgs, lib, ... }: {
  imports = [       
    inputs.hardware.nixosModules.asus-zephyrus-ga402
    ./hardware-configuration.nix
    ./monitors.nix
    ../modules/users/bloodwolfe
    ../modules/preset/main.nix
    ../modules/hardware/behringer-404-hd
    ../modules/hardware/gpu-passthrough.nix
    ../modules/hardware/rog-zypherus-g14.nix
    ./passthough
    ./powersave
    ./nonspecial.nix
  ];
  networking.hostName = "angel";
  services.resolved.enable = true;

  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs; [
    vaapiVdpau
    libvdpau-va-gl
  ];

  #android
  programs.adb.enable = true;
  environment.systemPackages = [ 
    pkgs.universal-android-debloater 
  ];
  users.users.bloodwolfe.extraGroups = ["adbusers"];      
  #environment.sessionVariables = {
  #  GTK_IM_MODULE = "fcitx";
  #  QT_IM_MODULE = "fcitx";
  #  XMODIFIES = "@im=fcitx";
  #};
  programs.nix-ld.enable = true;
  #boot.binfmt.preferStaticEmulators = true;

  specialisation.vfio-passthough.configuration = {
    bwcfg.angel.gpu-detatched.enable = true;
    bwcfg.angel.vfio-passthough.enable = true;
  };
  #specialisation.powersave.configuration = {
  #  config.hardware.asus-zypherus-ga402.powersave = true;
  #};
  specialisation.networkmanager.configuration = {
    networking.networkmanager.enable = true;
    bwcfg.angel.powersave.enable = true;
  };
}
