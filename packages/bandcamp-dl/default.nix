{
  fetchFromGitHub,
  python3,
  python3Packages,
  ...
}:

let
  python3Packages' = python3Packages.override {
    overrides = final: prev: {
      beautifulsoup4 = prev.buildPythonPackage rec {
        pname = "beautifulsoup4";
        version = "4.13.0b2";
        format = "pyproject";
        src = prev.fetchPypi {
          inherit pname version;
          sha256 = "sha256-xoTd7AcaoSCBmImqnolA+Fw/PNqgjiO5+iZRA4eJe9U=";
        };
        buildInputs = [
          final.hatchling
        ];
        propagatedBuildInputs = with python3Packages; [
          typing-extensions
          soupsieve
        ];
      };
    };
  };
in

python3.pkgs.buildPythonApplication rec {
  pname = "bandcamp-dl";
  version = "0.0.16";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "iheanyi";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-PNyVEzwRMXE0AtTTg+JyWw6+FSuxobi3orXuxkG0kxw=";
  };

  buildInputs = [
    python3
  ];

  propagatedBuildInputs = with python3Packages'; [
    setuptools
    docopt
    mutagen
    requests
    unicode-slugify
    mock
    chardet
    demjson3
    beautifulsoup4
  ];
}
