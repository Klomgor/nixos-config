{ config, pkgs, lib, currentSystem, currentSystemName, ... }:

{
  imports = [
    ../modules/specialization/plasma.nix
    ../modules/specialization/i3.nix
    ../modules/specialization/gnome-ibus.nix
  ];

  # Be careful updating this.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';

    # public binary cache that I use for all my derivations. You can keep
    # this, use your own, or toss it. Its typically safe to use a binary cache
    # since the data inside is checksummed.
    settings = {
      substituters = ["https://mitchellh-nixos-config.cachix.org"];
      trusted-public-keys = ["mitchellh-nixos-config.cachix.org-1:bjEbXJyLrL1HZZHBbO4QALnI5faYZppzkU4D2s0G8RQ="];
    };
  };

  nixpkgs.config.permittedInsecurePackages = [
    # Needed for k2pdfopt 2.53.
    "mupdf-1.17.0"
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # VMware, Parallels both only support this being 0 otherwise you see
  # "error switching console mode" on boot.
  boot.loader.systemd-boot.consoleMode = "0";

  # Define your hostname.
  networking.hostName = "dev";

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  # Don't require password for sudo
  security.sudo.wheelNeedsPassword = false;

  # Virtualization settings
  virtualisation.docker.enable = true;
  virtualisation.lxd = {
    enable = true;
  };

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-chinese-addons
        fcitx5-gtk
        fcitx5-hangul
        fcitx5-mozc
      ];
    };
  };

  # Enable tailscale. We manually authenticate when we want with
  # "sudo tailscale up". If you don't use tailscale, you should comment
  # out or delete all of this.
  services.tailscale.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = false;

  # Manage fonts. We pull these from a secret directory since most of these
  # fonts require a purchase.
  fonts = {
    fontDir.enable = true;

    packages = [
      pkgs.fira-code
      pkgs.jetbrains-mono
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    cachix
    gnumake
    killall
    xclip

    # For hypervisors that support auto-resizing, this script forces it.
    # I've noticed not everyone listens to the udev events so this is a hack.
    (writeShellScriptBin "xrandr-auto" ''
      xrandr --output Virtual-1 --auto
    '')
  ] ++ lib.optionals (currentSystemName == "vm-aarch64") [
    # This is needed for the vmware user tools clipboard to work.
    # You can test if you don't need this by deleting this and seeing
    # if the clipboard sill works.
    gtkmm3
  ];

  # Our default non-specialised desktop environment.
  services.xserver = lib.mkIf (config.specialisation != {}) {
    enable = true;
    xkb.layout = "us";
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
  services.openssh.settings.PermitRootLogin = "no";

  # Enable flatpak. I don't use any flatpak apps but I do sometimes
  # test them so I keep this enabled.
  services.flatpak.enable = true;

  # Enable snap. I don't really use snap but I do sometimes test them
  # and release snaps so we keep this enabled.
  services.snap.enable = true;

  # Disable the firewall since we're in a VM and we want to make it
  # easy to visit stuff in here. We only use NAT networking anyways.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
