{ pkgs, ... }: {
  mods = pkgs.linkFarmFromDrvs "mods" (builtins.attrValues {
    fabric-proxy-lite = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/8dI2tmqs/versions/AQhF7kvw/FabricProxy-Lite-2.9.0.jar";
      hash = "sha256-wIQA86Uh6gIQgmr8uAJpfWY2QUIBlMrkFu0PhvQPoac";
    };
    worldedit = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/1u6JkXh5/versions/vBzkrSYP/worldedit-mod-7.3.6.jar";
      hash = "sha256-rhXBnUgZouFryjZSfd1TQNB5HXGglz8sB0lHdyMkG4Y";
    };
    carpet = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/TQTTVgYE/versions/f2mvlGrg/fabric-carpet-1.21-1.4.147%2Bv240613.jar";
      hash = "sha256-B5/IpOBz6ySwEP/MWI5Z+TuYQUPhfY7xn7sLav8PGdk";
    };
  });
}
