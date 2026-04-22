# Generating your `packages` and `devShells`

## `devShells`

Flakoboros module will populate the current flake `devShells.default` output with a default `mkShell` whose `inputsFrom` are the `pkgs` (and `pkgs.python3Packages` / `pkgs.rosPackages.${rosShellDistro}` ) attributes listed in [`overlay-flakoboros`](./overlay-flakoboros.md).

Thus, you will get all the dependencies required to build all your packages in a nix shell accessible with `nix develop` (or nix-direnv).

If you have ROS packages, a `ros-${distro}` variant will be created for each ROS distro in the `rosDistros` config option. So `devShells.default == devShells.ros-${rosShellDistro}`.

## `packages`

In the same manner, the current flake `packages.default` output will default to a `buildEnv` (from `nix-ros-overlay`) including everything listed in [`overlay-flakoboros`](./overlay-flakoboros.md).

Those individual packages are also exposed, in a name prefixed by `py-` for python packages and `ros-${distro}` (for each ROS distro in the `rosDistros` config options) for ROS packages.

## Adding packages

The lists of packages in `packages` and `devShells` can be augmented with:
- the `extraPackages` config option (and `extraPyPackages` / `extraRosPackages`),
- the `extraDevPackage` config option (and `extraDevPyPackages` / `extraDevRosPackages`).

In the first case, the nix-built version will be available directly in the `devShells`.
In the second case, `devShells` will only include their dependencies, so that you can build them too.

## Excluding packages

The `filterPackages` config option is for that.
