{ config, ... }: {
  imports = [ ./disk-config.nix ];

  networking.hostName = "vps";
  networking.useDHCP = true;

  # Proxy server configuration
  cococoir.proxy.server = {
    enable = true;
    bindAddress = "0.0.0.0";
    credentialsFile = config.clan.core.vars.generators.rathole-tokens.files.server-tokens.path;
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
