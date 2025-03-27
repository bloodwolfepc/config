{ config, pkgs, lib,... }: let 
  cfg = config.configured.angel.vfio-passthough;
  user = "bloodwolfe";
  dir.win11 = "/home/bloodwolfe/qemu/windows-passthough/win11.qcow2";
in {
  config = lib.mkIf cfg.enable {
    virtualisation = {
      libvirtd = {
        enable = true;
        onBoot = "ignore";
        onShutdown = "shutdown";
        qemu = {
          package = pkgs.qemu_kvm;
        };
      };
    };
    #XHCI = eXtensible Host Controller Interface (also OHCI for open, EHCI for enhanced)
    environment.systemPackages = with pkgs; [
      looking-glass-client
      pciutils
      usbutils
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
      (writeShellScriptBin "gpu-info" ''
        lspci -nnk | grep "1002:73ef" -A 3
        lspci -nnk | grep "1002:ab28" -A 3
        lspci -nnk | grep "1002:1681" -A 3
        ls -l /sys/bus/pci/devices/0000:03:00.0/driver
        ls -l /sys/bus/pci/devices/0000:03:00.1/driver
      '')
      (writeShellScriptBin "gpu-detach" (builtins.readFile ./gpu-detach.sh))
      (writeShellScriptBin "gpu-attach" (builtins.readFile ./gpu-attach.sh))
    ];
  };
}
