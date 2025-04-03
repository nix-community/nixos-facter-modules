{ lib, config, ... }:
let
  facterLib = import ../../../lib/lib.nix lib;

  inherit (config.facter) report;
in
{
  options.facter.detected.boot.initrd.networking.kernelModules = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = facterLib.stringSet (
      facterLib.collectDrivers (report.hardware.network_controller or [ ])
    );
    defaultText = "hardware dependent";
    description = ''
      List of kernel modules to include in the initrd to support networking.
    '';
  };

  config = lib.mkIf config.boot.initrd.network.enable {
    boot.initrd.kernelModules = config.facter.detected.boot.initrd.networking.kernelModules;
  };
}
