{ ... }: {
  flake.modules.nixos.arrStack = {
    pkgs,
    config,
    lib,
    ...
  }: let
    machineName = config.networking.hostName;
  in {
    clan.core.vars.generators.privado-wireguard = {
      prompts.wireguard-conf = {
        description = "Paste your Privado VPN WireGuard configuration";
        type = "multiline";
        persist = true;
      };
    };

    vpnNamespaces.wg = {
      enable = true;
      wireguardConfigFile = config.clan.core.vars.generators.privado-wireguard.files.wireguard-conf.path;
      accessibleFrom = ["127.0.0.1"];
      portMappings = [
        {
          from = 9091;
          to = 9091;
        }
      ];
      openVPNPorts = [
        {
          port = 51413;
          protocol = "both";
        }
      ];
    };

    systemd.services.transmission.vpnConfinement = {
      enable = true;
      vpnNamespace = "wg";
    };

    services.transmission = {
      enable = true;
      package = pkgs.transmission_4;
      openRPCPort = false;
      openPeerPorts = true;
      user = "jellyfin";
      group = "jellyfin";
      settings = {
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist-enabled = false;
        peer-port = 51413;
        download-dir = "/media/entertain/downloads";
      };
    };

    services.prowlarr = {
      enable = true;
      openFirewall = false;
      settings.server.bindaddress = "127.0.0.1";
    };

    services.radarr = {
      enable = true;
      openFirewall = false;
      user = "jellyfin";
      group = "jellyfin";
      settings.server.bindaddress = "127.0.0.1";
    };

    services.sonarr = {
      enable = true;
      openFirewall = false;
      user = "jellyfin";
      group = "jellyfin";
      settings.server.bindaddress = "127.0.0.1";
    };

    services.lidarr = {
      enable = true;
      openFirewall = false;
      user = "jellyfin";
      group = "jellyfin";
      settings.server.bindaddress = "127.0.0.1";
    };

    services.bazarr = {
      enable = true;
      openFirewall = false;
      user = "jellyfin";
      group = "jellyfin";
    };

    services.flaresolverr = {
      enable = true;
      openFirewall = false;
    };

    systemd.tmpfiles.rules = [
      "d /media/entertain           0775 jellyfin jellyfin -"
      "d /media/entertain/books     0775 jellyfin jellyfin -"
      "d /media/entertain/downloads 0775 jellyfin jellyfin -"
      "d /media/entertain/dvr       0775 jellyfin jellyfin -"
      "d /media/entertain/games     0775 jellyfin jellyfin -"
      "d /media/entertain/movies    0775 jellyfin jellyfin -"
      "d /media/entertain/music     0775 jellyfin jellyfin -"
      "d /media/entertain/papers    0775 jellyfin jellyfin -"
      "d /media/entertain/shows     0775 jellyfin jellyfin -"
      "d /media/entertain/subtitles 0775 jellyfin jellyfin -"
    ];

    networking.firewall = {
      allowedTCPPorts = [ 51413 ];
      allowedUDPPorts = [ 51413 ];
    };

    services.caddy.virtualHosts = {
      "http://transmission.${machineName}.internal".extraConfig = ''
        reverse_proxy 192.168.15.1:9091
      '';
      "http://prowlarr.${machineName}.internal".extraConfig = ''
        reverse_proxy localhost:9696
      '';
      "http://radarr.${machineName}.internal".extraConfig = ''
        reverse_proxy localhost:7878
      '';
      "http://sonarr.${machineName}.internal".extraConfig = ''
        reverse_proxy localhost:8989
      '';
      "http://lidarr.${machineName}.internal".extraConfig = ''
        reverse_proxy localhost:8686
      '';
      "http://bazarr.${machineName}.internal".extraConfig = ''
        reverse_proxy localhost:6767
      '';
      "http://flaresolverr.${machineName}.internal".extraConfig = ''
        reverse_proxy localhost:8191
      '';
    };
  };
}
