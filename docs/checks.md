# Building everything in `checks`

Most of the time, running `nix build` will build the `packages.default` env including all the packages you care about, so this should be enough.

But if you add manually other things to `packages` and/or `devShells`, you may want a shortcut to build everything.

The `check` config option is for that, as it will expose everything in the current flake `checks` output, so that you can simply `nix flake check`.
