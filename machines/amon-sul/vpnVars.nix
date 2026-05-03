{ ... }: {
  clan.core.vars.generators.privado-wireguard = {
    prompts.wireguard-conf = {
      description = "Paste your Privado VPN WireGuard configuration";
      type = "multiline";
      persist = true;
    };
  };
}
