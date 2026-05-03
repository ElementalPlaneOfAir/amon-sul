{ config, pkgs, ... }: {
  imports = [
    ./hardware.nix
    ../../config.nix
  ];

  networking.hostName = "amon-sul";

  # Clan deployment target
  clan.core.networking.targetHost = "root@192.168.0.7";
}
