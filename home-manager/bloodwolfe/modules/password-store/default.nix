{ lib, config, pkgs, inputs, ... }: let 
  secrets = builtins.toString inputs.secrets;
  attrs = lib.custom.mkHomeApplication {
    name = "password-store";
    packages = with pkgs; [
      gopass
    ];
    programs.password-store = {
      enable = true;
      package = pkgs.pass.withExtensions (exts: [ exts.pass-otp exts. pass-import ]);
      settings = {
        PASSWORD_STORE_DIR = "${config.home.homeDirectory}/src/secrets/password-store";
      };
    };
    services.pass-secret-service = {
      enable = true;
      storePath = "${config.home.homeDirectory}/src/secrets/password-store"; #or ${secrets}/.password-store
    };
    inherit config;
  };
in {
  inherit (attrs) options config;
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];  
}
