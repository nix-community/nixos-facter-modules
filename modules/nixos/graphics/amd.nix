{ lib, config, ... }:
let
  facterLib = import ../../../lib/lib.nix lib;
  cfg = config.facter.detected.graphics.amd;
in
{
  options.facter.detected.graphics = {
    amd.enable = lib.mkEnableOption "Enable the AMD Graphics module" // {
      default = builtins.elem "amdgpu" (
        facterLib.collectDrivers (config.facter.report.hardware.graphics_card or [ ])
      );
      defaultText = "hardware dependent";
    };
  };
  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [ "modesetting" ];
  };
}
