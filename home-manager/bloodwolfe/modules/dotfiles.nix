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

    sourceAt = lib.mkOption {
      type = lib.types.raw;
      readOnly = true;
      internal = true;
      description = "Select an absolute live path or store-backed configuration source.";
    };

    source = lib.mkOption {
      type = lib.types.raw;
      readOnly = true;
      internal = true;
      description = "Select a live or store-backed configuration source.";
    };
  };

  config.dotfiles = {
    sourceAt =
      live: immutable: if cfg.mutable then config.lib.file.mkOutOfStoreSymlink live else immutable;
    source = relative: cfg.sourceAt "${cfg.path}/${relative}";
  };
}
