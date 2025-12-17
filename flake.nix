{
  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nixos-generators,
      ...
    }:
    let
      inherit (self) outputs;
      systems = [
        "x86_64-linux"
      ];
      lib' = nixpkgs.lib;
      lib = lib'.extend (
        final: prev:
        import ./lib {
          lib = final;
          config = outputs.config;
        }
        // home-manager.lib
      );
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
      pkgsFor = lib.genAttrs systems (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
      );
    in
    {
      inherit lib;
      myNixosModules = import ./modules/nixos;
      myHomeManagerModules = import ./modules/home-manager;
      overlays = import ./overlays { inherit inputs outputs; };
      customPackages = forEachSystem (pkgs: import ./packages { inherit pkgs; });
      devShells = forEachSystem (pkgs: import ./shell.nix { inherit pkgs; });

      nixosModules.myFormats =
        {
          config,
          ...
        }:
        {
          imports = [
            nixos-generators.nixosModules.all-formats
          ];
          nixpkgs.hostPlatform = "x86_64-linux";
          formatConfigs."iso" =
            { config, modulesPath, ... }:
            {
              imports = [ "${toString modulesPath}/installer/cd-dvd/installation-cd-base.nix" ];
              formatAttr = "isoImage";
              fileExtension = ".iso";
            };
        };

      nixosConfigurations = {
        angel = lib.nixosSystem {
          modules = [ ./nixos/angel ];
          specialArgs = { inherit inputs outputs; };
        };
      };
      homeConfigurations = {
        "bloodwolfe@angel" = lib.homeManagerConfiguration {
          modules = [ ./home-manager/bloodwolfe/angel ];
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs lib; };
        };
      };
    };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hardware.url = "github:nixos/nixos-hardware";
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
  };
  description = "bloodflake";
}
