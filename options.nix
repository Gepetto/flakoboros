{
  lib,
}:
{
  overrideAttrs = lib.mkOption {
    description = "packages attrs override";
    default = { };
    example = {
      hello = {
        postPatch = ''
          substituteInPlace src/hello.c po/*.po tests/hello-1 tests/traditional-1 \
            --replace-fail "world" "flakoboros"
        '';
      };
    };
  };
  pyOverrideAttrs = lib.mkOption {
    description = "python packages attrs override";
    default = { };
    example = {
      example-robot-data =
        {
          pkgs-final,
          drv-final,
          drv-prev,
          py-final,
          ...
        }:
        {
          src = lib.cleanSource ./.;
          cmakeFlags = [ (lib.cmakeBool "BUILD_TESTING" drv-final.doCheck) ];
          nativeBuildInputs = drv-prev.nativeBuildinputs ++ [ pkgs-final.ninja ];
          dependencies = drv-prev.dependencies ++ [ py-final.rerun-sdk ];
        };
    };
  };
  rosOverrideAttrs = lib.mkOption {
    description = "ROS packages attrs override";
    default = { };
    example = {
      eigenpy =
        { pkgs-final, ... }:
        {
          patches = [
            (pkgs-final.fetchpatch {
              name = "eigen5-support.patch";
              url = "https://github.com/stack-of-tasks/eigenpy/commit/3bd6b04229035c55fe92bba42acb88ef2588850f.patch?full_index=1";
              hash = "sha256-6wpExdUN6zot4VAkueHJfvBfk47om481BcsMrBdI12I=";
            })
          ];
        };
    };
  };

  overrides = lib.mkOption {
    description = "packages overrides";
    default = { };
    example = lib.literalExpression ''
      {
        blas =
          { pkgs-final, ... }:
          {
            blasProvider = pkgs-final.mkl;
          };
      };
    '';
  };
  pyOverrides = lib.mkOption {
    description = "python packages overrides";
    default = { };
    example = {
      coal = {
        buildStandalone = false;
      };
    };
  };
  rosOverrides = lib.mkOption {
    description = "ROS packages overrides";
    default = { };
    example = {
      ogre = {
        freeimage = { pkgs-final, ... }: pkgs-final.stbi;
      };
    };
  };

  packages = lib.mkOption {
    description = "new packages definitions";
    default = { };
    example = lib.literalExpression ''
      {
        my-lib = ./package.nix;
      };
    '';
  };
  pyPackages = lib.mkOption {
    description = "new python packages definitions";
    default = { };
    example = lib.literalExpression ''
      {
        my-module =
          { buildPythonPackage, numpy }:
          buildPythonPackage {
            pname = "my-module";
            inherit ((lib.importToml ./pyproject.toml).project) version;
            pyproject = true;

            src = lib.cleanSource ./.;
            dependencies = [ numpy ];
          };
      };
    '';
  };
  rosPackages = lib.mkOption {
    description = "new ROS packages definitions";
    default = { };
    example = lib.literalExpression ''
      {
        my-ros-lib = ./my-ros-lib/package.nix;
      };
    '';
  };

  extraPackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "extra packages to use in env and devShell";
    default = [ ];
    example = [
      "gdb"
      "ninja"
      "sccache"
    ];
  };
  extraPyPackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "extra python packages to use in env and devShell";
    default = [ ];
    example = [
      "ipython"
      "ruff"
    ];
  };
  extraRosPackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "extra ROS packages to use in env and devShell";
    default = [ ];
    example = [
      "plotjuggler"
      "ros2doctor"
    ];
  };

  extraDevPackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "extra packages to build in shell, and get dependencies from in devShells";
    default = [ ];
  };
  extraDevPyPackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "extra python packages to build in shell, and get dependencies from in devShells";
    default = [ ];
  };
  extraDevRosPackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "extra ROS packages to build in shell, and get dependencies from in devShells";
    default = [ ];
  };

  overlays = lib.mkOption {
    description = "Additionnal overlays";
    default = [ ];
    example = lib.literalExpression ''
      [
        inputs.hpp-core.overlays.flakoboros
        inputs.hpp-constraints.overlays.flakoboros
      ];
    '';
  };
  extends = lib.mkOption {
    description = "overlays to define alternate `pkgs-*`";
    default = { };
    example = lib.literalExpression ''
      {
        eigen5 = final: prev: {
          eigen = final.eigen_5;
        };
      };
    '';
  };

  rosDistros = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "ROS distributions to consider";
    default = [
      "humble"
      "jazzy"
      "kilted"
      "rolling"
    ];
    example = [ "rolling" ];
  };
  rosShellDistro = lib.mkOption {
    type = lib.types.str;
    description = "The ROS distribution of the default env and devShell";
    default = "rolling";
    example = "jazzy";
  };

  filterPackages = lib.mkOption {
    description = "Function to filter the packages to include in default env and devShell";
    default = _n: _v: true;
    example = n: _v: ((!lib.hasPrefix "gz-" n) || lib.hasPrefix "gz-harmonic-" n);
  };

  pkgs = lib.mkOption {
    type = lib.types.bool;
    description = "define pkgs from nixpkgs with overlays from nix-ros-overlay, flakoboros, and config.flakoboros.overlays";
    default = true;
    example = false;
  };
  nixpkgsConfig = lib.mkOption {
    description = "nixpkgs configuration in pkgs";
    default = { };
    example = {
      allowUnfree = true;
    };
  };

  check = lib.mkOption {
    type = lib.types.bool;
    description = "build all packages and devShells in checks";
    default = false;
    example = true;
  };
}
