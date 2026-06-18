{ config, ... }: {
  imports = [ ./disk-config.nix ];

  networking.hostName = "vps";
  networking.useDHCP = true;

  # Proxy server configuration
  tunnel.server = {
    enable = true;
    bindAddress = "0.0.0.0";
    credentialsFile = config.clan.core.vars.generators.rathole-tokens.files.server-tokens.path;
    extraServices = {
      minecraft_java = {
        bind_addr = "0.0.0.0:25565";
      };
      minecraft_bedrock = {
        bind_addr = "0.0.0.0:19132";
        type = "udp";
      };
    };
    extraTCPPorts = [ 25565 ];
    extraUDPPorts = [ 19132 ];
  };

  # SSH hardening
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  time.timeZone = "America/Denver";

  # Clan deployment target
  clan.core.networking.targetHost = "root@66.179.138.70";

  system.stateVersion = "24.11";
}
