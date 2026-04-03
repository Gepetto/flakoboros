{
  config,
  lib,
}:
let
  cfg = config.flakoboros;
  distro = cfg.rosShellDistro;
in
rec {
  rosWrapperArgs =
    pkgs: distro:
    ''
      rosWrapperArgs+=(
      --unset QTWEBKIT_PLUGIN_PATH
      --unset QT_QPA_PLATFORMTHEME
      --unset QT_STYLE_OVERRIDE
      --prefix AMENT_PREFIX_PATH : $out
      --prefix LD_LIBRARY_PATH : $out/lib
      --prefix PYTHONPATH : $out/lib/python3.13/site-packages:$out/lib/python3.14/site-packages
    ''
    + lib.optionalString (distro == "humble") ''
      --set-default IGN_IP 127.0.0.1
      --prefix IGN_CONFIG_PATH : $out/share/ignition
      --prefix IGN_GAZEBO_RESOURCE_PATH : $out/share
    ''
    + lib.optionalString (distro == "humble" || distro == "jazzy" || distro == "kilted") ''
      --set QML2_IMPORT_PATH ${
        lib.makeSearchPathOutput "bin" pkgs.qt5.qtbase.qtQmlPrefix [
          pkgs.qt5.qtbase
          pkgs.qt5.qtdeclarative
          pkgs.qt5.qtquickcontrols
          pkgs.qt5.qtquickcontrols2
          pkgs.qt5.qtgraphicaleffects
          pkgs.qt5.qtwayland
          pkgs.qt5.qtwebsockets
        ]
      }
      --set QT_QPA_PLATFORM_PLUGIN_PATH ${
        lib.makeSearchPathOutput "bin" "${pkgs.qt5.qtbase.qtPluginPrefix}/platforms" [
          pkgs.qt5.qtbase
          pkgs.qt5.qtwayland
        ]
      }
    ''
    + lib.optionalString (distro != "humble") ''
      --set-default GZ_IP 127.0.0.1
      --prefix GZ_SIM_RESOURCE_PATH : $out/share
    ''
    + ''
      )
    '';

  rosShellHook =
    pkgs: env:
    ''
      unset QTWEBKIT_PLUGIN_PATH
      unset QT_QPA_PLATFORMTHEME
      unset QT_STYLE_OVERRIDE
    ''
    + lib.optionalString (env != null) ''
      AMENT_PREFIX_PATH=${env}:''${AMENT_PREFIX_PATH:+:$AMENT_PREFIX_PATH}
      LD_LIBRARY_PATH=${env}/lib:''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
      export AMENT_PREFIX_PATH
      export LD_LIBRARY_PATH
    ''
    + lib.optionalString (distro == "humble") ''
      : ''${IGN_IP:=127.0.0.1}
      export IGN_IP
    ''
    + lib.optionalString (env != null && distro == "humble") ''
      IGN_CONFIG_PATH=${env}/share/ignition:''${IGN_CONFIG_PATH:+:$IGN_CONFIG_PATH}
      IGN_GAZEBO_RESOURCE_PATH=${env}/share:''${IGN_GAZEBO_RESOURCE_PATH:+:$IGN_GAZEBO_RESOURCE_PATH}
      export IGN_CONFIG_PATH
      export IGN_GAZEBO_RESOURCE_PATH
    ''
    +
      lib.optionalString (pkgs != null && (distro == "humble" || distro == "jazzy" || distro == "kilted"))
        ''
          QML2_IMPORT_PATH=${
            lib.makeSearchPathOutput "bin" pkgs.qt5.qtbase.qtQmlPrefix [
              pkgs.qt5.qtbase
              pkgs.qt5.qtdeclarative
              pkgs.qt5.qtquickcontrols
              pkgs.qt5.qtquickcontrols2
              pkgs.qt5.qtgraphicaleffects
              pkgs.qt5.qtwayland
              pkgs.qt5.qtwebsockets
            ]
          }
          QT_PLUGIN_PATH=${
            lib.makeSearchPathOutput "bin" pkgs.qt5.qtbase.qtPluginPrefix [
              pkgs.qt5.qtbase
              pkgs.qt5.qtdeclarative
              pkgs.qt5.qtwayland
            ]
          }
          QT_QPA_PLATFORM_PLUGIN_PATH=${
            lib.makeSearchPathOutput "bin" "${pkgs.qt5.qtbase.qtPluginPrefix}/platforms" [
              pkgs.qt5.qtbase
              pkgs.qt5.qtwayland
            ]
          }
          export QML2_IMPORT_PATH
          export QT_PLUGIN_PATH
          export QT_QPA_PLATFORM_PLUGIN_PATH
        ''
    + lib.optionalString (distro != "humble") ''
      : ''${GZ_IP:=127.0.0.1}
      export GZ_IP
    ''
    + lib.optionalString (env != null && distro != "humble") ''
      GZ_SIM_RESOURCE_PATH=${env}/share:''${GZ_SIM_RESOURCE_PATH:+:$GZ_SIM_RESOURCE_PATH}
      export GZ_SIM_RESOURCE_PATH
    ''
    + ''
      test -f install/local_setup.bash && source install/local_setup.bash
    '';

  getRosBasePackages = pkgs: distro: [
    pkgs.colcon
    pkgs.rosPackages.${distro}.ros2action
    pkgs.rosPackages.${distro}.ros2launch
    pkgs.rosPackages.${distro}.ros2run
    pkgs.rosPackages.${distro}.ros2topic
  ];

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
      shellHook = rosShellHook pkgs env;
    };

  /**
    Extract version from a structured file
  */
  loadVersion =
    bin: path: pkgs: file:
    pkgs.lib.trim (
      builtins.readFile (
        pkgs.runCommandLocal "version" {
          nativeBuildInputs = [ pkgs.yq ];
        } "${bin} -r ${path} ${file} > $out"
      )
    );

  /**
    Extract version from a ROS package.xml file
  */
  rosVersion = loadVersion "xq" ".package.version";

  /**
    Extract version from a python pyproject.toml file
  */
  pythonVersion = loadVersion "tomlq" ".project.version";
}
