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
| `modules/users.nix` | Defines `flake.modules.nixos.users`. Creates admin users `nicole` and `brad` with their SSH public keys and sets `fish` as the login shell. |

## Secret & Variable Management (Clan)

Clan stores per-machine and shared variables under `vars/` and encrypted secrets under `sops/`.

- `vars/per-machine/amon-sul/privado-wireguard/wireguard-conf/secret` — WireGuard VPN config.
- `vars/shared/rathole-tokens/client-tokens/secret` — Rathole client TOML credentials.
- `vars/shared/rathole-tokens/server-tokens/secret` — Rathole server TOML credentials.

## Services Currently Enabled (`config.nix`)

| Service | Domain | Public | Notes |
|---------|--------|--------|-------|
| Jellyfin | `jellyfin.interdim.net` | ✅ | — |
| Vaultwarden | `vault.interdim.net` | ✅ | — |
| Forgejo | `git.interdim.net` | ✅ | — |
| Matrix | `matrix.interdim.net` | ✅ | `.well-known` on base domain. |
| CryptPad | `cryptpad.interdim.net` | ✅ | — |
| Transmission | `transmission.interdim.net` | ❌ | VPN-confined via WireGuard. |
| Prowlarr | `prowlarr.interdim.net` | ❌ | — |
| Radarr | `radarr.interdim.net` | ❌ | — |
| Sonarr | `sonarr.interdim.net` | ❌ | — |
| Lidarr | `lidarr.interdim.net` | ❌ | — |
| Bazarr | `bazarr.interdim.net` | ❌ | — |
| FlareSolverr | `flaresolverr.interdim.net` | ❌ | — |
| gdoc-extract | `misc.interdim.net` | ✅ | Custom Go service imported via `inputs.gdoc-extract`. |

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
- **Transmission is VPN-confined.** If you add other services that need VPN isolation, follow the `vpnNamespaces.wg` + `systemd.services.<name>.vpnConfinement` pattern used in `media-stack.nix`.
