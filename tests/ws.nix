{
  name = "ws";

  enableDebugHook = true;
  sshBackdoor.enable = true;

  nodes = {
    ws =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          pkgs.vcs2l
        ];

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

        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };

        virtualisation = {
          cores = 4;
          diskSize = 50 * 1024;
          memorySize = 4096;
        };
      };
  };

  testScript = ''
    ws.execute("mkdir -p /ws/src")
    ws.copy_from_host("${./ws.repos}", "/ws/ws.repos")

    ws.wait_for_unit("multi-user.target")
    ws.wait_until_succeeds("ping -c 1 github.com", timeout=10)

    ws.succeed("cd /ws; vcs import --input ws.repos")
    ws.succeed("cd /ws; flakoboros")
    ws.succeed("cd /ws; nix develop --command 'colcon build'")
    ws.succeed("cd /ws; nix develop --command 'colcon test'")
  '';
}
