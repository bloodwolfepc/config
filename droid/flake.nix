{
  description = "Tinywolfe Android development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-on-droid,
    }:
    {
      nixOnDroidConfigurations.phone = nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-linux";
          overlays = [ nix-on-droid.overlays.default ];
        };
        home-manager-path = home-manager.outPath;
        modules = [ ./default.nix ];
      };
      nixOnDroidConfigurations.default = self.nixOnDroidConfigurations.phone;
    };
}
