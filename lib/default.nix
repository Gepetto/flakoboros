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
    if distro == "alum" then
      "harmonic"
    else if distro == "humble" then
      "fortress"
    else if distro == "jazzy" then
      "harmonic"
    else if distro == "kilted" then
      "ionic"
    else if distro == "lyrical" then
      "jetty"
    else if distro == "rolling" then
      "rotary"
    else
      throw "wrong ros distro";

  /**
    mapping of recommended Qt per ROS distro
  */
  ros2qt =
    distro:
    if (distro == "alum" || distro == "humble" || distro == "jazzy" || distro == "kilted") then
      "5"
    else
      "6";

  /**
    Qt helpers
  */
  mkQtHelpers =
    pkgs: qtVersion:
    let
      qt = if (qtVersion == "5") then pkgs.qt5 else pkgs.qt6;
    in
    {
      env = [
        qt.qtbase
        qt.wrapQtAppsHook
      ]
      ++ lib.optionals (qtVersion == "5") [
        qt.qtgraphicaleffects
      ];
    }
    // lib.optionalAttrs (qtVersion == "5") {
      QML2_IMPORT_PATH = lib.makeSearchPathOutput "bin" qt.qtbase.qtQmlPrefix (
        [
          qt.qtbase
          qt.qtdeclarative
          qt.qtquickcontrols
          qt.qtquickcontrols2
          qt.qtgraphicaleffects
          qt.qtwebsockets
        ]
        ++ lib.optional pkgs.stdenv.hostPlatform.isLinux qt.qtwayland
      );
      QT_PLUGIN_PATH = lib.makeSearchPathOutput "bin" qt.qtbase.qtPluginPrefix (
        [
          qt.qtbase
          qt.qtdeclarative
        ]
        ++ lib.optional pkgs.stdenv.hostPlatform.isLinux qt.qtwayland
      );
      QT_QPA_PLATFORM_PLUGIN_PATH =
        lib.makeSearchPathOutput "bin" "${qt.qtbase.qtPluginPrefix}/platforms"
          (
            [
              qt.qtbase
            ]
            ++ lib.optional pkgs.stdenv.hostPlatform.isLinux qt.qtwayland
          );
    };

  /**
    set many env vars in a makeWrapperArgs format for postBuild
  */
  rosWrapperArgs =
    pkgs: distro:
    {
      enableQt ? true,
      ...
    }:
    let
      qtVersion = ros2qt distro;
      qtHelpers = mkQtHelpers pkgs qtVersion;
    in
    ''
      rosWrapperArgs+=(
      --unset QT_PLUGIN_PATH
      --unset QTWEBKIT_PLUGIN_PATH
      --unset QT_QPA_PLATFORMTHEME
      --unset QT_STYLE_OVERRIDE
      --prefix AMENT_PREFIX_PATH : $out
      --prefix LD_LIBRARY_PATH : $out/lib
      --prefix PYTHONPATH : $out/lib/python3.13/site-packages:$out/lib/python3.14/site-packages
    ''
    + lib.optionalString (distro == "humble") ''
      --set-default IGN_IP 127.0.0.1
      --set-default IGN_VERSION ${ros2gz distro}
      --set-default IGNITION_VERSION ${ros2gz distro}
      --prefix IGN_CONFIG_PATH : $out/share/ignition
      --prefix IGN_GAZEBO_RESOURCE_PATH : $out/share
    ''
    + lib.optionalString (enableQt && qtVersion == "5") ''
      --set QML2_IMPORT_PATH ${qtHelpers.QML2_IMPORT_PATH}
      --set QT_PLUGIN_PATH ${qtHelpers.QT_PLUGIN_PATH}
      --set QT_QPA_PLATFORM_PLUGIN_PATH ${qtHelpers.QT_QPA_PLATFORM_PLUGIN_PATH}
    ''
    + lib.optionalString (distro != "humble") ''
      --set-default GZ_IP 127.0.0.1
      --set-default GAZEBO_VERSION ${ros2gz distro}
      --set-default GZ_VERSION ${ros2gz distro}
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
    {
      enableQt ? true,
      enableColcon ? true,
      enableVenv ? true,
      ...
    }:
    let
      qtVersion = ros2qt distro;
      qtHelpers = mkQtHelpers pkgs qtVersion;
    in
    ''
      unset QT_PLUGIN_PATH
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
      : ''${IGN_VERSION:=${ros2gz distro}}
      : ''${IGNITION_VERSION:=${ros2gz distro}}
      export IGN_IP
      export IGN_VERSION
      export IGNITION_VERSION
    ''
    + lib.optionalString (env != null && distro == "humble") ''
      IGN_CONFIG_PATH=${env}/share/ignition:''${IGN_CONFIG_PATH:+:$IGN_CONFIG_PATH}
      IGN_GAZEBO_RESOURCE_PATH=${env}/share:''${IGN_GAZEBO_RESOURCE_PATH:+:$IGN_GAZEBO_RESOURCE_PATH}
      export IGN_CONFIG_PATH
      export IGN_GAZEBO_RESOURCE_PATH
    ''
    + lib.optionalString (pkgs != null && enableQt && qtVersion == "5") ''
      QML2_IMPORT_PATH=${qtHelpers.QML2_IMPORT_PATH}
      QT_PLUGIN_PATH=${qtHelpers.QT_PLUGIN_PATH}
      QT_QPA_PLATFORM_PLUGIN_PATH=${qtHelpers.QT_QPA_PLATFORM_PLUGIN_PATH}
      export QML2_IMPORT_PATH
      export QT_PLUGIN_PATH
      export QT_QPA_PLATFORM_PLUGIN_PATH
    ''
    + lib.optionalString (distro != "humble") ''
      : ''${GZ_IP:=127.0.0.1}
      : ''${GAZEBO_VERSION:=${ros2gz distro}}
      : ''${GZ_VERSION:=${ros2gz distro}}
      export GZ_IP
      export GAZEBO_VERSION
      export GZ_VERSION
    ''
    + lib.optionalString (env != null && distro != "humble") ''
      GZ_CONFIG_PATH=${env}/share/gz:''${GZ_CONFIG_PATH:+:$GZ_CONFIG_PATH}
      GZ_SIM_RESOURCE_PATH=${env}/share:''${GZ_SIM_RESOURCE_PATH:+:$GZ_SIM_RESOURCE_PATH}
      export GZ_CONFIG_PATH
      export GZ_SIM_RESOURCE_PATH
    ''
    + lib.optionalString enableColcon ''
      test -f install/local_setup.bash && source install/local_setup.bash
    ''
    + lib.optionalString enableVenv ''
      test -f .venv/bin/activate && source .venv/bin/activate
    '';

  /**
    get a list of common ros packages.

    Don't hesitate to contact us to extend this list !
  */
  getRosBasePackages =
    pkgs: distro:
    [
      pkgs.colcon
      pkgs.rosPackages.${distro}.ros2action
      pkgs.rosPackages.${distro}.ros2cli
      pkgs.rosPackages.${distro}.ros2controlcli
      pkgs.rosPackages.${distro}.ros2launch
      pkgs.rosPackages.${distro}.ros2run
      pkgs.rosPackages.${distro}.ros2topic
      pkgs.rosPackages.${distro}.ros2topic
      pkgs.rosPackages.${distro}.launch-testing-ament-cmake
    ]
    ++ pkgs.rosPackages.${distro}.ament-lint-common.propagatedBuildInputs;

  /**
    Generate libFlakoboros
  */
  mkLibFlakoboros =
    config:
    import ./mk-lib.nix {
      inherit
        config
        lib
        mkQtHelpers
        ros2qt
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
