{
  lib,
  ...
}:
rec {
  /**
    mapping of recommended Gazebo distro per ROS distro
  */
  ros2gz =
    distro:
    if distro == "humble" then
      "fortress"
    else if distro == "jazzy" then
      "harmonic"
    else if distro == "kilted" then
      "ionic"
    else if distro == "rolling" then
      "jetty"
    else
      throw "wrong ros distro";

  /**
    set many env vars in a makeWrapperArgs format for postBuild
  */
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
      --set-default IGNITION_VERSION ${ros2gz distro}
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
      --set-default GAZEBO_VERSION ${ros2gz distro}
      --prefix GZ_SIM_RESOURCE_PATH : $out/share
    ''
    + ''
      )
    '';

  /**
    set many env vars in a bash format for pkgs.mkShell { shellHook = … }
  */
  rosShellHook =
    pkgs: distro: env:
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
      : ''${IGNITION_VERSION:=${ros2gz distro}}
      export IGN_IP
      export IGNITION_VERSION
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
      : ''${GAZEBO_VERSION:=${ros2gz distro}}
      export GZ_IP
      export GAZEBO_VERSION
    ''
    + lib.optionalString (env != null && distro != "humble") ''
      GZ_CONFIG_PATH=${env}/share/gz:''${GZ_CONFIG_PATH:+:$GZ_CONFIG_PATH}
      GZ_SIM_RESOURCE_PATH=${env}/share:''${GZ_SIM_RESOURCE_PATH:+:$GZ_SIM_RESOURCE_PATH}
      export GZ_CONFIG_PATH
      export GZ_SIM_RESOURCE_PATH
    ''
    + ''
      test -f install/local_setup.bash && source install/local_setup.bash
    '';

  /**
    get a list of common ros packages.

    Don't hesitate to contact us to extend this list !
  */
  getRosBasePackages = pkgs: distro: [
    pkgs.colcon
    pkgs.rosPackages.${distro}.ros2action
    pkgs.rosPackages.${distro}.ros2launch
    pkgs.rosPackages.${distro}.ros2run
    pkgs.rosPackages.${distro}.ros2topic
  ];

  /**
    Generate libFlakoboros
  */
  mkLibFlakoboros =
    config:
    import ./mk-lib.nix {
      inherit
        config
        lib
        rosWrapperArgs
        rosShellHook
        getRosBasePackages
        ;
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
