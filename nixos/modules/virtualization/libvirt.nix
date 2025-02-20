{ pkgs, ... }: {
  virtualisation = {
    #tpm.enable = true;
    spiceUSBRedirection.enable = true;
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true; #tpm emulator
        ovmf.enable = true; #UEFI 
      };
    };
  };
  programs.virt-manager = {
    enable = true;
  };
  environment.systemPackages = with pkgs; [ qemu ];
  services.rkvm = { #used for keybaord and mouse sharing on multiple linux machines
    enable = false;
  };
	environment.persistence."/persist/system" = {
		directories = [
      "/var/lib/libvirt"
    ];
  };
}
