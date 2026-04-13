{
  lib,
  cfg,
  pkgs,
  self',

  hasRos,
  flakoborosDevShell,
  ...
}:
{
  default = lib.mkDefault (flakoborosDevShell pkgs cfg.rosShellDistro self'.packages);
}
// lib.optionalAttrs hasRos (
  lib.genAttrs' cfg.rosDistros (
    distro: lib.nameValuePair "ros-${distro}" (flakoborosDevShell pkgs distro self'.packages)
  )
)
// lib.mapAttrs' (
  name: _:
  lib.nameValuePair ("pkgs-" + name) (
    flakoborosDevShell pkgs."pkgs-${name}" cfg.rosShellDistro self'.packages."pkgs-${name}".passthru
  )
) cfg.extends
