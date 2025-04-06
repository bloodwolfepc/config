{
	outputs = inputs@{ self, nixpkgs, home-manager, ... }:
	let 
    inherit (self) outputs;
		systems = [
      "x86_64-linux"
    ];
    lib' = nixpkgs.lib;
    lib = lib'.extend ( final: prev:
      import ./lib {
        lib = final;
        config = outputs.config;
      } // home-manager.lib
    );
    forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
		pkgsFor = lib.genAttrs systems (system: import nixpkgs {
			inherit system;
			config.allowUnfree = true;
		});
	in
	{
    inherit lib; 
    customNixosModules = import ./modules/nixos;
    customHomeManagerModules = import ./modules/home-manager;
    overlays = import ./overlays {inherit inputs outputs; };
    customPackages = forEachSystem (pkgs: import ./packages { inherit pkgs; }); #outputs.customPackages.x86_64-linux.hello
    devShells = forEachSystem (pkgs: import ./shell.nix { inherit pkgs; });
    #formatter = forEachSystem (pkgs: pkgs.nixpkgs-fmt);
		nixosConfigurations = {
      angel = lib.nixosSystem {
        modules = [ ./nixos/angel ];
        specialArgs = { inherit inputs outputs; };
      };
      navi = lib.nixosSystem {
        modules = [ ./nixos/navi ];
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
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hydra = {
      url = "github:nixos/hydra";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #nixos-mailserver = {
    #  url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
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
    #steam-tui = {
    #  url = "github:dmadisetti/steam-tui";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
    };
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
    };
    stylix = {
      url = "github:danth/stylix";
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
      #url = "github:hyprwm/Hyprland?submodules=1&rev=5ee35f914f921e5696030698e74fb5566a804768";
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hy3 = {
      #url = "github:outfoxxed/hy3?ref=hl0.48.0";
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
