# generated lib {#sec-functions-library-}


## `libFlakoboros.buildFlakoborosShell` {#function-library-libFlakoboros.buildFlakoborosShell}

Build a shell with all packages,
except those excluded

## `libFlakoboros.buildFlakoborosDevShell` {#function-library-libFlakoboros.buildFlakoborosDevShell}

Build a shell without the packages in `buildFlakoborosShell`, but with their dependencies

## `libFlakoboros.buildFlakoborosEnv` {#function-library-libFlakoboros.buildFlakoborosEnv}

Build an env with all packages from `buildFlakoborosShell`,
plus extra Qt 5 or 6 things

## `libFlakoboros.buildFlakoborosRosEnv` {#function-library-libFlakoboros.buildFlakoborosRosEnv}

`buildFlakoborosEnv` plus ros base packages

## `libFlakoboros.buildFlakoborosRosDevEnv` {#function-library-libFlakoboros.buildFlakoborosRosDevEnv}

`buildFlakoborosRosEnv`, without the packages in `buildFlakoborosShell`, but with their dependencies

## `libFlakoboros.buildFlakoborosRosDevShell` {#function-library-libFlakoboros.buildFlakoborosRosDevShell}

`buildFlakoborosDevShell` plus ros base packages

technically, we use `buildFlakoborosRosDevEnv` to set some ros path variables.
