{
  config,
  lib,
  ...
}:
let
  cfg = config.dotfiles;
in
{
  options.dotfiles = {
    mutable = lib.mkEnableOption "live configuration from the repository checkout";

    path = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/src/config/home-manager/bloodwolfe/modules";
      description = "Absolute path to the live Home Manager module checkout.";
    };

    source = lib.mkOption {
      type = lib.types.raw;
      readOnly = true;
      internal = true;
      description = "Select a live or store-backed configuration source.";
    };
  };

  config.dotfiles.source =
    relative: immutable:
    if cfg.mutable then config.lib.file.mkOutOfStoreSymlink "${cfg.path}/${relative}" else immutable;
}
