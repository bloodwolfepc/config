{ lib, pkgs, config, ... }: let
  cfg = config.configured.angel.gpu-detatched;
  platform = "amd";
  user = "bloodwolfe";
  vfioIds = [ "1002:73ef" "1002:ab28" ];
in {
  config = lib.mkIf cfg.enable {
    hardware.amdgpu = {
      initrd.enable = lib.mkForce false;
    };
    boot = {
      blacklistedKernelModules = [ "amdgpu" ];
      #echo "vfio-pci" > /sys/devices/pci0000:00/0000:00:01.1/0000:01:00.0/0000:02:00.0/0000:03:00.0/driver_override
      #modprobe -i vfio-pci
      #powerprofilesctl set performance
      #postBootCommands = ''
      #'';
      kernelModules = [ 
        "kvm-${platform}" 
        "vfio_virqfd"
        "vfio_pci"
        "vfio_iommu_type1"
        "vfio"
        #"vendor-reset"
      ];
      kernelParams = [
        "rd.driver.pre=vfio-pci"
        "nogpumanager"
        "vfio-pci.ids=${builtins.concatStringsSep "," vfioIds}"

        "${platform}_iommu=on"
        "${platform}_iommu=pt"
        "kvm.ignore_msrs=1"

        "video=vesafb:off,efifb:off"


        #"iommu=pt"
        #"${platform}=on"
        #"${platform}=pt"
      ];
      extraModprobeConfig = "
        options vfio-pci ids=${builtins.concatStringsSep "," vfioIds}
      ";
    };
    systemd.tmpfiles.rules = [
        "f /dev/shm/looking-glass 0660 ${user} qemu-libvirtd -"
    ];
    systemd.services.supergfxd.path = [ pkgs.pciutils ];
    services.supergfxd = {
      enable = true;
      settings = lib.mkForce {
        mode = "Vfio";
        vfio_enable = true;
        vfio_save = true;
        always_reboot = false;
        no_logind = false;
        logout_timeout_s = 180;
        hotplug_type = "Asus";
      };
    };
  };  
}
