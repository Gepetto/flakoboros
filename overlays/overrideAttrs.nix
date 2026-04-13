{
  lib,
  config,
  ...
}:
let
  cfg = config.flakoboros;
  resolveAttrs =
    ctx: val: drv-final: drv-prev:
    if builtins.isFunction val then val ({ inherit drv-final drv-prev; } // ctx) else val;
in
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
