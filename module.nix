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
  options.flakoboros = import ./options.nix { inherit lib; };

  config = {
    flake = {
      lib = import ./lib.nix { inherit config lib; };
      overlays.flakoboros = import ./overlays.nix { inherit config lib; };
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
      {
        devShells = {
          default = lib.mkDefault (
            (if hasRos then self.lib.buildFlakoborosRosDevShell else self.lib.buildFlakoborosDevShell) pkgs
              cfg.rosShellDistro
              self'.packages
          );
        }
        // lib.optionalAttrs hasRos (
          lib.genAttrs' cfg.rosDistros (
            distro:
            lib.nameValuePair "ros-${distro}" (self.lib.buildFlakoborosRosDevShell pkgs distro self'.packages)
          )
        )
        // lib.mapAttrs (
          name: _:
          (if hasRos then self.lib.buildFlakoborosRosDevShell else self.lib.buildFlakoborosDevShell)
            pkgs."pkgs-${name}"
            cfg.rosShellDistro
            self'.packages."pkgs-${name}"
        ) cfg.extends;

        packages =
          let
            genPackages =
              pkgs:
              {
                default = lib.mkDefault (
                  (if hasRos then self.lib.buildFlakoborosRosEnv else self.lib.buildFlakoborosEnv) pkgs
                    cfg.rosShellDistro
                    self'.packages
                );
              }
              // lib.getAttrs allNames pkgs
              // lib.genAttrs' allPyNames (name: lib.nameValuePair "py-${name}" pkgs.python3Packages.${name})
              // (lib.listToAttrs (
                lib.mapCartesianProduct
                  ({ distro, name }: lib.nameValuePair "ros-${distro}-${name}" pkgs.rosPackages.${distro}.${name})
                  {
                    distro = cfg.rosDistros;
                    name = allRosNames;
                  }
              ))
              // lib.optionalAttrs hasRos (
                lib.genAttrs' cfg.rosDistros (
                  distro:
                  lib.nameValuePair "ros-${distro}" (self.lib.buildFlakoborosRosEnv pkgs distro self'.packages)
                )
              );
          in
          genPackages pkgs
          // lib.genAttrs' (lib.attrNames cfg.extends) (
            name: lib.nameValuePair ("pkgs-" + name) (genPackages pkgs."pkgs-${name}")
          );
      }

      // lib.optionalAttrs cfg.pkgs {
        _module.args.pkgs =
          let
            base = import nixpkgs {
              inherit system;
              config = cfg.nixpkgsConfig;
              overlays = [
                nix-ros-overlay.overlays.default
                self.overlays.flakoboros
              ]
              ++ cfg.overlays;
            };
          in
          base
          // lib.mapAttrs' (
            name: overlay: lib.nameValuePair ("pkgs-" + name) (base.extend overlay)
          ) cfg.extends;
      }

      // lib.optionalAttrs hasPy {
        apps.default = {
          type = "app";
          program = lib.getExe (pkgs.python3.withPackages (p: lib.attrVals allPyNames p));
        };
      }

      // lib.optionalAttrs cfg.check {
        # Build all available packages and devShells. Useful for CI.
        checks =
          let
            devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") self'.devShells;
            packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") self'.packages;
          in
          lib.filterAttrs (_n: v: v.meta.available && !v.meta.broken) (devShells // packages);
      };
  };
}
