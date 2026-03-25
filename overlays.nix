{
  config,
  lib,
  ...
}:
let
  cfg = config.flakoboros;
in
lib.composeManyExtensions [
  # Packages
  (
    final: prev:
    (lib.mapAttrs (_name: package: final.callPackage package { }) cfg.packages)
    // {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (
          python-final: _python-prev:
          lib.mapAttrs (_name: package: python-final.callPackage package { }) cfg.pyPackages
        )
      ];

      rosPackages =
        prev.rosPackages
        // lib.genAttrs cfg.rosDistros (
          distro:
          prev.rosPackages.${distro}.overrideScope (
            ros-final: _ros-prev:
            lib.mapAttrs (_name: package: ros-final.callPackage package { }) cfg.rosPackages
          )
        );
    }
  )

  # Overrides
  (
    final: prev:
    (lib.mapAttrs (name: override: prev.${name}.override (override final)) cfg.overrides)
    // {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (
          python-final: python-prev:
          lib.mapAttrs (
            name: override: python-prev.${name}.override (override final python-final)
          ) cfg.pyOverrides
        )
      ];

      rosPackages =
        prev.rosPackages
        // lib.genAttrs cfg.rosDistros (
          distro:
          prev.rosPackages.${distro}.overrideScope (
            ros-final: ros-prev:
            lib.mapAttrs (name: override: ros-prev.${name}.override (override final ros-final)) cfg.rosOverrides
          )
        );
    }
  )

  # OverrideAttrs
  (
    final: prev:
    (lib.mapAttrs (name: override: prev.${name}.overrideAttrs (override final)) cfg.overrideAttrs)
    // {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (
          python-final: python-prev:
          lib.mapAttrs (
            name: override: python-prev.${name}.overrideAttrs (override final python-final)
          ) cfg.pyOverrideAttrs
        )
      ];

      rosPackages =
        prev.rosPackages
        // lib.genAttrs cfg.rosDistros (
          distro:
          prev.rosPackages.${distro}.overrideScope (
            ros-final: ros-prev:
            lib.mapAttrs (
              name: override: ros-prev.${name}.overrideAttrs (override final ros-final)
            ) cfg.rosOverrideAttrs
          )
        );
    }
  )
]
