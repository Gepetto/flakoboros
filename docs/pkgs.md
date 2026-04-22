# Defining `pkgs`

## Default `pkgs` instance

By default, a `pkgs` instance (provided as input of `perSystem`) will be defined from flakoboros `nixpkgs` input, plus several overlays:

- flakoboros `inputs.nix-ros-overlay.overlays.default`
- the `overlays` config option
- the current flake `overlays.flakoboros`, which is built as described in  [Controlling `overlay-flakoboros`](./overlay-flakoboros.md)

You can control its configuration via `nixpkgsConfig` option.

## Opt-out

If you don't want this instance, you can set the `pkgs` config option to `false`.

## Extends

The `extends` config option provide other `pkgs` instances (also available as input of `perSystem`).

In that config option, for each key `name`, a `pkgs-${name}` is defined as the `pkgs` instance from above plus the overlay provided as value.

This overlay is also exposed in the current flake `overlays`, for reference from other flakes.

Then, the current flake `packages` output gets a new `pkgs-${name}` env, similar to the `default` one, but from that `pkgs` instance. All other `packages` are also exposed as `passthru` of that `pkgs-${name}` env.

And finally, the current flake `devShells` also get a `pkgs-${name}` version of its `default`.

For example:

```nix
{
  pyOverrideAttrs.eigenpy = {
    src = lib.cleanSource ./.;
  };
  extends.eigen5 = final: _prev: {
    eigen = final.eigen_5;
  };
}
```

will define:
```
$ nix flake show

├───devShells
│   └───x86_64-linux
│       ├───default: development environment 'flakoboros-default-devShell'
│       └───pkgs-eigen5: development environment 'flakoboros-default-devShell'
├───overlays
│   ├───eigen5: Nixpkgs overlay
│   └───flakoboros: Nixpkgs overlay
└───packages
    └───x86_64-linux
        ├───default: package 'ros-env'
        ├───pkgs-eigen5: package 'ros-env'
        └───py-eigenpy: package 'python3.13-eigenpy-3.12.0'
```


So you can `nix develop` (or nix-direnv):
- `.` to get all dependencies to build the package with eigen 3
- `.#pkgs-eigen5` to get all dependencies to build the package with eigen 5

And you can `nix build`:
- `.#py-eigenpy`: the package (built with eigen 3)
- `.#pkgs-eigen5.py-eigenpy`: the package (built with eigen 5)
- `.`: an env with the package (built with eigen 3)
- `.#pkgs-eigen5`: an env with the package (built with eigen 5)

With that, you can check everything in CI with eg.:
```yml
jobs:
  build:
    runs-on: "${{ matrix.os }}"
    strategy:
      matrix:
        os: ["ubuntu-24.04", "ubuntu-24.04-arm", "macos-26-intel", "macos-26"]
        extends: ["", "pkgs-eigen5"]
    steps:
      - uses: actions/checkout@v6
      # install nix
      - run: nix build -L ".#${{ matrix.extends }}"
```
