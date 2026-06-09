{
  description = "Personal infrastructure: amon-sul home server and VPS proxy";

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (
      {self, ...}: let
        injectInputs = {...}: {
          _module.args.inputs = inputs;
        };
      in {
        imports = [
          inputs.clan-core.flakeModules.default
          (inputs.import-tree ./modules)
        ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
          "x86_64-darwin"
        ];

        perSystem = {
          pkgs,
          system,
          ...
        }: {
          devShells.default = pkgs.mkShell {
            packages = [inputs.clan-core.packages.${system}.clan-cli];
          };
        };

        clan = {
          meta.name = "amon-sul";
          meta.domain = "interdim.net";

          machines = {
            amon-sul = {
              nixpkgs.hostPlatform = "x86_64-linux";
              imports = [
                injectInputs
                inputs.vpn-confinement.nixosModules.default
                inputs.cococoir.nixosModules.default
                inputs.gdoc-extract.nixosModules.default
                inputs.nix-minecraft.nixosModules.minecraft-servers
                inputs.self.modules.nixos.ratholeVars
                inputs.self.modules.nixos.autobrrVars
                ./machines/amon-sul/vpnVars.nix
                inputs.self.modules.nixos.users
                ./machines/amon-sul/configuration.nix
              ];
            };

            vps = {
              nixpkgs.hostPlatform = "x86_64-linux";
              imports = [
                injectInputs
                inputs.cococoir.nixosModules.default
                inputs.self.modules.nixos.ratholeVars
                inputs.self.modules.nixos.users
                ./machines/vps/configuration.nix
              ];
            };
          };
        };
      }
    );

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    clan-core = {
      url = "https://git.clan.lol/clan/clan-core/archive/25.11.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.sops-nix.follows = "sops-nix";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vpn-confinement = {
      url = "github:Maroka-chan/VPN-Confinement";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cococoir = {
      # url = "github:ElementalPlaneofAir/cococoir";
      url = "path:/home/nicole/cococoir";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gdoc-extract = {
      url = "path:/home/nicole/Documents/small-jobs/mom-google-docs-extraction-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
