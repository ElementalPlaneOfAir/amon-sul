{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
    ../../config.nix
  ];
  nixpkgs.config.permittedInsecurePackages = ["olm-3.2.16"];
  networking.hostName = "amon-sul";
  services.tailscale.enable = true;

  # Clan deployment target
  clan.core.networking.targetHost = "root@192.168.0.7";
}
