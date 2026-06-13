# Global Directives

- Be very honest. Tell me something I need to hear even if I don't want to hear it.
- Be proactive and flag issues before they become problems.
- Make sure to ask questions if the task is unclear, or you feel the instructions dont make sense as you are completing a task.
- "Perfection is not achieved when there is nothing left to add, it is achieved when there is nothing left to remove."

# Amon-sul — Agent Context

## Overview

Amon-sul is a **personal NixOS infrastructure flake** that deploys two machines using [Clan](https://clan.lol):

| Machine | Role | Hardware | Target Host | Public IP |
|---------|------|----------|-------------|-----------|
| `amon-sul` | Home server | Custom x86_64 desktop | `root@192.168.0.7` | — (behind NAT) |
| `vps` | Public proxy | IONOS VPS | `root@66.179.138.70` | `66.179.138.70` |

The home server hosts all services; the VPS only runs a **rathole server** to tunnel public internet traffic back to the home server. TLS termination and reverse-proxying happen on the home server via **Caddy**.

## Domain

All services live under **`interdim.net`**.

## Flake Architecture

- **flake-parts** partitions the flake.
- **clan-core** (`25.11`) provides the deployment framework, remote secret management (`vars`), and machine inventory.
- **cococoir** (local path `/home/nicole/cococoir`) is imported as the self-hosting service library.
- **vpn-confinement** isolates Transmission inside a WireGuard namespace.
- **sops-nix** handles encrypted secrets.

## Machine Definitions

### `amon-sul` (Home Server)

Imports (in order):
1. `injectInputs` — passes flake inputs into the module args.
2. `vpn-confinement.nixosModules.default`
3. `cococoir.nixosModules.default`
4. `inputs.gdoc-extract.nixosModules.default` — Google Docs extraction server (custom service).
5. `inputs.self.modules.nixos.ratholeVars` — generates shared rathole tokens via Clan vars.
6. `./machines/amon-sul/vpnVars.nix` — prompts for the WireGuard VPN config.
7. `inputs.self.modules.nixos.users` — SSH keys for `nicole` and `brad`.
8. `./machines/amon-sul/configuration.nix` — hardware + main config.

### `vps` (Public Proxy)

Imports:
1. `injectInputs`
2. `cococoir.nixosModules.default`
3. `inputs.self.modules.nixos.ratholeVars`
4. `inputs.self.modules.nixos.users`
5. `./machines/vps/configuration.nix` — disk config + minimal server config.

The VPS intentionally runs **only** the rathole server, SSH, and a firewall.

## Key Files

| Path | Purpose |
|------|---------|
| `config.nix` | **Main service manifest.** Enables/disables cococoir services, sets local networking (static IP `192.168.0.7`, DNSMASQ, NFS), storage mounts, firewall rules, podman, and extra packages. |
| `machines/amon-sul/configuration.nix` | Hostname (`amon-sul`) + imports `hardware.nix` and `config.nix`. Sets Clan deployment target. |
| `machines/amon-sul/hardware.nix` | Generated hardware configuration for the home server (AMD, NVMe, EFI). |
| `machines/amon-sul/vpnVars.nix` | Clan vars generator that prompts for the Privado WireGuard config file. |
| `machines/vps/configuration.nix` | Hostname (`vps`), rathole server config, SSH hardening, firewall, deployment target. |
| `machines/vps/disk-config.nix` | Disko configuration for the VPS (`/dev/vda`, GPT, single ext4 root). |
| `modules/rathole-vars.nix` | Defines `flake.modules.nixos.ratholeVars`. Uses Clan `vars.generators.rathole-tokens` to create cryptographically random tokens for `http`, `https`, `https_udp`, `smtp`, `submission`, and `imaps` services. Tokens are shared between client and server. |
| `modules/autobrr-vars.nix` | Defines `flake.modules.nixos.autobrrVars`. Uses Clan `vars.generators.autobrr-session` to generate a random 32-byte base64 session secret for the autobrr web interface. |
| `modules/users.nix` | Defines `flake.modules.nixos.users`. Creates admin users `nicole` and `brad` with their SSH public keys and sets `fish` as the login shell. |

## Secret & Variable Management (Clan)

Clan stores per-machine and shared variables under `vars/` and encrypted secrets under `sops/`.

- `vars/per-machine/amon-sul/privado-wireguard/wireguard-conf/secret` — WireGuard VPN config.
- `vars/per-machine/amon-sul/autobrr-session/session-secret/secret` — autobrr session secret.
- `vars/shared/rathole-tokens/client-tokens/secret` — Rathole client TOML credentials.
- `vars/shared/rathole-tokens/server-tokens/secret` — Rathole server TOML credentials.

## Services Currently Enabled (`config.nix`)

| Service | Domain | Public | Notes |
|---------|--------|--------|-------|
| Jellyfin | `jellyfin.interdim.net` | ✅ | — |
| Vaultwarden | `vault.interdim.net` | ✅ | — |
| Forgejo | `git.interdim.net` | ✅ | — |
| Matrix | `matrix.interdim.net` | ✅ | `.well-known` on base domain. |
| mautrix-gmessages | *(none)* | — | Matrix-Google Messages bridge. Appservice, no public vhost. Requires manual registration in Matrix admin room after first deploy. |
| CryptPad | `cryptpad.interdim.net` | ✅ | — |
| qBittorrent | `torrent.interdim.net` | ❌ | VPN-confined via WireGuard. WebUI on 8080. |
| autobrr | `autobrr.interdim.net` | ❌ | Release automation. Hands matched releases to qBittorrent. Session secret via `clan.core.vars.generators.autobrr-session`. |
| Jellyseerr | `requests.interdim.net` | ✅ | Unified movie/TV request UI. Points at Jellyfin + qBittorrent. |
| gdoc-extract | `misc.interdim.net` | ✅ | Custom Go service imported via `inputs.gdoc-extract`. |

## Storage

Cococoir provides a distributed S3-compatible object store ([Garage](https://garagehq.deuxfleurs.fr/)) via `cococoir.storage.*`. On `amon-sul` this is configured as a **single-node, 1-zone cluster** with one `media` bucket at RF=1, FUSE-mounted at `/media/entertain`.

```nix
cococoir.storage = {
  enable = true;
  cluster = {
    clusterId = "amon-sul";
    bootstrapPeers = []; # single-node
    layout.zones = [ { id = "z1"; capacity = "1T"; } ];
  };
  node = {
    id = "amon-sul";
    address = "192.168.0.7:3901";
    zone = "z1";
    dataDir  = "/var/lib/cococoir/garage/data";
    metaDir  = "/var/lib/cococoir/garage/meta";
    capacity = "1T";
  };
  buckets.media = { replicationFactor = 1; };
  mounts.media  = { bucket = "media"; mountPoint = "/media/entertain"; readOnly = false; };
};
```

### What you get

- **Garage daemon** running locally on `127.0.0.1:3900` (S3) and `:3901` (RPC).
- **One bucket** `media` with a single global access key, generated at first boot and stored at `/var/lib/cococoir/garage/global/`.
- **A FUSE mount** at `/media/entertain` (geesefs, `--umask=000 --allow-other`) — appears as a regular POSIX directory.
- **qBittorrent saves there by default** (its `downloadDir` defaults to `/media/entertain/downloads`).

### Native-S3 access (Jellyfin, Rclone, S3 CLI, etc.)

Read credentials from the derived view:

```nix
cococoir.storage.derived.buckets.media = {
  endpoint              = "http://192.168.0.7:3900";
  region                = "garage";
  accessKeyId           = "GK...";                     # populated at first boot
  secretAccessKeyFile   = "/var/lib/cococoir/garage/global/secret-access-key";
  replicationFactor     = 1;
  intendedReplicationFactor = 1;
};
```

The access key is generated on first boot by `garage-bucket-init.service`. Before that boot, `accessKeyId` is an empty string — that's why `Jellyfin` is not auto-configured to use the S3 endpoint; it must be added as a library path manually (see Post-deploy below).

### Path layout on disk

| Path | Backing |
|------|---------|
| `/media` | btrfs (physical disk, UUID `5424a16e-…`) — existing local media library |
| `/export/media` | bind-mount of `/media` — NFS-shared on the LAN |
| `/media/entertain` | **FUSE geesefs mount of the `media` S3 bucket** — this is the new, distributed layer |
| `/media/entertain/downloads` | where qBittorrent saves completed torrents (default `downloadDir`) |
| `/var/lib/cococoir/garage/data` | Garage's local data dir (on root volume) |
| `/var/lib/cococoir/garage/meta` | Garage's metadata DB (SSD if possible) |
| `/var/lib/cococoir/garage/global/` | Generated at first boot: `access-key-id` + `secret-access-key` |

The btrfs `/media` and the FUSE `/media/entertain` are **separate**: the btrfs disk is your existing local library (movies that have been verified and removed from seed); the FUSE mount is the new, distributed layer (active downloads and any new media added to the cluster).

### Scaling out (1 → 3 nodes)

To add a second node, edit each machine's `flake.nix` and `config.nix`:

1. Add a second entry to `cluster.layout.zones` (e.g. `{ id = "z2"; capacity = "1T"; }`).
2. On the **existing** node, set `cluster.bootstrapPeers = [ "<new-node-address>:3901" ]`.
3. On the **new** node, set `cluster.bootstrapPeers = [ "<existing-node-address>:3901" ]` (everything except self).
4. Reduce the `media` bucket's `replicationFactor` to `1` (or accept the eval-time RF assertion if you want to use this cluster for RF=3 buckets later).
5. Deploy both. Garage will gossip and rebalance the data.

### Post-deploy (one-time, after first boot)

1. **Check that the bucket init ran**: `systemctl status garage-bucket-init.service` should show `active (exited)`.
2. **Verify the access key** is generated: `cat /var/lib/cococoir/garage/global/access-key-id` should be a `GK...` string.
3. **Add a Jellyfin library** pointing at `/media/entertain` (Movies and/or Shows). The default Jellyfin config has no library configured; add one via the web UI on first login at `https://jellyfin.interdim.net/`.
4. **(Optional) Rclone or other native-S3 clients**: use the endpoint, key, and secret file from the derived view above.

## Networking Topology

```
Internet → VPS (66.179.138.70) [rathole server :443]
                ↓ (encrypted tunnel)
         Home Server (192.168.0.7) [rathole client :443]
                ↓
            Caddy (reverse proxy + TLS)
                ↓
         Individual services on localhost
```

- DNSMASQ on the home server resolves `*.interdim.net` and `amon-sul.internal` to `192.168.0.7`.
- The firewall on the home server explicitly opens many ports including NFS (`111`, `2049`, `20048`) and custom ports (`4000`–`4002`).

## How to Add a New Service

### Option A — Generic Custom Service (recommended for bespoke / third-party projects)

Use this when the service does **not** have an upstream NixOS module and is defined in its own flake.

1. **In the service's repo** (e.g. a Go project):
   - Add a `flake.nix` that exports `packages.default` and `nixosModules.default`.
   - The `nixosModules.default` should define `services.<name>` options and a `systemd.services.<name>` unit that binds to `127.0.0.1`.

2. **In `amon-sul/flake.nix`**:
   - Add the service repo as a flake input (e.g. `gdoc-extract`).
   - Import `inputs.<name>.nixosModules.default` in the `amon-sul` machine imports.

3. **In `amon-sul/config.nix`**:
   - Enable the service's own module:
     ```nix
     services.gdoc-extract = {
       enable = true;
       bindAddress = "127.0.0.1";
       port = 8080;
     };
     ```
   - Add the Cococoir generic custom service entry:
     ```nix
     cococoir.services.custom.gdoc-extract = {
       enable = true;
       domain = "misc.interdim.net";
       port = 8080;
       public = true;
     };
     ```

### Option B — Dedicated Cococoir Wrapper (recommended for upstream NixOS services)

Use this for services that already have a NixOS module (e.g. Jellyfin, Vaultwarden).

1. **In `cococoir`** (the library):
   - Create a new module file (e.g. `modules/services/misc.nix`).
   - Follow the established pattern: `enable`, `domain`, `public` options; enable the upstream service; add a Caddy virtual host.
   - Import the module in `cococoir/flake.nix`.

2. **In `amon-sul`** (this repo):
   - Add the service block to `config.nix`:
     ```nix
     cococoir.services.misc = {
       enable = true;
       domain = "misc.interdim.net";
       public = true;
     };
     ```

### Rathole / Tunnel Considerations

- For standard HTTP/HTTPS traffic, **no extra rathole changes** are needed because ports 80/443 are already forwarded.
- If the service uses a new non-HTTP port that must be tunneled:
  - Add a new token to `modules/rathole-vars.nix` in the generator script (both client and server stanzas).
  - Add the corresponding service stanza to `cococoir/modules/proxy/client.nix` and `cococoir/modules/proxy/server.nix`.

### Deploy

```bash
nix build --dry-run .#nixosConfigurations.amon-sul.config.system.build.toplevel
clan machines update amon-sul
clan machines update vps
```

## Deployment Commands

Inside the dev shell (`nix develop` or via direnv):

```bash
# Update home server
clan machines update amon-sul

# Update VPS
clan machines update vps
```

Clan handles SSH, secret syncing, and activation automatically.

## State Version

Both machines use `system.stateVersion = "24.11"`.

## Important Notes for Agents

- **Do not commit plaintext secrets.** Secrets live in `vars/` and `sops/` and are managed by Clan.
- **Do not change `rathole-vars.nix` tokens** unless you intend to rotate credentials on both machines.
- **The VPS is intentionally minimal.** Avoid adding heavy services there; keep them on `amon-sul` and tunnel via rathole.
- **qBittorrent is VPN-confined.** If you add other services that need VPN isolation, follow the `vpnNamespaces.wg` + `systemd.services.<name>.vpnConfinement` pattern used in `media-stack.nix`.
- **mautrix-gmessages requires manual appservice registration.** After first deploy, the bridge generates `/var/lib/mautrix-gmessages/gmessages-registration.yaml`. Copy its contents and paste it into the Matrix admin room with `!admin appservices register` followed by the YAML block. Then follow the bridge authentication docs at <https://docs.mau.fi/bridges/go/gmessages/authentication.html> to pair an Android phone.
- **`/media` is the btrfs local disk; `/media/entertain` is the Garage S3 FUSE mount.** They are separate. The FUSE mount appears as a POSIX directory but the data is actually on the local Garage node (single-node for now). Don't add a Jellyfin library at `/media` if you want it to be S3-backed — point it at `/media/entertain` instead.
