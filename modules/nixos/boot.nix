{
  config,
  lib,
  ...
}:
{
  options.facter.detected.uefi.supported = lib.mkEnableOption "Enable the Facter uefi module" // {
    default = config.facter.report.uefi.supported or false;
    defaultText = "hardware dependent";
  };

  config.boot.loader.grub.efiSupport = lib.mkIf config.facter.detected.uefi.supported (
    lib.mkDefault true
  );
}
