<img align="right" src="logo.svg" alt="logo">

Circular Packaging framework with nix Flakes, including ROS support

> [!WARNING]
> still early beta: API will change, things will break, and/or are already broken

# flakoboros

## Goal

When one package is defined in a flake, we can by default:

- `nix build`: build the package (and run its tests)
- `nix shell`: open a shell with the package ready to be used
- `nix develop`: open a shell without the built package, but with everything required to build it
- `nix run`: execute the main program from the package

Flakoboros allows to provide the same experience with multiple packages in a flake:

- `nix build`: build all packages (and run their tests)
- `nix shell`: open a shell with all packages ready to be used
- `nix develop`: open a shell without any of the packages, but with everything required to build them all
- `nix run`: execute the main program from all the packages (eg. a python interpreter with all the python modules available)

To do so, the main API is designed around the idea that your packages are distributed in another more-or-less central repository (eg. nixpkgs or nix-ros-overlay),
and you just need `my-package.overrideAttrs { src = lib.cleanSource ./. }` in the flake of the source.

## Circular Packaging ?

That notion of re-using an existing distribution of a package inside its source.

More details in [rationale.md](./rationale.md)

## API overview

example for eigenpy:

```nix
{
  description = "Bindings between Numpy and Eigen using Boost.Python";

  inputs = {
    flakoboros.url = "github:gepetto/flakoboros";
    flake-parts.follows = "flakoboros/flake-parts";
    systems.follows = "flakoboros/systems";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        systems = import inputs.systems;
        imports = [
          inputs.flakoboros.flakeModule
          {
            flakoboros.pyOverrideAttrs.eigenpy = _: _: {
              src = lib.cleanSource ./.;
            };
          }
        ];
      }
    );
}
```

(the full list is defined in [options.nix](./options.nix))

This will:

- define `overlays.flakoboros` with this override
- (if you don't opt-out) instanciate `pkgs` with that overlay
- inherit this in `packages.${system}.py-eigenpy`
- define `packages.${system}.default` as a `buildEnv` including all others `packages.${system}.*`  (for `nix build` & `nix shell`)
- define `devShells.${system}.default` as a `mkShell` with `inputsFrom` the same `packages.${system}.*` (for `nix develop` / `nix-direnv`)

## ROS

If you have ROS packages, the `default` package and devShell will use a default ROS distribution (eg. `rolling`), but the same features are available for other distros, with eg.

- `nix build .#ros-humble`
- `nix shell .#ros-jazzy`
- `nix develop .#ros-kilted`
- `nix run .#ros-rolling`

Also, standard ROS tools like colcon and ros2cli will be included.

## Extend `pkgs`, aka alternate universes

```nix
flakoboros = {
  extends.eigen5 = final: _prev: { eigen = final.eigen_5; };
  pyOverrideAttrs.eigenpy = _final: _python-final: {
    src = lib.cleanSource ./.;
  };
};
```

This will:

- define `pkgs`, `packages.${system}.py-eigenpy` and `packages.${system}.default` as before
- define `pkgs.pkgs-eigen5` as another `pkgs` instance but where `eigen` is overriden everywhere by `eigen_5`
- define `packages.${system}.pkgs-eigen5`, equivalent to `packages.${system}.default` but with eigen 5
- add scoped everything else, eg. `packages.${system}.pkgs-eigen5.py-eigenpy` (technically `packages.${system}.pkgs-eigen5.passthru.py-eigenpy`)
- define `devShells.${system}.pkgs-eigen5`

So in your CI, you can build `.` and `.#pkgs-eigen5` to check all your stack with both eigen 3.4.1 and 5.0.1.

Also, you can either `echo 'use flake .' > .envrc` or `echo 'use flake .#pkgs-eigen5' > .envrc`, and follow your usual `cmake -B build && cmake --build build` workflow.
