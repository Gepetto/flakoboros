# flakoboros

<img src="./docs/logo.svg" alt="flakoboros logo: the 6 lambda from nix flake, but rotated as if they are eating each other as a ouroboros">

Circular Packaging framework with nix Flakes, including ROS support

# Goal

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

To do so, the main API is designed around the idea that your packages are distributed in another more-or-less central Nix repository (eg. nixpkgs or nix-ros-overlay),
and you just need `my-package.overrideAttrs { src = lib.cleanSource ./. }` in the flake of the source.

## Circular Packaging ?

That notion of re-using an existing distribution of a package inside its source.

<!-- More details in [rationale.md](./docs/rationale.md) -->

## API overview

example for [eigenpy](https://github.com/stack-of-tasks/eigenpy):

```nix
{
  description = "Bindings between Numpy and Eigen using Boost.Python";

  inputs.flakoboros.url = "github:gepetto/flakoboros";

  outputs =
    inputs:
    inputs.flakoboros.lib.mkFlakoboros inputs (
      { lib, ... }:
      {
        pyOverrideAttrs.eigenpy = {
          src = lib.cleanSource ./.;
        };
      }
    );
}
```

<details>
<summary>If you need access to more data, a callable form is also available (clic here to reveal)</summary>

```nix
{
  pyOverrideAttrs.example-robot-data =
    { pkgs-final, pkgs-prev, drv-final, drv-prev, py-final, py-prev, ... }:
    {
      src = lib.cleanSource ./.;
      cmakeFlags = [ (lib.cmakeBool "BUILD_TESTING" drv-final.doCheck) ];
      nativeBuildInputs = drv-prev.nativeBuildinputs ++ [ pkgs-final.ninja ];
      dependencies = drv-prev.dependencies ++ [ py-final.rerun-sdk ];
    };
}
```
</details>

<details>
<summary>Behind the scene, this is a shallow wrapper around `flake-parts.lib.mkFlake`, which can be used directly (clic here to reveal)</summary>

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
            flakoboros = {
              pyOverrideAttrs.eigenpy = {
                src = lib.cleanSource ./.;
              };
            };
          }
        ];
      }
    );
}
```
</details>

<!-- (the full list is defined in [options.nix](./options.nix)) -->

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
{
  extends.eigen5 = final: { eigen = final.eigen_5; };
  pyOverrideAttrs.eigenpy = {
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
