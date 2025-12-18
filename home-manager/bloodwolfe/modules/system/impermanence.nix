{
  inputs,
  ...
}:
{
  imports = [
    inputs.impermanence.nixosModules.home-manager.impermanence
  ];
  home.persistence = {
    "/persist/home/bloodwolfe".allowOther = true;
  };
}
