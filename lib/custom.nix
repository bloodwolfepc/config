{ lib }: 
  with builtins;
  with lib;
rec {

  mkSyncthingAttrs = devices: dirs: genAttrs dirs (dir: let
    path = dir;
  in {
    dir = {
      inherit devices path;
      ignorePerms = true;
    };
  });

  mkApplicationOptions = {
    name,
    attrSpace ? "bwcfg",
    extraOptions ? {}
  }: {
    options = {
      ${attrSpace}.${name} = {
        enable = mkEnableOption "enable ${attrSpace} ${name}";
        persist = {
          enable  = mkEnableOption "enable persist ${attrSpace} ${name}";
        };
        sync = {
          enable = mkEnableOption "enable sync ${attrSpace} ${name}";
        };
        #TODO add type
      };
    } // extraOptions;
  };
  
  mkHomeApplication = args:
    mkApplication (args // {type = "home"; });

  mkApplication = {
    name ? throw "No name given.",
    command ? "null",
    key ? "null",
    type ? "host",
    attrSpace ? "bwcfg",
    packages ? [ ],
    extraConfig ? { },
    extraHomeConfig ? { },
    extraOptions ? { },
    persistDirs ? [ ],
    persistFiles ? [ ],
    persistRootDir ? "/persist",
    syncDirs ? [ ],
    syncFiles ? [ ],
    syncRootDir ? "/sync",
    syncDefaultDevices ? [ "navi" "angel" ],
    syncExtraDevices ? [ ],

    pcWindowRule ? [ ],
    pcExecOnce ? [ ],
    pcEnv ? [ ],
    pcExtraConfig ? '' '',

    i18n ? { },
    programs ? { },
    services ? { },
    home ? { },
    xdg ? { },
    sops ? { },
    stylix ? { },
    wayland ? { },
    accounts ? { },

    config


  }: let
      cfg = config.${attrSpace}.${name};
      applicationOptions = mkApplicationOptions {
        inherit name attrSpace extraOptions;
      };
      extraConfig' = mkIf cfg.enable (
        if isFunction extraConfig
        then extraConfig cfg
        else extraConfig
      );  
      extraHomeConfig' = mkIf cfg.enable (
        if lib.isFunction extraHomeConfig
        then extraHomeConfig cfg
        else extraHomeConfig
      );
      services' = mkMerge [
        {
          syncthing = mkIf (cfg.sync.enable && syncDirs != [ ]) {
            settings.folders = mkSyncthingAttrs 
            syncDefaultDevices 
            (map (dir: "${config.home.homeDirectory}/${dir}") syncDirs);
          };
        } 
        services
      ];
      wayland' = mkMerge [
        {
          windowManager.hyprland = mkIf (config.wayland.windowManager.hyprland.enable) {
            settings = {
              windowrulev2 = pcWindowRule;
              exec-once = pcExecOnce;
              env = pcEnv;
            };
            extraConfig = mkBefore ''
              submap = EXEC
                bindi = , ${key}, submap , EXEC_${name}
              submap = escape
              submap = EXEC_${name}    
	              bindi = , ${config.kb_RIGHT}, layoutmsg, preselect r
	              bindi = , ${config.kb_DOWN}, layoutmsg, preselect d
	              bindi = , ${config.kb_UP}, layoutmsg, preselect u
	              bindi = , ${config.kb_LEFT}, layoutmsg, preselect l
	              bindi = , ${config.kb_RIGHT}, exec, ${command}
	              bindi = , ${config.kb_DOWN}, exec, ${command}
	              bindi = , ${config.kb_UP}, exec, ${command}
	              bindi = , ${config.kb_LEFT}, exec, ${command}
                source = ${config.globals.passOneshots}
              submap = escape
              submap = DEPLOY
                bindi = , ${key}, workspace, name:${name}
                bindi = , ${key}, exec, ${command}
              submap = escape
              submap = WS
                bindi = , ${key}, workspace, name:${name}
              submap = escape
              ${pcExtraConfig}
            ''; #+ pcExtraConfig;
          };
        }
        wayland
      ];
      home' = mkMerge [
        {
          inherit packages;
          persistence = {
            "${persistRootDir}${config.home.homeDirectory}" = mkIf cfg.persist.enable {
              directories = persistDirs;
              files = persistFiles;
            };
            "${syncRootDir}${config.home.homeDirectory}" = mkIf cfg.sync.enable {
              directories = syncDirs;
              files = syncFiles;
            };
          };
          file = (
            mkMerge (map (syncPath: {
              "${syncPath}".source = mkForce (config.lib.file.mkOutOfStoreSymlink
                "${syncRootDir}${config.home.homeDirectory}/.extra-syncs/DIR-${baseNameOf syncPath}/${syncPath}"
              );
            }) syncFiles)
          );
        }
        home
        extraHomeConfig' 
      ];
  in {
    inherit (applicationOptions) options;
    config = mkMerge [
      (mkIf cfg.enable {
        inherit i18n programs xdg sops stylix accounts;
        home = home';
        wayland = wayland';
        services = services';
      })
      extraConfig'
    ];
  };
}
