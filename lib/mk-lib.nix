{
  config,
  lib,

  rosWrapperArgs,
  rosShellHook,
  getRosBasePackages,
  ...
}:
let
  cfg = config.flakoboros;
in
rec {
  /**
    Build a shell with all packages,
    except those excluded
  */
  buildFlakoborosShell =
    pkgs: distro: packages:
    pkgs.mkShell {
      name = "flakoboros default shell";
      preferLocalBuild = false;
      __structuredAttrs = true;
      strictDeps = true;
      packages =
        lib.attrValues (
          lib.filterAttrs (
            n: v:
            (n != "default")
            && (cfg.filterPackages n v)
            && ((!lib.hasPrefix "ros-" n) || lib.hasPrefix "ros-${distro}-" n)
            && (!lib.hasPrefix "pkgs-" n)
          ) packages
        )
        ++ lib.attrVals cfg.extraPackages pkgs
        ++ lib.attrVals cfg.extraPyPackages pkgs.python3Packages
        ++ lib.attrVals cfg.extraRosPackages pkgs.rosPackages.${distro};
    };

  /**
    Build a shell without the packages in `buildFlakoborosShell`, but with their dependencies
  */
  buildFlakoborosDevShell =
    pkgs: distro: packages:
    pkgs.mkShell {
      name = "flakoboros default devShell";
      preferLocalBuild = false;
      __structuredAttrs = true;
      strictDeps = true;
      inputsFrom =
        lib.attrValues (
          lib.filterAttrs (
            n: v:
            (n != "default")
            && (cfg.filterPackages n v)
            && ((!lib.hasPrefix "ros-" n) || lib.hasPrefix "ros-${distro}-" n)
            && (!lib.hasPrefix "pkgs-" n)
          ) packages
        )
        ++ lib.attrVals cfg.extraDevPackages pkgs
        ++ lib.attrVals cfg.extraDevPyPackages pkgs.python3Packages
        ++ lib.attrVals cfg.extraDevRosPackages pkgs.rosPackages.${distro};
      packages =
        lib.attrVals cfg.extraPackages pkgs
        ++ lib.attrVals cfg.extraPyPackages pkgs.python3Packages
        ++ lib.attrVals cfg.extraRosPackages pkgs.rosPackages.${distro};
    };

  /**
    Build an env with all packages from `buildFlakoborosShell`,
    plus extra Qt 5 or 6 things
  */
  buildFlakoborosEnv =
    pkgs: distro: packages:
    let
      shell = buildFlakoborosShell pkgs distro packages;
    in
    pkgs.rosPackages.${distro}.buildEnv {
      extraOutputsToInstall = [ "out" ];
      paths = lib.unique (
        lib.filter lib.isDerivation (
          (shell.buildInputs or [ ])
          ++ (shell.nativeBuildInputs or [ ])
          ++ (shell.propagatedNativeBuildInputs or [ ])
          ++ (shell.propagatedBuildInputs or [ ])
        )
        ++ lib.attrVals cfg.extraPackages pkgs
        ++ lib.attrVals cfg.extraPyPackages pkgs.python3Packages
        ++ lib.attrVals cfg.extraRosPackages pkgs.rosPackages.${distro}
        ++ lib.optionals (distro == "humble" || distro == "jazzy" || distro == "kilted") [
          pkgs.python3Packages.coal # TODO
          pkgs.qt5.wrapQtAppsHook
          pkgs.qt5.qtgraphicaleffects
        ]
        ++ lib.optionals (distro == "rolling") [
          pkgs.qt6.qtbase
          pkgs.qt6.wrapQtAppsHook
        ]
      );
      postBuild = rosWrapperArgs pkgs distro;
    };

  /**
    `buildFlakoborosEnv` plus ros base packages
  */
  buildFlakoborosRosEnv =
    pkgs: distro: packages:
    let
      shell = buildFlakoborosShell pkgs distro packages;
    in
    pkgs.rosPackages.${distro}.buildEnv {
      extraOutputsToInstall = [ "out" ];
      paths = lib.unique (
        lib.filter lib.isDerivation (
          (shell.buildInputs or [ ])
          ++ (shell.nativeBuildInputs or [ ])
          ++ (shell.propagatedNativeBuildInputs or [ ])
          ++ (shell.propagatedBuildInputs or [ ])
        )
        ++ lib.attrVals cfg.extraPackages pkgs
        ++ lib.attrVals cfg.extraPyPackages pkgs.python3Packages
        ++ lib.attrVals cfg.extraRosPackages pkgs.rosPackages.${distro}
        ++ getRosBasePackages pkgs distro
        ++ lib.optionals (distro == "humble" || distro == "jazzy" || distro == "kilted") [
          pkgs.python3Packages.coal # TODO
          pkgs.qt5.wrapQtAppsHook
          pkgs.qt5.qtgraphicaleffects
        ]
        ++ lib.optionals (distro == "rolling") [
          pkgs.qt6.wrapQtAppsHook
          pkgs.qt6.qtbase
        ]
      );
      postBuild = rosWrapperArgs pkgs distro;
    };

  /**
    `buildFlakoborosRosEnv`, without the packages in `buildFlakoborosShell`, but with their dependencies
  */
  buildFlakoborosRosDevEnv =
    pkgs: distro: packages:
    let
      shell = buildFlakoborosDevShell pkgs distro packages;
    in
    pkgs.rosPackages.${distro}.buildEnv {
      extraOutputsToInstall = [ "out" ];
      paths = lib.unique (
        lib.filter lib.isDerivation (
          (shell.buildInputs or [ ])
          ++ (shell.nativeBuildInputs or [ ])
          ++ (shell.propagatedNativeBuildInputs or [ ])
          ++ (shell.propagatedBuildInputs or [ ])
        )
        ++ lib.attrVals cfg.extraPackages pkgs
        ++ lib.attrVals cfg.extraPyPackages pkgs.python3Packages
        ++ lib.attrVals cfg.extraRosPackages pkgs.rosPackages.${distro}
        ++ getRosBasePackages pkgs distro
        ++ lib.optionals (distro == "humble" || distro == "jazzy" || distro == "kilted") [
          pkgs.python3Packages.coal # TODO
          pkgs.qt5.wrapQtAppsHook
          pkgs.qt5.qtgraphicaleffects
        ]
        ++ lib.optionals (distro == "rolling") [
          pkgs.qt6.wrapQtAppsHook
          pkgs.qt6.qtbase
        ]
      );
      postBuild = rosWrapperArgs pkgs distro;
    };

  /**
    `buildFlakoborosDevShell` plus ros base packages

    technically, we use `buildFlakoborosRosDevEnv` to set some ros path variables.
  */
  buildFlakoborosRosDevShell =
    pkgs: distro: packages:
    let
      shell = buildFlakoborosDevShell pkgs distro packages;
      env = buildFlakoborosRosDevEnv pkgs distro packages;
    in
    pkgs.mkShell {
      name = "flakoboros default ROS devShell";
      preferLocalBuild = false;
      __structuredAttrs = true;
      strictDeps = true;
      inputsFrom = [ shell ];
      packages =
        getRosBasePackages pkgs distro
        ++ lib.attrVals cfg.extraPackages pkgs
        ++ lib.attrVals cfg.extraPyPackages pkgs.python3Packages
        ++ lib.attrVals cfg.extraRosPackages pkgs.rosPackages.${distro};
      shellHook = rosShellHook pkgs distro env;
    };

}
