{
  pkgs,
  inputs,
  ...
}:
{
  home.packages = [
    inputs.neovim.packages.${pkgs.system}.default
    pkgs.nixfmt-rfc-style
    (pkgs.aspellWithDicts (
      ds: with ds; [
        en
        en-computers
        en-science
      ]
    ))
  ];
  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
