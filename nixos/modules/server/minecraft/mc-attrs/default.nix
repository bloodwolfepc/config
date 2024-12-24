{ pkgs }: rec {
  ops = import ./ops;
  mods = import ./mods { inherit pkgs; };
  modconfig = import ./modconfig { inherit pkgs; };
  paper = import ./paper;
  server-properties' = import ./server-properties;
  server-properties = server-properties'.server-properties;
}
  
