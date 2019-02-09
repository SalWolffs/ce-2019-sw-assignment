{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  crossSystem = {
    config = "arm-none-eabihf";
    libc = "newlib";
    platform.gcc = {
      cpu = "cortex-m4";
    };
  };

  cpkgs = import pkgs.path { inherit crossSystem; };

  inherit (cpkgs) stdenv;

  libopencm3 = stdenv.mkDerivation {
    name = "libopencm3";
    src = fetchFromGitHub {
      owner = "libopencm3";
      repo = "libopencm3";
      rev = "8064f6d0cbaca9719c25ee74af115f90deb2b3a0";
      sha256 = "17m91skxbh1v59nl94wzwg7q29hagdg5vi891cjpa7zsv36vhc5j";
    };

    PREFIX = stdenv.hostPlatform.config;
    TARGETS = "stm32/f4";

    enableParellelBuilding = true;
    nativeBuildInputs = [ python ];
    preBuild = ''
      patchShebangs scripts
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r lib include $out
      runHook postInstall
    '';
  };

in stdenv.mkDerivation {
  name = "crypto-engineering";
  PREFIX = stdenv.hostPlatform.config;
  OPENCM3_DIR = toString libopencm3;
  nativeBuildInputs = [ screen stlink ];
}
