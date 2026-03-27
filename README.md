# flakoboros

Circular Packaging framework with nix Flakes, including ROS support

> [!WARNING]
> still early beta: API will change, things will break, and/or are already broken

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

## API overview

```nix
{
outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (
  { lib, ... }:
  {
    systems = import inputs.systems;
    imports = [
      inputs.flakoboros.flakeModule
      {
        flakoboros = {
          overrideAttrs.pinocchio = _final: {
            src = lib.cleanSource ./.;
          };
          pyOverrideAttrs.pinocchio = _final: pyFinal: (super: {
            propagatedBuildInputs = super.propagatedBuildInputs ++ [
              pyFinal.viser
            ];
          });
        };
      }
    ];
  });
  }
```

(the full list is defined in <./options.nix>)

This will:

- define `overlays.default` with those overrides
- (if you don't opt-out) instanciate `pkgs` with that overlay
- inherit those in `packages.${system}.pinocchio` and `packages.${system}.py-pinocchio`
- define `packages.${system}.default` as a `buildEnv` including all others `packages.${system}.*`  (for `nix build` & `nix shell`)
- define `devShells.${system}.default` as a `mkShell` with `inputsFrom` the same `packages.${system}.*` (for `nix develop` / `nix-direnv`)

## ROS

If you have ROS packages, the `default` package and devShell will use a default ROS distribution (eg. `rolling`), but the same features are available for other distros, with eg.

- `nix build .#ros-humble`
- `nix shell .#ros-jazzy`
- `nix develop .#ros-kilted`
- `nix run .#ros-rolling`

Also, standard ROS tools like colcon and ros2cli will be included.

![logo](./logo.svg)
