{ lib, config, ... }:
let
  facterLib = import ../../lib/lib.nix lib;

  inherit (config.facter) report;
in
{
  options.facter.detected.boot.disk.kernelModules = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = facterLib.stringSet (
      facterLib.collectDrivers (
        # A disk might be attached.
        (report.hardware.firewire_controller or [ ])
        # definitely important
        ++ (report.hardware.disk or [ ])
        ++ (report.hardware.storage_controller or [ ])
      )
    );
    defaultText = "hardware dependent";
    description = ''
      List of kernel modules that are needed to access the disk.
    '';
  };

  config = {
    boot.initrd.availableKernelModules = config.facter.detected.boot.disk.kernelModules;
  };
}
