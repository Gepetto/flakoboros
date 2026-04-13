{
  lib,
  config,
  ...
}:
let
  cfg = config.flakoboros;
in
pkgs-final: pkgs-prev:
(lib.mapAttrs (_name: package: pkgs-final.callPackage package { }) cfg.packages)
// {
  pythonPackagesExtensions = pkgs-prev.pythonPackagesExtensions ++ [
    (
      python-final: _python-prev:
      lib.mapAttrs (_name: package: python-final.callPackage package { }) cfg.pyPackages
    )
  ];

  rosPackages =
    pkgs-prev.rosPackages
    // lib.genAttrs cfg.rosDistros (
      distro:
      pkgs-prev.rosPackages.${distro}.overrideScope (
        ros-final: _ros-prev:
        lib.mapAttrs (_name: package: ros-final.callPackage package { }) cfg.rosPackages
      )
    );
}
