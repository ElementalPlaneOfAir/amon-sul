{ config, pkgs, inputs, ... }: {
  # ---------------------------------------------------------------------------
  # Packages overlay
  # ---------------------------------------------------------------------------
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

  # ---------------------------------------------------------------------------
  # Domain
  # ---------------------------------------------------------------------------
  cococoir.domain = "interdim.net";

  # ---------------------------------------------------------------------------
  # Admin Authentication (Caddy basicauth for *rr stack, Transmission, OctoPrint)
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

  cococoir.services.transmission = {
    enable = true;
    domain = "transmission.interdim.net";
    public = false;
    vpnConfigFile = config.clan.core.vars.generators.privado-wireguard.files.wireguard-conf.path;
  };

  cococoir.services.prowlarr = {
    enable = true;
    domain = "prowlarr.interdim.net";
    public = false;
  };

  cococoir.services.radarr = {
    enable = true;
    domain = "radarr.interdim.net";
    public = false;
  };

  cococoir.services.sonarr = {
    enable = true;
    domain = "sonarr.interdim.net";
    public = false;
  };

  cococoir.services.lidarr = {
    enable = true;
    domain = "lidarr.interdim.net";
    public = false;
  };

  cococoir.services.bazarr = {
    enable = true;
    domain = "bazarr.interdim.net";
    public = false;
  };

  cococoir.services.flaresolverr = {
    enable = true;
    domain = "flaresolverr.interdim.net";
    public = false;
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
    allowedTCPPorts = [ 53 80 111 2049 4000 4001 4002 443 20048 25565 ];
    allowedUDPPorts = [ 53 80 111 2049 4000 4001 4002 443 20048 19132 24454 ];
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
      package = pkgs.fabricServers.fabric-26_1_2;
      jvmOpts = "-Xms4G -Xmx8G";

      serverProperties = {
        server-port = 25565;
        difficulty = 3;            # hard
        gamemode = 0;              # survival
        max-players = 40;
        motd = "Autonomous Self Organized Vanilla Anarchy";
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

      symlinks = {
        mods = pkgs.linkFarmFromDrvs "mods" (builtins.attrValues {
          # --- Core dependencies ---
          FabricAPI = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/TwiSoUFC/fabric-api-0.149.1%2B26.2.jar";
            sha512 = "af3754c67806f93b84827da27bac5134c3e04424d34b96648b78052cfba773d793306ca4064dce8a36f4bb168f23351b83a417192d85c8d4bb6ec737d28e54ae";
          };
          Cicada = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/IwCkru1D/versions/SKXslujb/cicada-lib-0.15.1%2B26.1.jar";
            sha512 = "25a55a4148fc07276e2a65d7931a1ab52b04248d3a1ab6e0253f68cfd84293638dc5a469cb6c00b3f94deb62bc4003b45160d2f69696a449378a1376e52da4ea";
          };
          Lithostitched = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/XaDC71GB/versions/dUL7i4Qf/lithostitched-1.7.7-fabric-26.1.jar";
            sha512 = "d93811321d7e1b11525ebcc326bab9dec0633b85ef3b0d4253dbe299af091b35d369c5e3ace5f8a58ac97a703d9351389b22c07a917cb004e65c268e582d066d";
          };

          # --- Selected mods from Modrinth collection ---
          DoABarrelRoll = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/6FtRfnLg/versions/xjeI6fAx/do_a_barrel_roll-fabric-3.8.4%2B26.1.jar";
            sha512 = "3dfebd3ee012192ae3e99cb31823fe6936c902abafdef2c4c674efdaf04a31da2b23e97b63f4c38002a1e6c598d69f4e3cd4644583d1416a4c50712ce34c8dc6";
          };
          SeedGuard = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/7e8ji5y2/versions/kzMmYXRY/seedguard%2B26.1-pre-3-1.0.1.jar";
            sha512 = "68af3b7dc0d62db2faa3a4d51f55e548732ae4eeafdaac43241746b4f94c179ac68ef12a87d8297ee0e59f907fb7449180d8e1eb9845987b9a4d107570b3e36c";
          };
          Terralith = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/8oi3bsk5/versions/FCzSjHeG/Terralith_26.1_v2.6.2_Fabric.jar";
            sha512 = "5a3be2986a624446c82a8879e34e4c7b09f6f98a1937fd4d9bcf5356b8321f0b9cebb5e567e8d00ae8161d261b108fb7c9a80ebed61f2edb8cdb0852b33cbacc";
          };
          SimpleVoiceChat = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/9eGKb6K1/versions/gVPjsMto/voicechat-fabric-2.6.17%2B26.1.2.jar";
            sha512 = "1eb687a5210e7e15887e84a93195dd8ebcf45d85a2b657d27c711ad01ed8e9096f499fcb84d6564854989ed2c13b6a800665fbb382229977d1125e0d3eb5a836";
          };
          TownsAndTowers = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/DjLobEOy/versions/eN3WLQ3P/t_and_t-fabric-neoforge-1.13.11.jar";
            sha512 = "e318ec6ea4c15b456c188fdaec3447b8ae875efa21961be5fc365a50aacf4bd7b6b939950a48707a20764a78c42eea37e19052e3cc55c843e147dfb788c2e959";
          };
          GrimAC = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/LJNGWSvH/versions/IlySaNCY/grimac-fabric-2.3.74-edc3987.jar";
            sha512 = "ef52e1b0c1b3d753650a6484e2bbbc918b8d63e1b374883f8a4c2b02fc592c961bef5c1ff2d1002105415c788c36d59a54a3bdfa0455f16ea0c375d8075343f7";
          };
          C2ME = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/VSNURh3q/versions/iFyIEVsG/c2me-fabric-mc26.1.2-0.3.7%2Balpha.0.69.jar";
            sha512 = "32e5a21914ecd16b4560d2d59a4c1a96be92841d642cb278acd76461c0fe70e3875944917cb9e51dac719421d75abffd57bcbafe6e297e7477eaf34514857ced";
          };
          LuckPerms = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/Vebnzrzj/versions/fTIdfb46/LuckPerms-Fabric-5.5.42.jar";
            sha512 = "bfe9f0e0e2d9dfe3c1c456298dbd778af02310dabab5d7fb4a54fcc4a4e8c2653bae0be84151d7c52992065d9884cdab97ec1eea6607e7f7cf01126a13be8630";
          };
          Lithium = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/R7MxYvuW/lithium-fabric-0.24.2%2Bmc26.1.2.jar";
            sha512 = "9231ad05667d4eef0348c700bf5160929e0b723d9e145fd97c7fcef9387ac2e6d524fb15d99f47f8f838f1d235324fd750cdcb6603b63aab6085d79fbeaab31b";
          };
          Tectonic = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/lWDHr9jE/versions/jL2ZsTzx/tectonic-3.0.22-fabric-26.1.jar";
            sha512 = "1877b3e7956af4525eeb8758392719fea8c624b0b85c36fd3e37780af4aa5823a3bd6981cefff27364c999ab492abcfea02448a27a404bc41e3b9d924e1bc971";
          };
          NoChatReports = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/qQyHxfxd/versions/2yrLNE3S/NoChatReports-FABRIC-26.1-v2.19.0.jar";
            sha512 = "94d58a1a4cde4e3b1750bdf724e65c5f4ff3436c2532f36a465d497d26bf59f5ac996cddbff8ecdfed770c319aa2f2dcc9c7b2d19a35651c2a7735c5b2124dad";
          };
          AlternateCurrent = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/r0v8vy1s/versions/PGm6TCxh/alternate-current-mc26.1-1.9.0.jar";
            sha512 = "9541b1c5abdc675259043c1b6e71ac48680ee1746635a62b4376a09944899a78f9615bd1a9f8d0b27910dd5e62bbdf3b9d7e4dba91a34f8dd4c3a08f584c5c13";
          };
          AntiXray = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/sml2FMaA/versions/AK313N9m/antixray-fabric-1.4.16%2B26.1.jar";
            sha512 = "213e65ee0584a6602118f9e6ef861d93fc09160c5b32b627d294b920a08d5cfc25a839f25bfb2a53bdf1adeb8d4fd58ca6743a3c993e87cf8b8e2b371ba2a9eb";
          };
          DistantHorizons = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/uCdwusMi/versions/FJrLlu3p/DistantHorizons-3.0.3-b-26.1.2-fabric-neoforge.jar";
            sha512 = "11b252de3308d7299d34625ace65223d9c5d42e52a340bb9c85fa0250c0c354ad594b72f0a827d9d7c046b95dd17a5e500f93954f14d03da9fdac7596c41b514";
          };
          Geyser = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/wKkoqHrH/versions/UinPmiDG/Geyser-Fabric-2.10.0-b1154.jar";
            sha512 = "c1568254371266e9ed1ee23d8c26a1ec40656034f3e088780ac6aba9785f22ae563d56ba4352c2297f6f766fafb5cb4ad075890ababeb92ec267af1e1127d4b3";
          };
        });
      };
    };
  };

  system.stateVersion = "24.11";
}
