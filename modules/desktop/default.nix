# Configuration for the machines that I use interactivly
{ lib, config, ... }: {
  imports = [
    ./audio.nix
    ./flatpak.nix
    ./fonts.nix
    ./gnome.nix
    ./gui-programs.nix
    ./piper.nix
    ./printer.nix
    ./steam.nix
    ./udev-rules.nix
    ./networkmanager.nix
  ];

  options.modules.desktop.enable = lib.mkOption {
    default = false;
    description = ''
      Enable GUI stuff for this machine
    '';
  };

  config = {
    assertions = [{
      assertion = config.modules.desktop.enable -> config.modules.workstation.enable;
      message = "You need to enable the workstation module for the desktop module to work. This is because many desktop things dont work as root, so we need a normal user.";
    }];
  };
}
