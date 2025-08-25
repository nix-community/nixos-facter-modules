{ config, lib, ... }:
{
  imports = [
    ./initrd.nix
    ./intel.nix
  ];

  options.facter.detected.dhcp.enable = lib.mkEnableOption "Facter dhcp module" // {
    default = builtins.length config.facter.report.hardware.network_interface or [ ] > 0;
    defaultText = "hardware dependent";
  };
  config = lib.mkIf config.facter.detected.dhcp.enable {
    networking.useDHCP = lib.mkDefault true;
    # Disable networkd when both NetworkManager and wait-online are enabled
    networking.useNetworkd = lib.mkDefault (
      !(config.networking.networkmanager.enable && config.systemd.network.wait-online.enable)
    );
  };
}
