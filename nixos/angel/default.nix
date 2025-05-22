{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.asus-zephyrus-ga402
    ./hardware-configuration.nix
    ./monitors.nix
    ./passthough
    ../setup
  ];

  config =
    let
      inherit (config.sysglobals.list)
        require-nixos
        require-pc
        srv-progs
        used-progs
        gaming-progs
        ;
      enable = {
        list =
          [
            "bloodwolfe"
            "zen-kernel"
            "audio"
            "systemd-boot"
          ]
          ++ require-nixos
          ++ require-pc
          ++ srv-progs
          ++ used-progs
          ++ gaming-progs;
        value = {
          enable = true;
          persist.enable = true;
        };
      };
      configured = lib.listToAttrs (
        map (name: {
          inherit name;
          inherit (enable) value;
        }) enable.list
      );
    in
    {
      inherit configured;
      networking.hostName = "angel";
      services.resolved.enable = true;

      specialisation = {
        nmvfio.configuration = {
          configured = {
            angel = {
              gpu-detatched.enable = true;
              vfio-passthough.enable = true;
            };
            networkmanager.enable = true;
          };
        };
        vfio-passthough.configuration = {
          configured = {
            angel = {
              gpu-detatched.enable = true;
              vfio-passthough.enable = true;
            };
          };
        };
        networkmanager.configuration = {
          configured.networkmanager.enable = true;
        };
      };
      services = {
        asusd = {
          enable = true;
          enableUserService = true;
        };
        switcherooControl.enable = true;
        power-profiles-daemon.enable = true;
        auto-cpufreq.enable = false;

        supergfxd = {
          enable = true;
          settings = lib.mkDefault {
            #mode = "Hybrid";
            mode = "AsusMuxDgpu";
            vfio_enable = true;
            vfio_save = true;
            always_reboot = false;
            no_logind = false;
            logout_timeout_s = 180;
            hotplug_type = "None";
          };
        };
      };
      programs.rog-control-center.enable = true;
      powerManagement.powertop.enable = true;
      environment.systemPackages = with pkgs; [
        asusctl
        gpu-screen-recorder
        gpu-screen-recorder-gtk
      ];
      programs.gpu-screen-recorder.enable = true;
    };
}
