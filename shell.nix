{ pkgs ? import <nixpkgs> {} }:

with pkgs;

stdenv.mkDerivation {
  name = "crypto-engineering";
  nativeBuildInputs = [ gcc-arm-embedded-7 stlink python37 ]
  ++ (with python37Packages; [ pyserial ]);
}
