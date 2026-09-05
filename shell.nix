let
  pkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/71caefce12ba78d84fe618cf61644dce01cf3a96.tar.gz";
    sha256 = "1v4f4p1v444r56m6n4jdjc6i1wg3gx724l0rnr45j6cvn5hf5zf9";
  }) { };
in
pkgs.mkShell {
  packages = with pkgs; [ openscad xvfb-run imagemagick python3 ];
  LD_LIBRARY_PATH = "${pkgs.mesa}/lib";
  LIBGL_DRIVERS_PATH = "${pkgs.mesa}/lib/dri";
  LIBGL_ALWAYS_SOFTWARE = "1";
  __GLX_VENDOR_LIBRARY_NAME = "mesa";
}
