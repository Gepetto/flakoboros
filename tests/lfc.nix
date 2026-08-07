{
  name = "lfc";

  enableDebugHook = true;
  sshBackdoor.enable = true;

  nodes = {
    lfc =
      { pkgs, ... }:
      {
        networking = {
          useDHCP = true;
          nameservers = [ "1.1" ];
        };

        nix.settings = {
          experimental-features = [
            "flakes"
            "nix-command"
          ];
          extra-substituters = [
            "https://gepetto.cachix.org"
            "https://attic.iid.ciirc.cvut.cz/ros"
          ];
          extra-trusted-public-keys = [
            "gepetto.cachix.org-1:toswMl31VewC0jGkN6+gOelO2Yom0SOHzPwJMY2XiDY="
            "ros:JR95vUYsShSqfA1VTYoFt1Nz6uXasm5QrcOsGry9f6Q="
          ];
        };

        programs.git.enable = true;

        virtualisation = {
          cores = 4;
          diskSize = 50 * 1024;
          memorySize = 4096;
        };
      };
  };

  testScript = ''
    lfc.wait_for_unit("multi-user.target")
    lfc.wait_until_succeeds("ping -c 1 github.com", timeout=10)

    lfc.succeed("git clone https://github.com/loco-3d/linear-feedback-controller /lfc")
    lfc.succeed("cd /lfc; nix develop --command 'cmake -B build'")
    lfc.succeed("cd /lfc; nix develop --command 'cmake --build build'")
    lfc.succeed("cd /lfc; nix develop --command 'cmake --build build -t test'")
    lfc.succeed("cd /lfc; nix build -L")
  '';
}
