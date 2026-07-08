{
  lib,
  config,

  inputs,
  outputs,
  pkgs,
  ...
}@args:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  options = {
    modules = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
    };
    modules_list = {
      main = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };
  };

  config =
    let
      moduleNames = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./.);
      moduleConfig = {
        value = {
          enable = true;
        };
        list = [

          # ../modules/account.nix
          # ../modules/system
          # ../modules/security
          # ../modules/applications
          # ../modules/terminal
          # ../modules/kanata
          "account"
          "aichat"
          "attrs-dev"
          "attrs-termial"
          "direnv"
          "kanata"
          "main"
          "neovim"
          # "nextcloud"
          "security"
          "terminal"
          "virtualisation"
          "yazi"
          "zellij"
          "zsh"
        ];
      };
      # setModules = lib.listToAttrs (
      #   map (name: {
      #     inherit name;
      #     inherit (moduleConfig) value;
      #   }) moduleConfig.list
      # );

      disabledModules = lib.genAttrs (builtins.attrNames moduleNames) (_: {
        enable = false;
      });
      enabledModules = lib.genAttrs moduleConfig.list (_: {
        enable = true;
      });

      setModules = disabledModules // enabledModules;

      #TODO: attrs- modules should have a way to access an extraModules, for each attrs of a list, mkModule
      # extraModules = [
      #   lib.mkModule
      #   {
      #     name = "kdeconnect";
      #     attrs = {
      #       services.kdeconnect = {
      #         enable = true;
      #         indicator = true;
      #       };
      #     };
      #   }
      #];
    in
    lib.mkMerge (
      [
        {
          modules_list.main = moduleNames;
        }
        { modules = setModules; }
      ]
      ++ map (
        name:
        lib.mkModule {
          inherit name config;
          attrs = import ./${name} args;
        }
      ) (builtins.attrNames moduleNames)
    );
}
