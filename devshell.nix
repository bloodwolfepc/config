# Shell for dev
{
  pkgs ?
    # If pkgs is not defined, instanciate nixpkgs from locked commit
    let
      lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
      nixpkgs = fetchTarball {
        url = "https://github.com/nixos/nixpkgs/archive/${lock.rev}.tar.gz";
        sha256 = lock.narHash;
      };
    in
    import nixpkgs { overlays = [ ]; },
  ...
}:
{
  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes";
    nativeBuildInputs = with pkgs; [
      nix
      git

      gcc
      make
      binutils
      flex
      bison
      util-linux
      kmod
      e2fsprogs
      jfsutils
      reiser
      fsprogs
      xfsprogs
      squashfs-tools
      btrfs-progs
      pcmciautils
      quota-tools
      PPP
      nfs-utils
      procps
      oprofile
      udev
      grub
      mcelog
      iptables
      penssl
      libcrypto
      bc

      pahole
      cpio
      cmlto
      python-sphinx
      python-sphix_rtd_theme
      pearl
      tar
      xz

    ];
  };
}
