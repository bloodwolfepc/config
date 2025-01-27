{
  imports = [
    ../require
    ../stylix
    ../virtualization/libvirt.nix
    ../virtualization/podman.nix
    ../networking/printing.nix
    ../networking/wireguard.nix
    ../extra-modules/ephemeral-btrfs.nix
    
    #../server/nginx-proxy
    #../server/waterdreamer
    #../server/waterdreamer-blog
    #../server/nixarr
    #../server/nextcloud
    #../server/calibre
  ];
}
