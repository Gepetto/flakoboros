{
  nix-ros-overlay,
  nixpkgs,
  ...
}:
{
  config,
  lib,
  self,
  ...
}:
let
  cfg = config.flakoboros;
in
{
  options.flakoboros = import ../options.nix { inherit lib; };

  config = {
    flake.overlays = cfg.extends // {
      flakoboros = import ../overlays { inherit config lib; };
    };

    perSystem =
      let
        allNames =
          lib.attrNames (cfg.packages // cfg.overrides // cfg.overrideAttrs)
          ++ cfg.extraPackages
          ++ cfg.extraDevPackages;
        allPyNames =
          lib.attrNames (cfg.pyPackages // cfg.pyOverrides // cfg.pyOverrideAttrs)
          ++ cfg.extraPyPackages
          ++ cfg.extraDevPyPackages;
        allRosNames =
          lib.attrNames (cfg.rosPackages // cfg.rosOverrides // cfg.rosOverrideAttrs)
          ++ cfg.extraRosPackages
          ++ cfg.extraDevRosPackages;
        hasPy = (allPyNames ++ cfg.extraDevPyPackages) != [ ];
        hasRos = (allRosNames ++ cfg.extraDevRosPackages) != [ ];
      in
      {
        pkgs,
        self',
        system,
        ...
      }:
      let
        inherit ((import ../lib { inherit lib; }).mkLibFlakoboros config)
          buildFlakoborosEnv
          buildFlakoborosRosEnv
          buildFlakoborosDevShell
          buildFlakoborosRosDevShell
          ;
        ctx = {
          inherit
            lib
            cfg
            pkgs
            self'
            allNames
            allPyNames
            allRosNames
            hasRos
            ;
          flakoborosEnv = if hasRos then buildFlakoborosRosEnv else buildFlakoborosEnv;
          flakoborosDevShell = if hasRos then buildFlakoborosRosDevShell else buildFlakoborosDevShell;
        };
      in
      {
        devShells = import ./dev-shells.nix ctx;
        packages = import ./packages.nix ctx;
      }
      // lib.optionalAttrs hasPy { apps = import ./apps.nix ctx; }
      // lib.optionalAttrs cfg.check { checks = import ./checks.nix ctx; }
      // lib.optionalAttrs cfg.pkgs {
        _module.args.pkgs =
          import nixpkgs {
            inherit system;
            config = cfg.nixpkgsConfig;
            overlays = [
              nix-ros-overlay.overlays.default
            ]
            ++ cfg.overlays
            ++ [
              self.overlays.flakoboros
            ];
          }
          // lib.mapAttrs' (
            name: overlay: lib.nameValuePair ("pkgs-" + name) (pkgs.extend overlay)
          ) cfg.extends;
      };
  };
}
