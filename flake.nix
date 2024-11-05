{
  description = "NixOS Facter Modules";

  outputs =
    publicInputs:
    let
      loadPrivateFlake =
        path:
        let
          flakeHash = builtins.readFile "${toString path}.narHash";
          flakePath = "path:${toString path}?narHash=${flakeHash}";
        in
        builtins.getFlake (builtins.unsafeDiscardStringContext flakePath);

      privateFlake = loadPrivateFlake ./dev/private;

      privateInputs = privateFlake.inputs;

      systems = [
        "aarch64-linux"
        "riscv64-linux"
        "x86_64-linux"
      ];
      eachSystem =
        f:
        builtins.listToAttrs (
          builtins.map (system: {
            name = system;
            value = f {
              pkgs = import privateInputs.nixpkgs { inherit system; };
              inherit system;
            };
          }) systems
        );
    in
    {
      lib = import ./lib { inherit (privateInputs.nixpkgs) lib; };

      nixosConfigurations = {
        basic =
          (import ./hosts/basic {
            inputs = privateInputs;
            flake = publicInputs.self;
          }).value;
      };
      nixosModules.facter = ./modules/nixos/facter.nix;
    }
    //
      # DevOutputs
      {
        devShells = eachSystem (
          { pkgs, ... }:
          {
            default = pkgs.callPackage ./devshell.nix { inputs = publicInputs // privateInputs; };
            docs = pkgs.callPackage ./docs.nix { inputs = publicInputs // privateInputs; };
          }
        );
        formatter = eachSystem (
          { pkgs, ... }:
          (pkgs.callPackage ./formatter.nix { inputs = publicInputs // privateInputs; }).config.build.wrapper
        );

        packages = eachSystem (
          { pkgs, ... }:
          {
            fprint-supported-devices = pkgs.libfprint.overrideAttrs (old: {
              nativeBuildInputs = old.nativeBuildInputs or [ ] ++ [
                pkgs.jq
                pkgs.gawk
              ];
              buildPhase = ''
                ninja libfprint/fprint-list-supported-devices
              '';
              outputs = [ "out" ];
              installPhase = ''
                ./libfprint/fprint-list-supported-devices | \
                  grep -o -E '(\b[0-9a-fA-F]{4}:[0-9a-fA-F]{4}\b)' | \
                  awk '{print toupper($0)}' | \
                  jq -R -s 'split("\n") | map(select(. != "")) | map({key: ., value: true}) | from_entries' > $out
              '';
              # we cannot disable doInstallcheck because than we are missing nativeCheckInputs dependencies
              installCheckPhase = "";
            });
            update-fprint-devices = pkgs.writeScriptBin "update-fprint-devices" ''
              #!${pkgs.stdenv.shell}
              target=$(git rev-parse --show-toplevel)/modules/nixos/fingerprint/devices.json
              cat ${publicInputs.self.packages.${pkgs.system}.fprint-supported-devices} > "$target"
              nix fmt -- "$target"
              git add -- "$target"
            '';
          }
        );

        checks = eachSystem (
          { pkgs, ... }:
          {
            formatting =
              (pkgs.callPackage ./formatter.nix { inputs = publicInputs // privateInputs; }).config.build.check
                publicInputs.self;
            minimal-machine =
              (pkgs.nixos [
                publicInputs.self.nixosModules.facter
                (
                  { lib, config, ... }:
                  {
                    boot.loader.grub.devices = lib.mkForce [ "/dev/sda" ];
                    fileSystems."/".device = lib.mkDefault "/dev/sda";
                    users.users.root.initialPassword = "fnord23";
                    system.stateVersion = config.system.nixos.version;
                    nixpkgs.pkgs = pkgs;
                  }
                )
              ]).config.system.build.toplevel;
            lib-tests = pkgs.runCommandLocal "lib-tests" { nativeBuildInputs = [ pkgs.nix-unit ]; } ''
              export HOME="$(realpath .)"
              export NIX_CONFIG='
              extra-experimental-features = nix-command flakes
              flake-registry = ""
              '

              nix-unit --expr '(import ${publicInputs.self}/lib { lib = import ${privateInputs.nixpkgs}/lib; }).tests'

              touch $out
            '';
          }
        );
      };
}
