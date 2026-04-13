{
  lib,
  cfg,
  pkgs,
  self',

  allNames,
  allPyNames,
  allRosNames,
  hasRos,
  flakoborosEnv,
  ...
}:
let
  genPackages =
    pkgs:
    lib.getAttrs allNames pkgs
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
        distro: lib.nameValuePair "ros-${distro}" (flakoborosEnv pkgs distro self'.packages)
      )
    );
in
{
  default = lib.mkDefault (flakoborosEnv pkgs cfg.rosShellDistro self'.packages);
}
// genPackages pkgs
// lib.genAttrs' (lib.attrNames cfg.extends) (
  name:
  lib.nameValuePair ("pkgs-" + name) (
    let
      packages = genPackages pkgs."pkgs-${name}";
      default = flakoborosEnv pkgs."pkgs-${name}" cfg.rosShellDistro packages;
    in
    default.overrideAttrs { passthru = packages; }
  )
)
