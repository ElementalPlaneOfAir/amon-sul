{ ... }: {
  flake.modules.nixos.autobrrVars = {
    clan.core.vars.generators.autobrr-session = {
      files.session-secret = {};
      script = ''
        head -c 32 /dev/urandom | base64 > $out/session-secret
      '';
    };
  };
}
