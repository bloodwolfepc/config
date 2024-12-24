{ pkgs, ... }: rec {
  fabric-proxy-lite' = import ./fabric-proxy-lite { inherit pkgs; };
  fabric-proxy-lite = fabric-proxy-lite'.fabric-proxy-lite;
}
