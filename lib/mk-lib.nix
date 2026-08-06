{
  config,
  lib,

  mkQtHelpers,
  ros2qt,
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
      qtHelpers = mkQtHelpers pkgs (ros2qt distro);
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
        ++ lib.optionals cfg.enableQt qtHelpers.env
      );
      preBuild = "export PKG_CONFIG=${lib.getExe pkgs.pkg-config}";
      postBuild = rosWrapperArgs pkgs distro cfg;
    };

  /**
    `buildFlakoborosEnv` plus ros base packages
  */
  buildFlakoborosRosEnv =
    pkgs: distro: packages:
    let
      shell = buildFlakoborosShell pkgs distro packages;
      qtHelpers = mkQtHelpers pkgs (ros2qt distro);
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
        ++ lib.optionals cfg.enableQt qtHelpers.env
      );
      preBuild = "export PKG_CONFIG=${lib.getExe pkgs.pkg-config}";
      postBuild = rosWrapperArgs pkgs distro cfg;
    };

  /**
    `buildFlakoborosRosEnv`, without the packages in `buildFlakoborosShell`, but with their dependencies
  */
  buildFlakoborosRosDevEnv =
    pkgs: distro: packages:
    let
      shell = buildFlakoborosDevShell pkgs distro packages;
      qtHelpers = mkQtHelpers pkgs (ros2qt distro);
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
        ++ lib.optionals cfg.enableQt qtHelpers.env
      );
      preBuild = "export PKG_CONFIG=${lib.getExe pkgs.pkg-config}";
      postBuild = rosWrapperArgs pkgs distro cfg;
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
      shellHook = rosShellHook pkgs distro env cfg;
    };

}
