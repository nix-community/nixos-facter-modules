# NixOS Configuration

Taking the `facter.json` file generated in the [previous step](./generate-report.md), we can construct a
[NixOS configuration]:

=== "Flake"

    ```nix title="flake.nix"
    {
      inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
      };

      outputs =
        inputs@{ nixpkgs, ... }:
        let
            inherit (nixpkgs) lib;
        in
        {
          nixosConfigurations.basic = lib.nixosSystem {
            modules = [

              # enable the NixOS Facter module
              inputs.nixos-facter-modules.nixosModules.facter

              # configure the facter report
              { config.facter.reportPath = ./facter.json; }

              # Additional modules and configuration, for example:
              #
              # {
              #   users.users.root.initialPassword = "fnord23";
              #   boot.loader.grub.devices = lib.mkForce [ "/dev/sda" ];
              #   fileSystems."/".device = lib.mkDefault "/dev/sda";
              # }
              # ...
              # Define your bootloader if you are not using grub
              # { boot.loader.systemd-boot.enable = true; }
            ];
          };
        };
    }
    ```

=== "Non-Flake"

    ```nix title="configuration.nix"
    { lib, ... }:
    {
      imports = [
        "${
          (builtins.fetchTarball { url = "https://github.com/numtide/nixos-facter-modules/"; })
        }/modules/nixos/facter.nix"
      ];

      # configure the facter report
      config.facter.reportPath = ./facter.json;

      # Additional modules and configuration, for example:
      #
      # config.users.users.root.initialPassword = "fnord23";
      # config.boot.loader.grub.devices = lib.mkForce [ "/dev/sda" ];
      # config.fileSystems."/".device = lib.mkDefault "/dev/sda";
      #
      # ...
      # Define your bootloader if you are not using grub
      # config.boot.loader.systemd-boot.enable = true;
    }
    ```

The NixOS Facter module will attempt to do the following:

-   Configure `nixpkgs.hostPlatform` based on the [detected architecture].
-   Enable a variety of kernel modules and NixOS options related to VM and bare-metal environments based on the [detected virtualisation].
-   Enable CPU microcode updates based on the [detected CPU(s)].
-   Ensure a variety of kernel modules are made available at boot time based on the [detected (usb|firewire|storage) controllers and disks].
-   Enable a variety of kernel modules based on the [detected Broadcom and Intel WiFi devices].

!!! info "Roadmap"

    We continue to add to and improve [nixos-facter-modules]. Our eventual goal is to replace much if not all of the
    functionality currently provided by [nixos-hardware] and [nixos-generate-config].

## Introspection and debugging

You might be asking yourself:

> This is cool and all that, but how do I know what changes `nixos-facter` will be making to my system closure???

And you would be right to be concerned about just applying it without a way of understanding its impact.

That is why we have added the following options for introspecting how `nixos-facter` is affecting a system closure.

### `nvd`

You can output a [nvd diff] of the system closure with and without `nixos-facter` enabled by running
`nix run .#nixosConfigurations.<hostname>.config.facter.debug.nvd`:

```shell
❯ nix run .#nixosConfigurations.basic.config.facter.debug.nvd
<<< /nix/store/fqbia5p8hfnyzxipfjmzxn8v3b69mjvs-nixos-system-nixos-24.11.20240831.12228ff
>>> /nix/store/ijkh9sq03y72pfrjvncrsrhwh7g6k8q0-nixos-system-nixos-24.11.20240831.12228ff
Added packages:
[A.]  #01  X-Reload-Triggers-systemd-networkd         <none>
[A.]  #02  X-Restart-Triggers-systemd-networkd        <none>
[A.]  #03  X-Restart-Triggers-systemd-resolved        <none>
[A.]  #04  etc-systemd-networkd.conf                  <none>
[A.]  #05  etc-systemd-resolved.conf                  <none>
[A.]  #06  graphics-driver.conf                       <none>
[A.]  #07  graphics-drivers                           <none>
[A.]  #08  hwdata                                     0.385
[A.]  #09  libXfixes                                  6.0.1
[A.]  #10  libXxf86vm                                 1.1.5
[A.]  #11  libdrm                                     2.4.122
[A.]  #12  libpciaccess                               0.18.1
[A.]  #13  libxshmfence                               1.3.2
[A.]  #14  llvm                                       18.1.8-lib
[A.]  #15  lm-sensors                                 3.6.0
[A.]  #16  mesa                                       24.2.1, 24.2.1-drivers
[A.]  #17  unit                                       99-ethernet-default-dhcp.network, 99-wireless-client-dhcp.network
[A.]  #18  unit-systemd-network-wait-online-.service  <none>
[A.]  #19  unit-systemd-networkd-wait-online.service  <none>
[A.]  #20  unit-systemd-networkd.service              <none>
[A.]  #21  unit-systemd-networkd.socket               <none>
[A.]  #22  unit-systemd-resolved.service              <none>
[A.]  #23  vulkan-loader                              1.3.283.0
[A.]  #24  wayland                                    1.23.0
[A.]  #25  xcb-util-keysyms                           0.4.1
Removed packages:
[R.]  #1  X-Restart-Triggers-resolvconf    <none>
[R-]  #2  dhcpcd                           10.0.6
[R.]  #3  dhcpcd.conf                      <none>
[R-]  #4  openresolv                       3.13.2
[R.]  #5  unit-dhcpcd.service              <none>
[R.]  #6  unit-network-setup.service       <none>
[R.]  #7  unit-resolvconf.service          <none>
[R.]  #8  unit-script-network-setup-start  <none>
Closure size: 562 -> 581 (55 paths added, 36 paths removed, delta +19, disk usage +700.6MiB).
```

### `nix-diff`

You can output a [nix-diff] of the system closure with and without `nixos-facter` enabled by running
`nix run .#nixosConfigurations.<hostname>.config.facter.debug.nix-diff`:

```shell
❯ nix run .#nixosConfigurations.basic.config.facter.debug.nix-diff
- /nix/store/fqbia5p8hfnyzxipfjmzxn8v3b69mjvs-nixos-system-nixos-24.11.20240831.12228ff:{out}
+ /nix/store/ijkh9sq03y72pfrjvncrsrhwh7g6k8q0-nixos-system-nixos-24.11.20240831.12228ff:{out}
• The input derivation named `boot.json` differs
  - /nix/store/zcmdy29f5di6rrfkkld3x773q1d7c1bv-boot.json.drv:{out}
  + /nix/store/j0wxsmw6fxgzd59pdcljkpq430jbk8jn-boot.json.drv:{out}
  • The input derivation named `initrd-linux-6.6.48` differs
    - /nix/store/3z3jgifv3rj5wrh4cx23gzc9hlrwrxwj-initrd-linux-6.6.48.drv:{out}
    + /nix/store/ds7pcp97k33p93z460b5vzrii02jjkcf-initrd-linux-6.6.48.drv:{out}
    • The input derivation named `initrd-nixos.conf` differs
      - /nix/store/y458hw08d5hv2bcf295fv9wvbsfvprrq-initrd-nixos.conf.drv:{out}
      + /nix/store/989v278ws16mnvlx6fwsa925vgx9a0ia-initrd-nixos.conf.drv:{out}
      • The environments do not match:
          text=''
          virtio_balloon
          virtio_console
          virtio_rng
          virtio_gpu
          bochs
          dm_mod
      ''
    • The input derivation named `linux-6.6.48-modules-shrunk` differs
      - /nix/store/dk2xshi6hr85wjyia60nizahl2rq31sz-linux-6.6.48-modules-shrunk.drv:{out}
      + /nix/store/xxk67p9wy7hxq33gd1mfz5dqcsm2mhsr-linux-6.6.48-modules-shrunk.drv:{out}
      • The environments do not match:
          rootModules=''
          virtio_net virtio_pci virtio_mmio virtio_blk 9p 9pnet_virtio uhci_hcd ata_piix floppy virtio_blk virtio_pci ext2 ext4 autofs tpm-tis tpm-crb efivarfs ahci sata_nv sata_via sata_sis sata_uli ata_piix pata_marvell nvme sd_mod sr_mod mmc_block uhci_hcd ehci_hcd ehci_pci ohci_hcd ohci_pci xhci_hcd xhci_pci usbhid hid_generic hid_lenovo hid_apple hid_roccat hid_logitech_hidpp hid_logitech_dj hid_microsoft hid_cherry hid_corsair pcips2 atkbd i8042 rtc_cmos virtio_balloon virtio_console virtio_rng virtio_gpu bochs dm_mod
      ''
    • Skipping environment comparison
  • Skipping environment comparison
  ...
  ...
  ...
```

[NixOS configuration]: https://nixos.org/manual/nixos/stable/#sec-configuration-syntax
[detected architecture]: https://github.com/numtide/nixos-facter-modules/blob/main/modules/nixos/system.nix
[detected virtualisation]: https://github.com/numtide/nixos-facter-modules/blob/main/modules/nixos/virtualisation.nix
[detected CPU(s)]: https://github.com/numtide/nixos-facter-modules/blob/main/modules/nixos/firmware.nix
[detected (usb|firewire|storage) controllers and disks]: (https://github.com/numtide/nixos-facter-modules/blob/main/modules/nixos/boot.nix)
[detected Broadcom and Intel WiFi devices]: https://github.com/numtide/nixos-facter-modules/blob/main/modules/nixos/networking
[nixos-facter-modules]: https://github.com/numtide/nixos-facter-modules
[nixos-hardware]: https://github.com/NixOS/nixos-hardware
[nixos-generate-config]: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/tools/nixos-generate-config.pl
[nvd diff]: https://khumba.net/projects/nvd/
[nix-diff]: https://github.com/Gabriella439/nix-diff
