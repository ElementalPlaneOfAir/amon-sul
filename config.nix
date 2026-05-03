{ config, pkgs, ... }: {
  # ---------------------------------------------------------------------------
  # Domain
  # ---------------------------------------------------------------------------
  cococoir.domain = "interdim.net";

  # ---------------------------------------------------------------------------
  # Services
  # ---------------------------------------------------------------------------
  cococoir.services.jellyfin.enable = true;
  cococoir.services.vaultwarden.enable = true;
  cococoir.services.forgejo.enable = true;
  cococoir.services.matrix.enable = true;
  cococoir.services.cryptpad.enable = true;

  # ---------------------------------------------------------------------------
  # Proxy (client side — tunnels to VPS)
  # ---------------------------------------------------------------------------
  cococoir.proxy.client = {
    enable = true;
    serverAddress = "66.179.138.70";
    credentialsFile = config.clan.core.vars.generators.rathole-tokens.files.client-tokens.path;
  };

  # ---------------------------------------------------------------------------
  # Networking (local)
  # ---------------------------------------------------------------------------
  networking.interfaces.enp11s0.useDHCP = false;
  networking.interfaces.enp11s0.ipv4.addresses = [
    { address = "192.168.0.7"; prefixLength = 24; }
  ];
  networking.defaultGateway = {
    address = "192.168.0.1";
    interface = "enp11s0";
  };
  networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];

  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "enp11s0";
      bind-interfaces = true;
      server = [ "8.8.8.8" "1.1.1.1" ];
      address = [
        "/${config.networking.hostName}.internal/192.168.0.7"
        "/${config.cococoir.domain}/192.168.0.7"
      ];
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 53 80 111 2049 4000 4001 4002 443 20048 ];
    allowedUDPPorts = [ 53 80 111 2049 4000 4001 4002 443 20048 ];
  };

  # ---------------------------------------------------------------------------
  # Storage & NFS
  # ---------------------------------------------------------------------------
  fileSystems."/backup" = {
    device = "/dev/disk/by-uuid/7b72c3a2-9a4b-4f43-b787-c179ec71847e";
    fsType = "btrfs";
    options = [ "users" "nofail" "x-gvfs-show" ];
  };

  fileSystems."/media" = {
    device = "/dev/disk/by-uuid/5424a16e-700b-4620-b7f9-713a1619eb88";
    fsType = "btrfs";
    options = [ "users" "nofail" "x-gvfs-show" ];
  };

  fileSystems."/export/media" = {
    device = "/media";
    fsType = "none";
    options = [ "bind" ];
  };

  services.nfs.server = {
    enable = true;
    exports = ''
      /media   192.168.0.0/16(rw,nohide,insecure,no_subtree_check)
    '';
  };

  # ---------------------------------------------------------------------------
  # Boot & Locale
  # ---------------------------------------------------------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  i18n.defaultLocale = "en_US.UTF-8";

  # ---------------------------------------------------------------------------
  # User tweaks
  # ---------------------------------------------------------------------------
  users.users.nicole.extraGroups = [ "jellyfin" ];
  users.users.brad.extraGroups = [ "jellyfin" ];

  # ---------------------------------------------------------------------------
  # Containers & Podman
  # ---------------------------------------------------------------------------
  virtualisation.containers = {
    enable = true;
    registries.search = [ "docker.io" ];
    policy = {
      default = [ { type = "insecureAcceptAnything"; } ];
      transports = {
        docker-daemon = {
          "" = [ { type = "insecureAcceptAnything"; } ];
        };
      };
    };
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # ---------------------------------------------------------------------------
  # Packages
  # ---------------------------------------------------------------------------
  environment.variables.EDITOR = "nvim";
  environment.systemPackages = with pkgs; [
    zellij
    tmux
    wget
    btop
    ripgrep-all
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    wireguard-tools
    dive
    podman-tui
    docker-compose
    podman-compose
  ];

  system.stateVersion = "24.11";
}
