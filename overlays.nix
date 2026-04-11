{
  config,
  lib,
  ...
}:
let
  cfg = config.flakoboros;
  resolve = ctx: val: if builtins.isFunction val then val ctx else val;
  resolveAttrs =
    ctx: val: drv-final: drv-prev:
    if builtins.isFunction val then val ({ inherit drv-final drv-prev; } // ctx) else val;
in
lib.composeManyExtensions [
  # Packages
  (
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
  )

  # Overrides
  (
    pkgs-final: pkgs-prev:
    let
      ctx = { inherit pkgs-final pkgs-prev; };
    in
    (lib.mapAttrs (name: override: pkgs-prev.${name}.override (resolve ctx override)) cfg.overrides)
    // {
      pythonPackagesExtensions = pkgs-prev.pythonPackagesExtensions ++ [
        (
          python-final: python-prev:
          let
            py-ctx = ctx // {
              inherit python-final python-prev;
            };
          in
          lib.mapAttrs (
            name: override: python-prev.${name}.override (resolve py-ctx override)
          ) cfg.pyOverrides
        )
      ];

      rosPackages =
        pkgs-prev.rosPackages
        // lib.genAttrs cfg.rosDistros (
          distro:
          pkgs-prev.rosPackages.${distro}.overrideScope (
            ros-final: ros-prev:
            let
              ros-ctx = ctx // {
                inherit ros-final ros-prev;
              };
            in
            lib.mapAttrs (name: override: ros-prev.${name}.override (resolve ros-ctx override)) cfg.rosOverrides
          )
        );
    }
  )

  # OverrideAttrs
  (
    pkgs-final: pkgs-prev:
    let
      ctx = { inherit pkgs-final pkgs-prev; };
    in
    (lib.mapAttrs (
      name: override: pkgs-prev.${name}.overrideAttrs (resolveAttrs ctx override)
    ) cfg.overrideAttrs)
    // {
      pythonPackagesExtensions = pkgs-prev.pythonPackagesExtensions ++ [
        (
          python-final: python-prev:
          let
            py-ctx = ctx // {
              inherit python-final python-prev;
            };
          in
          lib.mapAttrs (
            name: override: python-prev.${name}.overrideAttrs (resolveAttrs py-ctx override)
          ) cfg.pyOverrideAttrs
        )
      ];

      rosPackages =
        pkgs-prev.rosPackages
        // lib.genAttrs cfg.rosDistros (
          distro:
          pkgs-prev.rosPackages.${distro}.overrideScope (
            ros-final: ros-prev:
            let
              ros-ctx = ctx // {
                inherit ros-final ros-prev;
              };
            in
            lib.mapAttrs (
              name: override: ros-prev.${name}.overrideAttrs (resolveAttrs ros-ctx override)
            ) cfg.rosOverrideAttrs
          )
        );
    }
  )
]
