{
  lib,
  pkgs,
  config,
  extendModules,
  ...
}:
{

  options = {

    system.build = {
      noFacter = lib.mkOption {
        type = lib.types.unspecified;
        description = "A version of the system closure with facter disabled";
      };
    };

    facter.debug = {
      nvd = lib.mkOption {
        type = lib.types.package;
        description = ''
          A shell application which will produce an nvd diff of the system closure with and without facter enabled.
        '';
      };
      nix-diff = lib.mkOption {
        type = lib.types.package;
        description = ''
          A shell application which will produce a nix-diff of the system closure with and without facter enabled.
        '';
      };
    };

  };

  config.system.build = {
    noFacter = extendModules {
      modules = [
        {
          # we 'disable' facter by overriding the report and setting it to empty with one caveat: hostPlatform
          config.facter.report = lib.mkForce {
            system = config.nixpkgs.hostPlatform;
          };
        }
      ];
    };
  };

  config.facter.debug = {

    nvd = pkgs.writeShellApplication {
      name = "facter-diff";
      runtimeInputs = [ pkgs.nvd ];
      text = ''
        nvd diff \
                ${config.system.build.noFacter.config.system.build.toplevel} \
                ${config.system.build.toplevel}
      '';
    };

    nix-diff = pkgs.writeShellApplication {
      name = "facter-diff";
      runtimeInputs = [ pkgs.nix-diff ];
      text = ''
        nix-diff \
                ${config.system.build.noFacter.config.system.build.toplevel} \
                ${config.system.build.toplevel}
      '';
    };

  };

}
