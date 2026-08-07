{
  description = "flake to run tests";

  inputs = {
    flakoboros.url = "path:../";

    nixpkgs.follows = "flakoboros/nix-ros-overlay/nixpkgs";
    flake-parts.follows = "flakoboros/flake-parts";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } ({
      systems = [ "x86_64-linux" ];
      perSystem =
        {
          pkgs,
          inputs',
          ...
        }:
        {
          checks = {
            lfc = pkgs.testers.runNixOSTest {
              imports = [ ./lfc.nix ];

              nodes.lfc = {
                nix.nixPath = [ "${inputs.nixpkgs}" ];
              };
            };
            ws = pkgs.testers.runNixOSTest {
              imports = [ ./ws.nix ];

              nodes.ws = {
                nix.nixPath = [ "${inputs.nixpkgs}" ];
                environment.systemPackages = [
                  inputs'.flakoboros.packages.flakoboros
                ];
              };
            };
          };
        };
    });
}
