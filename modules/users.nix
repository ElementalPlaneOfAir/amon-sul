{ inputs, ... }: {
  imports = [ inputs.flake-parts.flakeModules.modules ];

  flake.modules.nixos.users = { pkgs, ... }: {
    cococoir.adminUsers = {
      nicole = {
        keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBfMZjr6H4oK3qSBTxjZrMZptWXdzYC6QV4bdS892Ls nicole@vermissian"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN1tyFv2UbkAJMx2U6bp8OwRx5wMpK7/DxSslcPS0sWY nicole@incarnadine"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDBQresTdgx3Se26QxvwD/S9SaCRCWL8dvZwZ6IM62b2 nicole@cheddar"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKdPzSlJ3TCzPy7R2s2OOBJbBb+U5NY8dwMlGH9wm4Ot nicole@apiarist"
        ];
      };

      brad = {
        keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILBunjCx4C8YjSS9X9zH+a/aRTrp3J/0US/fAKd2SVQ9 brad@mina-rau"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHaOgK4fO5gTB79Infge2b+31VzXnC23lqV7m5NA+xuz bvenner@proton.me"
        ];
      };
    };

    users.users.nicole.shell = pkgs.fish;
    users.users.brad.shell = pkgs.fish;
  };
}
