{
  lib,
  config,
  ...
}:
let
  cfg = config.flakoboros;
  resolve = ctx: val: if builtins.isFunction val then val ctx else val;
in
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
