{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/develop";
    nixpkgs.follows = "nix-ros-overlay/nixpkgs";
    systems.follows = "nix-ros-overlay/flake-utils/systems";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      let
        flakeModule = inputs.flake-parts.lib.importApply ./module {
          inherit (inputs) nixpkgs nix-ros-overlay;
        };
      in
      {
        systems = import inputs.systems;
        flake = {
          inherit flakeModule;
          lib = import ./lib { inherit lib; };
        };
        imports = [
          inputs.treefmt-nix.flakeModule
          flakeModule
        ];
        perSystem =
          { system, ... }:
          {
            treefmt = {
              # workaround  https://github.com/numtide/treefmt-nix/issues/352
              pkgs = inputs.nixpkgs.legacyPackages.${system};
              programs = {
                deadnix.enable = true;
                keep-sorted.enable = true;
                nixfmt.enable = true;
              };
            };
          };
      }
    );
}
