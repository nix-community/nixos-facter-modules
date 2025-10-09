{ pkgs, ... }:
pkgs.mkShellNoCC {
  packages = [
    pkgs.nix-unit
  ];
}
