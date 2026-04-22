# API overview

## `flake-parts` and `mkFlake`

Flakoboros is a [`flake-parts`](https://flake.parts/) module.
Its main entrypoint is a `flakoboros` config attrset which can be used in your `flake.nix` as:

```nix
{
  description = "The description of your project";

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
              # Every config option goes here
            };
          }
        ];
      }
    );
}
```

## `mkFlakoboros` shortcut

To reduce the boilerplate, if you don't need anything else from `flake-parts`, you can use this shortcut:

```nix
{
  description = "The description of your project";

  inputs.flakoboros.url = "github:gepetto/flakoboros";

  outputs =
    inputs:
    inputs.flakoboros-parts.lib.mkFlakoboros inputs (
      { lib, ... }:
      {
        # Every config option goes here
      }
    );
}
```
