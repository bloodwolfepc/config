# Add ordinary paths here; they are read from a read-only snapshot, never live.
{ home, lib }:
let
  minecraft =
    lib.concatMap
      (
        root:
        map (part: "${home}/.local/share/PrismLauncher/instances/*/${root}/${part}") [
          "saves"
          "config"
          "scripts"
          "kubejs"
          "screenshots"
          "mods"
          "resourcepacks"
          "shaderpacks"
          "datapacks"
        ]
      )
      [
        ".minecraft"
        "minecraft"
      ];
  steam =
    lib.concatMap
      (
        root:
        lib.concatMap
          (id: [
            "${home}/${root}/userdata/*/${id}/remote"
            "${home}/${root}/steamapps/compatdata/${id}/pfx/drive_c/users/steamuser/Documents/My Games/Terraria"
          ])
          [
            "105600"
            "1281930"
          ]
      )
      [
        ".local/share/Steam"
        ".local/share/steamgames"
      ];
in
{
  state = {
    paths =
      map (path: "${home}/${path}") [
        "projects/art"
        ".config/GIMP"
        ".local/share/krita"
        ".config/kritarc"
        ".config/kritadisplayrc"
        ".config/BeeRef/BeeRef.ini"
        ".config/ardour8"
        ".config/ardour9"
        ".config/falkTX"
        ".config/fcitx5"
        ".config/millennium/quick.css"
        # Read only for the small sanitizer; the raw file is excluded below.
        ".config/millennium/config.json"
        ".local/share/zathura/bookmarks.sqlite"
        ".local/share/zathura/bookmarks.sqlite-wal"
        ".local/share/zathura/bookmarks.sqlite-shm"
        ".local/share/PrismLauncher/instances/*/instance.cfg"
        ".local/share/PrismLauncher/instances/*/mmc-pack.json"
      ]
      ++ minecraft;
    exclude = [
      "**/PrismLauncher/instances/.*"
      "**/.config/millennium/config.json"
    ];
  };
  legcord = {
    paths = [ "${home}/.config/legcord" ];
    exclude = map (name: "**/legcord/${name}") [
      "Cache"
      "Code Cache"
      "GPUCache"
      "Crashpad"
      "DawnGraphiteCache"
      "DawnWebGPUCache"
      "logs"
      "VideoDecodeStats"
      "WebrtcVideoStats"
      "SingletonCookie"
      "SingletonLock"
      "SingletonSocket"
      ".org.chromium.Chromium.*"
    ];
  };
  anki = {
    paths = [
      "${home}/.local/share/Anki2"
      "${home}/.config/Anki"
      "${home}/.config/Anki2"
    ];
    exclude = [ "**/Anki2/logs" ];
  };
  firefox = {
    paths = [
      "${home}/.config/mozilla/firefox"
      "${home}/.mozilla/firefox"
    ];
    exclude =
      lib.concatMap
        (name: [
          "**/firefox/${name}"
          "**/firefox/*/${name}"
        ])
        [
          "cache2"
          "startupCache"
          "shader-cache"
          "thumbnails"
          "minidumps"
          "crashes"
          "Crash Reports"
          "Pending Pings"
          "firefox-mpris"
          ".parentlock"
          "parent.lock"
          "lock"
        ];
  };
  terraria = {
    paths = [ "${home}/.local/share/Terraria" ] ++ steam;
    exclude = [ ];
  };
}
