{ lib, config, ... }:
let
  facterLib = import ../../lib/lib.nix lib;

  cfg = config.facter.boot;
  inherit (config.facter) report;
in
{
  options.facter.boot.enable = lib.mkEnableOption "Enable the Facter Boot module" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.availableKernelModules = lib.filter (dm: dm != null) (
      map
        (
          {
            driver_module ? null,
            ...
          }:
          driver_module
        )
        (
          lib.filter (
            with facterLib;
            isOneOf [
              # Needed if we want to use the keyboard when things go wrong in the initrd.
              isUsbController
              # A disk might be attached.
              isFirewireController
              # definitely important
              isMassStorageController
            ]
          ) report.hardware
        )
    );
  };
}
