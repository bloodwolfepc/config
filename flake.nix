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
      customNixosModules = import ./modules/nixos;
      customHomeManagerModules = import ./modules/home-manager;
      overlays = import ./overlays { inherit inputs outputs; };
      customPackages = forEachSystem (pkgs: import ./packages { inherit pkgs; });
      devShells = forEachSystem (pkgs: import ./shell.nix { inherit pkgs; });

      #maybe use as a flake - package instead
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
        navi = lib.nixosSystem {
          modules = [ ./nixos/navi ];
          specialArgs = { inherit inputs outputs; };
        };
        iso = lib.nixosSystem {
          modules = [
            self.nixosModules.myFormats
            ./nixos/iso
          ];
          specialArgs = { inherit inputs outputs; };
        };
      };
      homeConfigurations = {
        "bloodwolfe@angel" = lib.homeManagerConfiguration {
          modules = [ ./home-manager/bloodwolfe/angel ];
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs lib; };
        };
        "bloodwolfe@navi" = lib.homeManagerConfiguration {
          modules = [ ./home-manager/bloodwolfe/navi ];
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs lib; };
        };
        "bloodwolfe@iso" = lib.homeManagerConfiguration {
          modules = [ ./home-manager/bloodwolfe/iso ];
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
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixarr = {
      url = "github:rasmus-kirk/nixarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:bloodwolfepc/nixvim";
    };
    neovim = {
      url = "github:bloodwolfepc/neovim";
    };
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
    };
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
    };
    stylix = {
      url = "github:danth/stylix";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
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
    hy3 = {
      url = "github:outfoxxed/hy3";
      inputs.hyprland.follows = "hyprland";
    };
    split-monitor-workspaces = {
      url = "github:Duckonaut/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };
    hyprsplit = {
      url = "github:shezdy/hyprsplit";
      inputs.hyprland.follows = "hyprland";
    };

  };
  description = "bloodflake";
}
