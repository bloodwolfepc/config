{ config, pkgs, lib,... }: let 
  cfg = config.bwcfg.angel.vfio-passthough;
  user = "bloodwolfe";
  dir.win11 = "/home/bloodwolfe/qemu/win11.qcow2";
in {
  config = lib.mkIf cfg.enable {
    virtualisation = {
      libvirtd = {
        enable = true;
        extraConfig = ''
          user="${user}"
        '';
        onBoot = "ignore";
        onShutdown = "shutdown";
        qemu = {
          package = pkgs.qemu_kvm;
          #ovmf = "enabled";
          verbatimConfig = ''
            namespaces = []
            user = "+${builtins.toString config.users.users.${user}.uid}"
          '';
        };
      };
    };
    users.users.${user}.extraGroups = [
      "qemu-libvirtd" "libvirtd" "disk"
    ];
    environment.systemPackages = [
      #pkgs.looking-glass-client
      (pkgs.writeShellScriptBin "vfio-boot-windows" ''
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
    ];
  };
}
