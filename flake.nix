{
  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nixos-generators,
      nix-on-droid,
      systems,
      ...
    }:
    let
      inherit (self) outputs;
      lib' = nixpkgs.lib;
      lib = lib'.extend (
        final: prev:
        import ./lib {
          lib = final;
          config = outputs.config;
        }
        // home-manager.lib
      );
      forEachSystem = f: lib.genAttrs (import systems) (system: f pkgsFor.${system});
      pkgsFor = lib.genAttrs (import systems) (
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
        navi = lib.nixosSystem {
          modules = [ ./nixos/navi ];
          specialArgs = { inherit inputs outputs; };
        };
        # iso = lib.nixosSystem {
        #   specialArgs = { inherit inputs outputs; };
        #   modules = [ ./nixos/iso ];
        # };
        # fp30x = lib.nixosSystem {
        #   specialArgs = { inherit inputs outputs; };
        #   modules = [ ./nixos/fp30x ];
        # };
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
        "bloodwolfe@fp30x" = lib.homeManagerConfiguration {
          modules = [ ./home-manager/bloodwolfe/fp30x ];
          pkgs = pkgsFor.aarch64-linux;
          extraSpecialArgs = { inherit inputs outputs lib; };
        };
      };

      nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import nixpkgs { system = "aarch64-linux"; };
        modules = [ ./droid ];
      };
    };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hardware.url = "github:nixos/nixos-hardware";
    systems.url = "github:nix-systems/default-linux";
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
      url = "github:bloodwolfepc/january-nvim";
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
    subtui = {
      url = "github:MattiaPun/SubTUI";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  description = "bloodflake";
}
