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
      overlays.default = import ./overlays.nix { inherit config lib; };
    };

    perSystem =
      let
        allNames = lib.attrNames (cfg.packages // cfg.overrides // cfg.overrideAttrs);
        allPyNames = lib.attrNames (cfg.pyPackages // cfg.pyOverrides // cfg.pyOverrideAttrs);
        allRosNames = lib.attrNames (cfg.rosPackages // cfg.rosOverrides // cfg.rosOverrideAttrs);
        hasRos = allRosNames != [ ];
        pythonModules = allPyNames ++ cfg.extraPythonModules;
      in
      {
        pkgs,
        self',
        system,
        ...
      }:
      let
        buildFlakoborosEnv' = self.lib.buildFlakoborosEnv pkgs;
        buildFlakoborosRosEnv' = self.lib.buildFlakoborosRosEnv pkgs;
        buildFlakoborosDevShell' = self.lib.buildFlakoborosDevShell pkgs;
        buildFlakoborosRosDevShell' = self.lib.buildFlakoborosRosDevShell pkgs;
      in
      {
        devShells = {
          default = lib.mkDefault (
            (if hasRos then buildFlakoborosRosDevShell' else buildFlakoborosDevShell') cfg.rosShellDistro
              self'.packages
          );
        }
        // lib.optionalAttrs hasRos (
          lib.genAttrs' cfg.rosDistros (
            distro: lib.nameValuePair "ros-${distro}" (buildFlakoborosRosDevShell' distro self'.packages)
          )
        );

        packages = {
          default = lib.mkDefault (
            (if hasRos then buildFlakoborosRosEnv' else buildFlakoborosEnv') cfg.rosShellDistro self'.packages
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
            distro: lib.nameValuePair "ros-${distro}" (buildFlakoborosRosEnv' distro self'.packages)
          )
        );
      }

      // lib.optionalAttrs cfg.pkgs {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config = cfg.nixpkgsConfig;
          overlays = [
            nix-ros-overlay.overlays.default
            self.overlays.default
          ]
          ++ cfg.overlays;
        };
      }

      // lib.optionalAttrs (pythonModules != [ ]) {
        apps.default = {
          type = "app";
          program = lib.getExe pkgs.python3.withPackages (
            p: lib.attrVals (lib.uniqueStrings pythonModules) p
          );
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
