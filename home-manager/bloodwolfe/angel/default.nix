{ lib, config, inputs, ... }: {
  imports = [ 
    ../setup
    ../../../nixos/angel/monitors.nix
    ../hardware/rog-zypherus-g14.nix
    ../hardware/wacom-intuos-pro.nix
  ];
  config = let
    inherit (config.globals.list)
      require-nixos
      require-hm
      require-pc
      srv-progs
      used-progs
      gaming-progs
      workstation-progs
    ;
    enable = {
      list = [ ] 
        ++ require-nixos
        ++ require-hm
        ++ require-pc
        ++ srv-progs
        ++ used-progs
        ++ gaming-progs
        ++ workstation-progs
      ;
      value = {
        enable = true;
        sync.enable = true;
        persist.enable = true;
      };
    };
    bwcfg = lib.listToAttrs (map (name: {
      inherit name;
      inherit (enable) value;
    }) enable.list );
  in {
    inherit bwcfg;
    wayland.windowManager.hyprland.extraConfig = ''
      submap = MONITOR
        bindi = ,f, focusmonitor, desc:Microstep MSI G241 0x000005ED
        bindi = ,d, focusmonitor, desc:BOE 0x0A1D
        bindi = ,s, focusmonitor, desc:Sceptre Tech Inc Sceptre F24 0x00000001
      submap = escape
    '';
    sops.secrets = {
      "syncthing-key-angel" = { };
      "syncthing-cert-angel" = { };
    };
    services.syncthing = { 
      key = config.sops.secrets."syncthing-key-angel".path;
      cert = config.sops.secrets."syncthing-cert-angel".path;
    }; 


    qt = {
      enable = true;
      platformTheme.name = "qtct";
      #qt5ct qt6ct

    };
    gtk = {
      enable = true;
    };
  };
}
