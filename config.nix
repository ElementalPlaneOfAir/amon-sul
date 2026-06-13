{
  config,
  pkgs,
  inputs,
  ...
}: {
  # ---------------------------------------------------------------------------
  # Packages overlay
  # ---------------------------------------------------------------------------
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [inputs.nix-minecraft.overlay];

  # ---------------------------------------------------------------------------
  # Domain
  # ---------------------------------------------------------------------------
  cococoir.domain = "interdim.net";

  # ---------------------------------------------------------------------------
  # Admin Authentication (Caddy basicauth for qBittorrent, autobrr, Jellyseerr, OctoPrint)
  # Generate your own hash: mkpasswd -m bcrypt
  # OctoPrint: ensure your admin account is named "admin" for auto-login.
  # ---------------------------------------------------------------------------
  cococoir.adminAuth = {
    enable = true;
    users.nicole = "$2b$05$DRPpuqQUFqbRI5o8mXytuOgCpGFcVkcDOWSC7Mn4vUTbPv4LhRRz6"; # changeme
  };

  # ---------------------------------------------------------------------------
  # Services
  # ---------------------------------------------------------------------------
  cococoir.services.jellyfin = {
    enable = true;
    domain = "jellyfin.interdim.net";
    public = true;
  };

  cococoir.services.vaultwarden = {
    enable = true;
    domain = "vault.interdim.net";
    public = true;
  };

  cococoir.services.forgejo = {
    enable = true;
    domain = "git.interdim.net";
    public = true;
  };

  cococoir.services.matrix = {
    enable = true;
    domain = "matrix.interdim.net";
    public = true;
  };

  cococoir.services.mautrix-gmessages = {
    enable = true;
  };

  cococoir.services.cryptpad = {
    enable = true;
    domain = "cryptpad.interdim.net";
    public = true;
  };

  cococoir.services.kavita = {
    enable = true;
    domain = "kavita.interdim.net";
    public = true;
  };

  cococoir.services.octoprint = {
    enable = true;
    domain = "octoprint.interdim.net";
    public = false;
  };

  cococoir.services.qbittorrent = {
    enable = true;
    domain = "torrent.interdim.net";
    public = false;
    vpnConfigFile = config.clan.core.vars.generators.privado-wireguard.files.wireguard-conf.path;
  };

  cococoir.services.autobrr = {
    enable = true;
    domain = "autobrr.interdim.net";
    public = false;
    secretFile = config.clan.core.vars.generators.autobrr-session.files.session-secret.path;
  };

  cococoir.services.jellyseerr = {
    enable = true;
    domain = "requests.interdim.net";
    public = true;
  };

  # ---------------------------------------------------------------------------
  # Custom services (upstream systemd modules imported separately)
  # ---------------------------------------------------------------------------
  services.gdoc-extract = {
    enable = true;
    bindAddress = "127.0.0.1";
    port = 8080;
  };

  cococoir.services.custom.gdoc-extract = {
    enable = true;
    domain = "misc.interdim.net";
    port = 8080;
    public = true;
  };

  # ---------------------------------------------------------------------------
  # Proxy (client side — tunnels to VPS)
  # ---------------------------------------------------------------------------
  cococoir.proxy.client = {
    enable = true;
    serverAddress = "66.179.138.70";
    credentialsFile = config.clan.core.vars.generators.rathole-tokens.files.client-tokens.path;
    extraServices = {
      minecraft_java = {
        local_addr = "127.0.0.1:25565";
      };
      minecraft_bedrock = {
        local_addr = "127.0.0.1:19132";
        type = "udp";
      };
    };
  };

  # ---------------------------------------------------------------------------
  # Networking (local)
  # ---------------------------------------------------------------------------
  networking.interfaces.enp11s0.useDHCP = false;
  networking.interfaces.enp11s0.ipv4.addresses = [
    {
      address = "192.168.0.7";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = {
    address = "192.168.0.1";
    interface = "enp11s0";
  };
  networking.nameservers = ["8.8.8.8" "1.1.1.1"];

  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "enp11s0";
      bind-interfaces = true;
      server = ["8.8.8.8" "1.1.1.1"];
      address = [
        "/${config.networking.hostName}.internal/192.168.0.7"
        "/${config.cococoir.domain}/192.168.0.7"
      ];
    };
  };

  networking.firewall = {
    allowedTCPPorts = [53 80 111 2049 4000 4001 4002 443 20048 25565];
    allowedUDPPorts = [53 80 111 2049 4000 4001 4002 443 20048 19132 24454];
  };

  # ---------------------------------------------------------------------------
  # Cococoir distributed object storage (Garage S3)
  # Single-node, 1-zone cluster. Add zones/nodes here when scaling out.
  # The `media` bucket (RF=1, re-downloadable) is FUSE-mounted at
  # /media/entertain — qBittorrent saves there by default.
  # ---------------------------------------------------------------------------
  cococoir.storage = {
    enable = true;
    cluster = {
      clusterId = "amon-sul";
      bootstrapPeers = []; # single-node cluster
      layout.zones = [
        {
          id = "z1";
          capacity = "1T"; # honest answer: most of /media is for this
        }
      ];
    };
    node = {
      id = "amon-sul";
      address = "192.168.0.7:3901";
      zone = "z1";
      dataDir = "/var/lib/cococoir/garage/data";
      metaDir = "/var/lib/cococoir/garage/meta";
      capacity = "1T";
    };
    buckets.media = {
      replicationFactor = 1; # re-downloadable
    };
    mounts.media = {
      bucket = "media";
      mountPoint = "/media/entertain";
      readOnly = false;
    };
  };

  # ---------------------------------------------------------------------------
  # Storage & NFS
  # ---------------------------------------------------------------------------
  fileSystems."/backup" = {
    device = "/dev/disk/by-uuid/7b72c3a2-9a4b-4f43-b787-c179ec71847e";
    fsType = "btrfs";
    options = ["users" "nofail" "x-gvfs-show"];
  };

  fileSystems."/media" = {
    device = "/dev/disk/by-uuid/5424a16e-700b-4620-b7f9-713a1619eb88";
    fsType = "btrfs";
    options = ["users" "nofail" "x-gvfs-show"];
  };

  fileSystems."/export/media" = {
    device = "/media";
    fsType = "none";
    options = ["bind"];
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
  users.users.nicole.extraGroups = ["jellyfin"];
  users.users.brad.extraGroups = ["jellyfin"];

  # ---------------------------------------------------------------------------
  # Containers & Podman
  # ---------------------------------------------------------------------------
  virtualisation.containers = {
    enable = true;
    registries.search = ["docker.io"];
    policy = {
      default = [{type = "insecureAcceptAnything";}];
      transports = {
        docker-daemon = {
          "" = [{type = "insecureAcceptAnything";}];
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

  # ---------------------------------------------------------------------------
  # Minecraft Server (Anarchy — Fabric 26.1.2)
  # ---------------------------------------------------------------------------
  services.minecraft-servers = {
    enable = true;
    eula = true;
    openFirewall = true;

    servers.anarchy = {
      enable = true;
      autoStart = true;
      restart = "always";
      # package = pkgs.fabricServers.fabric-26_1_2;
      package = pkgs.fabricServers.fabric-26_1_2.override {
        jre_headless = pkgs.jdk25_headless;
      };
      jvmOpts = "-Xms4G -Xmx8G";

      serverProperties = {
        eula = true;
        server-port = 25565;
        difficulty = 3; # hard
        gamemode = 0; # survival
        max-players = 40;
        motd = "What do I sacrifice?? EVERYTHING!!!!!";
        level-seed = "-3482801611578790576";
        white-list = false;
        spawn-protection = 0;
        pvp = true;
        online-mode = true;
        enforce-secure-profile = false;
        view-distance = 12;
        simulation-distance = 10;
        "query.port" = 25565;
        "rcon.port" = 25575;
        enable-rcon = false;
        enable-status = true;
        hide-online-players = false;
      };
      symlinks = let
        modpack = pkgs.fetchPackwizModpack {
          src = ./modpack;
          # packHash = "";
          # packHash = "";
          packHash = "sha256-DrvzPOfI/jiBncFZ7Qt++lQSGbNixtQKgTGEmDVzVUc=";
          side = "server";
        };
      in {
        "mods" = "${modpack}/mods";
      };
    };
  };

  system.stateVersion = "24.11";
}
