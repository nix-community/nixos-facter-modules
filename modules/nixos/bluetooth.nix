{ lib, config, ... }:
{
  options.facter.detected.bluetooth.enable =
    lib.mkEnableOption "Enable the Facter bluetooth module"
    // {
      default = builtins.length (config.facter.report.hardware.bluetooth or [ ]) > 0;
      defaultText = "hardware dependent";
    };

  config.hardware.bluetooth.enable = lib.mkIf config.facter.detected.bluetooth.enable (
    lib.mkDefault true
  );
}
