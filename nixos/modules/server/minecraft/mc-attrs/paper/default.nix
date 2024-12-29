{
  paper = rec {
    paper-global' = import ./paper-global;
    paper-global = paper-global'.paper-global;
  };
}
