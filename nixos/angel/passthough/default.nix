#TODO
#modprobe amdgpu on post activation
#system hooks
#usb passthough keybinds
#emulated tpm

{ lib, ... }:
{
  imports = [
    ./gpu-detatched.nix
    ./vfio-passthrough.nix
  ];
  options = {
    configured.angel.gpu-detatched = {
      enable = lib.mkEnableOption "Detatch gpu on boot.";
    };
    configured.angel.vfio-passthough = {
      enable = lib.mkEnableOption "Configure QEMU for vfio Passthough, create VM launch options.";
    };
  };
}
