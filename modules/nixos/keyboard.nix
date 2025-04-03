{ lib, config, ... }:
let
  facterLib = import ../../lib/lib.nix lib;

  inherit (config.facter) report;
in
{
  options.facter.detected.boot.keyboard.kernelModules = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = facterLib.stringSet (facterLib.collectDrivers (report.hardware.usb_controller or [ ]));
    defaultText = "hardware dependent";
    example = [ "usbhid" ];
    description = ''
      List of kernel modules to include in the initrd to support the keyboard.
    '';
  };

  config = {
    boot.initrd.availableKernelModules = config.facter.detected.boot.keyboard.kernelModules;
  };
}
