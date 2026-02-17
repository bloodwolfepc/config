#reverse eng the old 1

{
  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      home-manager,
      nixos-generators,
      ...
    }:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib.extend (
        final: prev:
        import ./lib {
          lib = final;
          config = outputs.config;
        }
        // home-manager.lib
        // flake-utils.lib
      );
    in
    lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      rec {
        inherit lib;
        myNixosModules = import ./modules/nixos;
        myHomeManagerModules = import ./modules/home-manager;
        overlays = import ./overlays { inherit inputs outputs; };
        customPackages = import ./packages { inherit pkgs; };
        devShells = import ./shell.nix { inherit pkgs; };
        nixosConfigurations = {
          angel = lib.nixosSystem {
            modules = [ ./nixos/angel ];
            specialArgs = { inherit inputs outputs; };
          };
          navi = lib.nixosSystem {
            modules = [ ./nixos/navi ];
            specialArgs = { inherit inputs outputs; };
          };
          iso = lib.nixosSystem {
            specialArgs = { inherit inputs outputs; };
            modules = [ ./nixos/iso ];
          };
        };
        homeConfigurations = {
          "bloodwolfe@angel" = lib.homeManagerConfiguration {
            modules = [ ./home-manager/bloodwolfe/angel ];
            inherit pkgs;
            extraSpecialArgs = { inherit inputs outputs lib; };
          };
          "bloodwolfe@navi" = lib.homeManagerConfiguration {
            modules = [ ./home-manager/bloodwolfe/navi ];
            inherit pkgs;
            extraSpecialArgs = { inherit inputs outputs lib; };
          };
          "bloodwolfe@fp30x" = lib.homeManagerConfiguration {
            modules = [ ./home-manager/bloodwolfe/fp30x ];
            inherit pkgs;
            extraSpecialArgs = { inherit inputs outputs lib; };
          };
          "bloodwolfe@iso" = lib.homeManagerConfiguration {
            modules = [ ./home-manager/bloodwolfe/iso ];
            inherit pkgs;
            extraSpecialArgs = { inherit inputs outputs lib; };
          };
        };
        nixosModules.myFormats =
          {
            config,
            ...
          }:
          {
            imports = [
              nixos-generators.nixosModules.all-formats
            ];
            nixpkgs.hostPlatform.system = "x86_64-linux";
            formatConfigs."iso" =
              { config, modulesPath, ... }:
              {
                imports = [ "${toString modulesPath}/installer/cd-dvd/installation-cd-base.nix" ];
                formatAttr = "isoImage";
                fileExtension = ".iso";
              };
          };
      }
    );

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hardware.url = "github:nixos/nixos-hardware";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "";
      inputs.home-manager.follows = "";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "git+ssh://git@gitlab.com/bloodwolfe/secrets.git?shallow=1";
      flake = false;
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hydra = {
      url = "github:nixos/hydra";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim = {
      url = "github:bloodwolfepc/neovim";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wl-crosshair = {
      url = "github:lelgenio/wl-crosshair";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/main";
    };

  };
  description = "bloodflake";
}
