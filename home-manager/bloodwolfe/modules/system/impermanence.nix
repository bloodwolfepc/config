{
  inputs,
  ...
}:
{
  imports = [
    inputs.impermanence.nixosModules.home-manager.impermanence
  ];
  home.persistence = {
    "/sync/home/bloodwolfe".allowOther = true;
    "/persist/home/bloodwolfe".allowOther = true;
  };
}
