{
  lib,
  config,
  ...
}:
lib.composeManyExtensions [
  (import ./packages.nix { inherit lib config; })
  (import ./overrides.nix { inherit lib config; })
  (import ./overrideAttrs.nix { inherit lib config; })
]
