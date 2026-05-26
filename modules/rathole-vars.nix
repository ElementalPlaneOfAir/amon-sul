{ ... }: {
  flake.modules.nixos.ratholeVars = {
    clan.core.vars.generators.rathole-tokens = {
      share = true;
      files.client-tokens = {};
      files.server-tokens = {};
      script = ''
        randhex() {
          od -An -tx1 -N32 < /dev/urandom | tr -d ' \n'
        }
        TOKEN_HTTP=$(randhex)
        TOKEN_HTTPS=$(randhex)
        TOKEN_HTTPS_UDP=$(randhex)
        TOKEN_MINECRAFT_JAVA=$(randhex)
        TOKEN_MINECRAFT_BEDROCK=$(randhex)
        cat > $out/client-tokens <<EOF
[client.services.http]
token = "$TOKEN_HTTP"
[client.services.https]
token = "$TOKEN_HTTPS"
[client.services.https_udp]
token = "$TOKEN_HTTPS_UDP"
[client.services.minecraft_java]
token = "$TOKEN_MINECRAFT_JAVA"
[client.services.minecraft_bedrock]
token = "$TOKEN_MINECRAFT_BEDROCK"
EOF
        cat > $out/server-tokens <<EOF
[server.services.http]
token = "$TOKEN_HTTP"
[server.services.https]
token = "$TOKEN_HTTPS"
[server.services.https_udp]
token = "$TOKEN_HTTPS_UDP"
[server.services.minecraft_java]
token = "$TOKEN_MINECRAFT_JAVA"
[server.services.minecraft_bedrock]
token = "$TOKEN_MINECRAFT_BEDROCK"
EOF
      '';
    };
  };
}
