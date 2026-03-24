{
  nix-ros-overlay,
  nixpkgs,
  ...
}:
{
  config,
  lib,
  self,
  ...
}:
let
  cfg = config.flakoboros;
in
{
  options.flakoboros = {
    overlays = lib.mkOption {
      description = "Additionnal overlays for flakoboros";
      default = [ ];
    };

    packages = lib.mkOption {
      description = "packages to add in overlay";
      default = { };
    };
    pyPackages = lib.mkOption {
      description = "python packages to add in overlay";
      default = { };
    };
    rosPackages = lib.mkOption {
      description = "ROS packages to add in overlay";
      default = { };
    };

    overrides = lib.mkOption {
      description = "attrSet of packages name/override to add in overlay";
      default = { };
    };
    pyOverrides = lib.mkOption {
      description = "attrSet of python packages name/override to add in overlay";
      default = { };
    };
    rosOverrides = lib.mkOption {
      description = "attrSet of ROS packages name/override to add in overlay";
      default = { };
    };

    overrideAttrs = lib.mkOption {
      description = "attrSet of packages name/overrideAttrs to add in overlay";
      default = { };
    };
    pyOverrideAttrs = lib.mkOption {
      description = "attrSet of python packages name/overrideAttrs to add in overlay";
      default = { };
    };
    rosOverrideAttrs = lib.mkOption {
      description = "attrSet of ROS packages name/overrideAttrs to add in overlay";
      default = { };
    };

    rosDistros = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of ROS distributions to consider for rosOverrides & rosPackages overlay";
      default = [
        "humble"
        "jazzy"
        "kilted"
        "rolling"
      ];
    };
    rosShellDistro = lib.mkOption {
      type = lib.types.str;
      description = "The ROS distribution of the default devShell and env";
      default = "rolling";
    };

    filterPackages = lib.mkOption {
      description = "Function to filter the packages to include in default devShell and env";
      default = _n: _v: true;
    };

    pkgs = lib.mkOption {
      type = lib.types.bool;
      description = "define pkgs from nixpkgs with overlays from nix-ros-overlay, flakoboros, and overlays";
      default = true;
    };
    nixpkgsConfig = lib.mkOption {
      description = "nixpkgs configuration in pkgs";
      default = { };
    };
    check = lib.mkOption {
      type = lib.types.bool;
      description = "build all packages and devShells in checks";
      default = false;
    };

    extraPythonModules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "list of python modules to include in apps.default, in addition to pyPackages, pyOverrides & pyOverrideAttrs";
      default = [ ];
    };
  };

  config =
    let
      rosWrapperArgs =
        distro: pkgs:
        ''
          rosWrapperArgs+=(
          --unset QTWEBKIT_PLUGIN_PATH
          --unset QT_QPA_PLATFORMTHEME
          --unset QT_STYLE_OVERRIDE
          --prefix AMENT_PREFIX_PATH : $out
          --prefix LD_LIBRARY_PATH : $out/lib
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
        {
          env ? null,
          pkgs ? null,
        }:
        let
          distro = cfg.rosShellDistro;
        in
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

      getRosBasePackages = distro: pkgs: [
        pkgs.colcon
        pkgs.rosPackages.${distro}.ros2action
        pkgs.rosPackages.${distro}.ros2launch
        pkgs.rosPackages.${distro}.ros2run
        pkgs.rosPackages.${distro}.ros2topic
      ];

      buildGazebros2nixShell =
        distro: pkgs: packages:
        pkgs.mkShell {
          name = "flakoboros default shell";
          __structuredAttrs = true;
          strictDeps = true;
          packages = lib.attrValues (
            lib.filterAttrs (
              n: v:
              (n != "default")
              && (cfg.filterPackages n v)
              && ((!lib.hasPrefix "ros-" n) || lib.hasPrefix "ros-${distro}-" n)
            ) packages
          );
        };

      buildGazebros2nixEnv =
        distro: pkgs: packages:
        let
          shell = buildGazebros2nixShell distro pkgs packages;
        in
        pkgs.rosPackages.${distro}.buildEnv {
          paths = lib.unique (
            lib.filter lib.isDerivation (
              (shell.buildInputs or [ ])
              ++ (shell.nativeBuildInputs or [ ])
              ++ (shell.propagatedNativeBuildInputs or [ ])
              ++ (shell.propagatedBuildInputs or [ ])
            )
            ++ lib.attrVals (lib.uniqueStrings cfg.extraPythonModules) pkgs.python3Packages
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
          postBuild = rosWrapperArgs cfg.rosShellDistro pkgs;
        };

      buildGazebros2nixDevShell =
        distro: pkgs: packages:
        pkgs.mkShell {
          name = "flakoboros default devShell";
          __structuredAttrs = true;
          strictDeps = true;
          inputsFrom = lib.attrValues (
            lib.filterAttrs (
              n: v:
              (n != "default")
              && (cfg.filterPackages n v)
              && ((!lib.hasPrefix "ros-" n) || lib.hasPrefix "ros-${distro}-" n)
            ) packages
          );
          packages = lib.attrVals (lib.uniqueStrings cfg.extraPythonModules) pkgs.python3Packages;
        };

      buildGazebros2nixRosShell =
        distro: pkgs: packages:
        let
          shell = buildGazebros2nixShell distro pkgs packages;
          env = buildGazebros2nixEnv distro pkgs packages;
        in
        pkgs.mkShell {
          name = "flakoboros default ROS shell";
          __structuredAttrs = true;
          strictDeps = true;
          inputsFrom = [ shell ];
          packages = getRosBasePackages distro pkgs;
          shellHook = rosShellHook { inherit env pkgs; };
        };

      buildGazebros2nixRosEnv =
        distro: pkgs: packages:
        let
          shell = buildGazebros2nixDevShell distro pkgs packages;
        in
        pkgs.rosPackages.${distro}.buildEnv {
          paths = lib.unique (
            lib.filter lib.isDerivation (
              (shell.buildInputs or [ ])
              ++ (shell.nativeBuildInputs or [ ])
              ++ (shell.propagatedNativeBuildInputs or [ ])
              ++ (shell.propagatedBuildInputs or [ ])
            )
            ++ lib.attrVals (lib.uniqueStrings cfg.extraPythonModules) pkgs.python3Packages
            ++ lib.optional (
              distro == "humble" || distro == "jazzy" || distro == "kilted"
            ) pkgs.qt5.wrapQtAppsHook
            ++ lib.optionals (distro == "rolling") [
              pkgs.qt6.wrapQtAppsHook
              pkgs.qt6.qtbase
            ]
          );
        };

      buildGazebros2nixRosDevShell =
        distro: pkgs: packages:
        let
          shell = buildGazebros2nixDevShell distro pkgs packages;
          env = buildGazebros2nixRosEnv distro pkgs packages;
        in
        pkgs.mkShell {
          name = "flakoboros default ROS devShell";
          __structuredAttrs = true;
          strictDeps = true;
          inputsFrom = [ shell ];
          packages =
            getRosBasePackages distro pkgs
            ++ lib.attrVals (lib.uniqueStrings cfg.extraPythonModules) pkgs.python3Packages;
          shellHook = rosShellHook { inherit env pkgs; };
        };

      loadVersion =
        bin: path: pkgs: file:
        pkgs.lib.trim (
          builtins.readFile (
            pkgs.runCommandLocal "version" {
              nativeBuildInputs = [ pkgs.yq ];
            } "${bin} -r ${path} ${file} > $out"
          )
        );
      rosVersion = loadVersion "xq" ".package.version";
      pythonVersion = loadVersion "tomlq" ".project.version";

    in
    {
      flake = {
        lib = {
          inherit
            rosWrapperArgs
            rosShellHook
            getRosBasePackages
            buildGazebros2nixShell
            buildGazebros2nixEnv
            buildGazebros2nixDevShell
            buildGazebros2nixRosShell
            buildGazebros2nixRosEnv
            buildGazebros2nixRosDevShell
            pythonVersion
            rosVersion
            ;
        };

        overlays.default = lib.composeManyExtensions [
          (
            final: prev:
            (lib.mapAttrs (_name: package: final.callPackage package { }) cfg.packages)
            // {
              pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                (
                  python-final: _python-prev:
                  lib.mapAttrs (_name: package: python-final.callPackage package { }) cfg.pyPackages
                )
              ];

              rosPackages =
                prev.rosPackages
                // lib.genAttrs cfg.rosDistros (
                  distro:
                  prev.rosPackages.${distro}.overrideScope (
                    ros-final: _ros-prev:
                    lib.mapAttrs (_name: package: ros-final.callPackage package { }) cfg.rosPackages
                  )
                );
            }
          )

          (
            final: prev:
            (lib.mapAttrs (name: override: prev.${name}.override (override final)) cfg.overrides)
            // {
              pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                (
                  python-final: python-prev:
                  lib.mapAttrs (
                    name: override: python-prev.${name}.override (override final python-final)
                  ) cfg.pyOverrides
                )
              ];

              rosPackages =
                prev.rosPackages
                // lib.genAttrs cfg.rosDistros (
                  distro:
                  prev.rosPackages.${distro}.overrideScope (
                    ros-final: ros-prev:
                    lib.mapAttrs (name: override: ros-prev.${name}.override (override final ros-final)) cfg.rosOverrides
                  )
                );
            }
          )

          (
            final: prev:
            (lib.mapAttrs (name: override: prev.${name}.overrideAttrs (override final)) cfg.overrideAttrs)
            // {
              pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                (
                  python-final: python-prev:
                  lib.mapAttrs (
                    name: override: python-prev.${name}.overrideAttrs (override final python-final)
                  ) cfg.pyOverrideAttrs
                )
              ];

              rosPackages =
                prev.rosPackages
                // lib.genAttrs cfg.rosDistros (
                  distro:
                  prev.rosPackages.${distro}.overrideScope (
                    ros-final: ros-prev:
                    lib.mapAttrs (
                      name: override: ros-prev.${name}.overrideAttrs (override final ros-final)
                    ) cfg.rosOverrideAttrs
                  )
                );
            }
          )
        ];
      };

      perSystem =
        let
          pythonModules =
            lib.attrNames (cfg.pyPackages // cfg.pyOverrides // cfg.pyOverrideAttrs) ++ cfg.extraPythonModules;
        in
        {
          pkgs,
          self',
          system,
          ...
        }:
        {
          devShells = {
            default = lib.mkDefault (
              if (cfg.rosPackages == { } && cfg.rosOverrides == { } && cfg.rosOverrideAttrs == { }) then
                (buildGazebros2nixDevShell cfg.rosShellDistro pkgs self'.packages)
              else
                (buildGazebros2nixRosDevShell cfg.rosShellDistro pkgs self'.packages)
            );
          }
          //
            lib.optionalAttrs (cfg.rosPackages != { } || cfg.rosOverrides != { } || cfg.rosOverrideAttrs != { })
              (
                lib.genAttrs' cfg.rosDistros (
                  distro: lib.nameValuePair "ros-${distro}" (buildGazebros2nixRosDevShell distro pkgs self'.packages)
                )
              );

          packages = {
            default = lib.mkDefault (
              if (cfg.rosPackages == { } && cfg.rosOverrides == { } && cfg.rosOverrideAttrs == { }) then
                (buildGazebros2nixEnv cfg.rosShellDistro pkgs self'.packages)
              else
                (buildGazebros2nixRosEnv cfg.rosShellDistro pkgs self'.packages)
            );
          }
          // (lib.mapAttrs (name: _v: pkgs.${name}) (cfg.packages // cfg.overrides // cfg.overrideAttrs))
          // (lib.mapAttrs' (name: _v: lib.nameValuePair "py-${name}" pkgs.python3Packages.${name}) (
            cfg.pyPackages // cfg.pyOverrides // cfg.pyOverrideAttrs
          ))
          // (lib.listToAttrs (
            lib.mapCartesianProduct
              ({ distro, name }: lib.nameValuePair "ros-${distro}-${name}" pkgs.rosPackages.${distro}.${name})
              {
                distro = cfg.rosDistros;
                name = lib.attrNames (cfg.rosPackages // cfg.rosOverrides // cfg.rosOverrideAttrs);
              }
          ))
          //
            lib.optionalAttrs (cfg.rosPackages != { } || cfg.rosOverrides != { } || cfg.rosOverrideAttrs != { })
              (
                lib.genAttrs' cfg.rosDistros (
                  distro: lib.nameValuePair "ros-${distro}" (buildGazebros2nixRosEnv distro pkgs self'.packages)
                )
              );
        }

        // lib.optionalAttrs cfg.pkgs {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config = cfg.nixpkgsConfig;
            overlays = [
              nix-ros-overlay.overlays.default
              self.overlays.default
            ]
            ++ cfg.overlays;
          };
        }

        // lib.optionalAttrs (pythonModules != [ ]) {
          apps.default = {
            type = "app";
            program = pkgs.python3.withPackages (p: lib.attrVals (lib.uniqueStrings pythonModules) p);
          };
        }

        // lib.optionalAttrs cfg.check {
          # Build all available packages and devShells. Useful for CI.
          checks =
            let
              devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") self'.devShells;
              packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") self'.packages;
            in
            lib.filterAttrs (_n: v: v.meta.available && !v.meta.broken) (devShells // packages);
        };
    };
}
