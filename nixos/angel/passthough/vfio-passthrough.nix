{ config, pkgs, lib,... }: let 
  cfg = config.bwcfg.angel.vfio-passthough;
  user = "bloodwolfe";
  dir.win11 = "/home/bloodwolfe/qemu/windows-passthough/win11.qcow2";
in {
  config = lib.mkIf cfg.enable {
    virtualisation = {
      libvirtd = {
        enable = true;
        #extraConfig = ''
          #user="${user}"
        #'';
        onBoot = "ignore";
        onShutdown = "shutdown";
        qemu = {
          package = pkgs.qemu_kvm;
          #ovmf = "enabled";
          #verbatimConfig = ''
          #namespaces = []
            #user = "+${builtins.toString config.users.users.${user}.uid}"
          #'';
        };
      };
    };
    #XHCI = eXtensible Host Controller Interface (also OHCI for open, EHCI for enhanced)
    environment.systemPackages = with pkgs; [
      looking-glass-client
      (writeShellScriptBin "vfio-boot-windows" ''
        sudo qemu-system-x86_64 \
        -drive file=${dir.win11},format=qcow2 \
        -cpu Skylake-Client-v3 \
        -enable-kvm \
        -m 4096 \
        -smp 2 \
        -device intel-hda \
        -device hda-duplex \
        -usb \
        -nic user,ipv6=off,model=rtl8139,mac=84:1b:77:c9:03:a6 \
        -device vfio-pci,host=03:00.0,multifunction=on,x-vga=on,id=vfio0 \
        -device vfio-pci,host=03:00.1,id=vfio1 \
        -vga none \
        -display none \
        -nographic \
        -parallel none \
        -serial none \
        -enable-kvm \
      '')
      (writeShellScriptBin "check-gpu" ''
        lspci -nnk | grep "1002:73ef" -A 3
        lspci -nnk | grep "1002:ab28" -A 3
        lspci -nnk | grep "1002:1681" -A 3
      '')
      (writeShellScriptBin "gpu-attach" ''
        sudo virsh nodedev-reattach --device pci_0000_03_00_0 && echo "GPU attached" &&
        sudo rmmod vfio vfio_iommu_type1 vfio_pci vfio virqfd && echo "VFIO drivers removed" &&
        sudo modprobe amdgpu "amdgpu driver initialized"
      '')
      (writeShellScriptBin "gpu-detached" ''
        sudo rmmod amdgpu && echo "amdgpu driver removed"
        sudo modprobe vfio vfio_iommu_type1 vfio_pci vfio virqfd && echo "VFIO initialized" &&
        sudo virsh nodedev-detach pci_0000_03_00_0 "GPU detached"
      '')
    ];
  };
}
