# BUG: hyperland has graphical issues

{ lib, pkgs, config, ... }: let
  cfg = config.bwcfg.angel.gpu-detatched;
  platform = "amd";
  vfioIds = [ "1002:73ef" "1002:ab28" ];
in {
  config = lib.mkIf cfg.enable {
    hardware.amdgpu = {
      initrd.enable = lib.mkForce false;
    };
    boot = {
      blacklistedKernelModules = [ "amdgpu" ];
      postBootCommands = ''
        echo "vfio-pci" > /sys/devices/pci0000:00/0000:00:01.1/0000:01:00.0/0000:02:00.0/0000:03:00.0/driver_override   
        modprobe -i vfio-pci
      '';
      kernelModules = [ 
        "vfio"
        "vfio_iommu_type1"
        "vfio_pci"
        "vfio_virqfd"
        "kvm-${platform}" 
      ];
      kernelParams = [
        "${platform}=on"
        "${platform}=pt"
        "iommu=pt"
        "kvm.ignore_msrs=1"
        "nogpumanager"
        "rd.driver.pre=vfio-pci"
        "vfio-pci.ids=${builtins.concatStringsSep "," vfioIds}"
      ];
      extraModprobeConfig = "
        options vfio-pci ids=${builtins.concatStringsSep "," vfioIds}
      ";
    };
    environment.etc = {
      "supergfxd.conf" = {
        mode = "0664";
        source = (pkgs.formats.json { }).generate "supergfxd.conf" {
          mode = lib.mkForce "Vfio";
          vfio_enable = lib.mkForce true;
          vfio_save = false;
          always_reboot = false;
          no_logind = false;
          logout_timeout_s = 180;
          hotplug_type = "None";
        };
      };
    };
  };  
}
