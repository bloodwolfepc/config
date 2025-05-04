{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkConfig {
    name = "kanata";
    services.kanata = {
      enable = true;
      package = pkgs.kanata-with-cmd;
      keyboards."60-percent-default" = {
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
          (defsrc
          esc  f1   f2   f3   f4   f5   f6   f7   f8   f9   f10  f11  f12
          grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
          tab  q    w    e    r    t    y    u    i    o    p    [    ]    \
          caps a    s    d    f    g    h    j    k    l    ;    '    ret
          lsft z    x    c    v    b    n    m    ,    .    /    rsft
          lctl lmet lalt           spc            ralt rmet rctl
          )

          ;;
          (defalias
          a (tap-hold 200 200 tab (layer-toggle navigation))
          b lctl
          #b (tap-hold 200 200 lctl (layer-toggle number))
          chj (chord jkesc j)
          chk (chord jkesc k)
          )

          (deflayer default
          esc  f1   f2   f3   f4   f5   f6   f7   f8   f9   f10  f11  f12
          grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
          tab   q    w    e    r    t    y    u    i    o    p    [    ]    \
          @b   a    s    d    f    g    h    @chj @chk l    ;    '    ret
          lsft z    x    c    v    b    n    m    ,    .    /    rsft
          lctl lmet lalt           spc            ralt rmet rctl
          )

          (deflayer navigation
            _    _    _    _    _    _    _    _    _    _    _    _    _
            _    _    _    _    _    _    _    _    _    _    _    _    _    _
            _    _    _    _    _    _    _    _    _    _    _    _    _    _
            _    _    _    del  bspc _    left down up   rght _    _    _
            _    _    _    _    _    _    _    _    _    _    _    _
            _    _    _              _              _    _    _
          )

          (deflayer number
            _    _    _    _    _    _    _    _    _    _    _    _    _
            _    S-5  S-6  S-7  S-8  _    _    _    _    _    _    _    _    _
            _    S-1  S-2  S-3  S-4  S-5  S-6  S-7  S-8  S-9  S-0  _    _    _
            _    1    2    3    4    5    6    7    8    9    0    1    _
            _    _    _    _    _    _    _    _    _    _    _    _
            _    _    _              _              _    _    _
          )

          (defchords jkesc 75
            (j    ) j
            (   k ) k
            (j  k ) esc
          )

          ;;(deflayer base
          ;;  @chj @chk
          ;;) 
        '';
      };
    };
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
