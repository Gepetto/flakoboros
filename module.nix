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
        pythonModules =
          lib.attrNames (cfg.pyPackages // cfg.pyOverrides // cfg.pyOverrideAttrs) ++ cfg.extraPythonModules;
      in
      {
        pkgs,
        self',
        system,
        ...
      }:
      let
        buildGazebros2nixEnv = self.lib.buildGazebros2nixEnv pkgs;
        buildGazebros2nixRosEnv = self.lib.buildGazebros2nixRosEnv pkgs;
        buildGazebros2nixDevShell = self.lib.buildGazebros2nixDevShell pkgs;
        buildGazebros2nixRosDevShell = self.lib.buildGazebros2nixRosDevShell pkgs;
      in
      {
        devShells = {
          default = lib.mkDefault (
            if (cfg.rosPackages == { } && cfg.rosOverrides == { } && cfg.rosOverrideAttrs == { }) then
              (buildGazebros2nixDevShell cfg.rosShellDistro self'.packages)
            else
              (buildGazebros2nixRosDevShell cfg.rosShellDistro self'.packages)
          );
        }
        //
          lib.optionalAttrs (cfg.rosPackages != { } || cfg.rosOverrides != { } || cfg.rosOverrideAttrs != { })
            (
              lib.genAttrs' cfg.rosDistros (
                distro: lib.nameValuePair "ros-${distro}" (buildGazebros2nixRosDevShell distro self'.packages)
              )
            );

        packages = {
          default = lib.mkDefault (
            if (cfg.rosPackages == { } && cfg.rosOverrides == { } && cfg.rosOverrideAttrs == { }) then
              (buildGazebros2nixEnv cfg.rosShellDistro self'.packages)
            else
              (buildGazebros2nixRosEnv cfg.rosShellDistro self'.packages)
          );
        }
        // (lib.mapAttrs (name: _v: pkgs.${name}) (cfg.packages // cfg.overrides // cfg.overrideAttrs))
        // (lib.mapAttrs' (name: _v: lib.nameValuePair "py-${name}" pkgs.python3Packages.${name}) (
          cfg.pyPackages // cfg.pyOverrides // cfg.pyOverrideAttrs
        ))
        // (lib.listToAttrs (
          lib.mapCartesianProduct
            ({ distro, name }: lib.nameValuePair "ros-${distro}-${name}" pkgs.rosPackages.${distro}.${name})
            {
              distro = cfg.rosDistros;
              name = lib.attrNames (cfg.rosPackages // cfg.rosOverrides // cfg.rosOverrideAttrs);
            }
        ))
        //
          lib.optionalAttrs (cfg.rosPackages != { } || cfg.rosOverrides != { } || cfg.rosOverrideAttrs != { })
            (
              lib.genAttrs' cfg.rosDistros (
                distro: lib.nameValuePair "ros-${distro}" (buildGazebros2nixRosEnv distro self'.packages)
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
          program = pkgs.python3.withPackages (p: lib.attrVals (lib.uniqueStrings pythonModules) p);
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
