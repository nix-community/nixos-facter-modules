{ lib, config, ... }:
let
  devices = builtins.fromJSON (builtins.readFile ./devices.json);
  default = {
    value = 0;
  };

  toZeroPaddedHex =
    n:
    let
      hex = lib.toHexString n;
      len = builtins.stringLength hex;
    in
    if len == 1 then
      "000${hex}"
    else if len == 2 then
      "00${hex}"
    else if len == 3 then
      "0${hex}"
    else
      hex;

  isSupported = lib.any (
    {
      vendor ? default,
      device ? default,
      bus_type ? {
        name = "";
      },
      ...
    }:
    bus_type.name == "USB"
    && devices ? "${toZeroPaddedHex vendor.value}:${toZeroPaddedHex device.value}"
  );
in
{
  options.facter.detected.fingerprint.enable = lib.mkEnableOption "Fingerprint devices" // {
    default =
      isSupported (config.facter.report.hardware.unknown or [ ])
      || isSupported (config.facter.report.hardware.fingerprint or [ ])
      || isSupported (config.facter.report.hardware.usb or [ ]);
    defaultText = "hardware dependent";
  };

  config.services.fprintd.enable = lib.mkIf config.facter.detected.fingerprint.enable (
    lib.mkDefault true
  );
}
