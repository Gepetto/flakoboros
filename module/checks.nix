# Build all available packages and devShells. Useful for CI.
{
  lib,
  self',
  ...
}:
let
  devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") self'.devShells;
  packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") self'.packages;
in
lib.filterAttrs (_n: v: v.meta.available && !v.meta.broken) (devShells // packages)
