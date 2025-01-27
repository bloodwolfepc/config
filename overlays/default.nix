{ inputs, outputs }: let
  addPatches = pkg: patches:
  pkg.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ patches;
  });
in {

  additions = final: _prev: import ../packages { pkgs = final; };
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  modifications = final: prev: {
    #neovim = prev.neovim // {
    #  neovim = inputs.nixvim.packages.x86_64-linux.default;
    #};
    #python312Packages = prev.python312Packages.overrideScope (gfinal: gprev: {
    #  pyliblo = gprev.pyliblo.overrideAttrs (oldAttrs: {
    #    patches = oldAttrs.patches ++ [
    #      # Fix compile error due to  incompatible pointer type 'lo_blob_dataptr'
    #      #(lib.fetchurl {
    #      #  url = "https://github.com/s0600204/pyliblo/commit/ebbb255d6a73384ec2560047eab236660d4589db.patch";
    #      #  hash = "sha256-KxvEwdDEeWkAdjJS61K0qRys08Unp9d1BbZK52YeWfY=";
    #      #})
    #      ./pyliblo.patch
    #    ];
    #  });
    #});
  };
}
