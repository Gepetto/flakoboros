{
  lib,
}:
{
  packages = lib.mkOption {
    description = "new packages to define";
    default = { };
  };
  pyPackages = lib.mkOption {
    description = "new python packages to define";
    default = { };
  };
  rosPackages = lib.mkOption {
    description = "new ROS packages to define";
    default = { };
  };

  overrides = lib.mkOption {
    description = "packages overrides";
    default = { };
  };
  pyOverrides = lib.mkOption {
    description = "python packages overrides";
    default = { };
  };
  rosOverrides = lib.mkOption {
    description = "ROS packages overrides";
    default = { };
  };

  overrideAttrs = lib.mkOption {
    description = "packages attrs override";
    default = { };
  };
  pyOverrideAttrs = lib.mkOption {
    description = "python packages attrs override";
    default = { };
  };
  rosOverrideAttrs = lib.mkOption {
    description = "ROS packages attrs override";
    default = { };
  };

  extraPackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "extra packages to use in env and devShell";
    default = [ ];
  };
  extraPyPackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "extra python packages to use in env and devShell";
    default = [ ];
  };
  extraRosPackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "extra ROS packages to use in env and devShell";
    default = [ ];
  };

  extraDevPackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "extra packages to get dependencies from in devShells";
    default = [ ];
  };
  extraDevPyPackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "extra python packages to get dependencies from in devShells";
    default = [ ];
  };
  extraDevRosPackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "extra ROS packages to get dependencies from in devShells";
    default = [ ];
  };

  overlays = lib.mkOption {
    description = "Additionnal overlays";
    default = [ ];
  };
  extends = lib.mkOption {
    description = "overlays to define alternate `pkgs-*`";
    default = { };
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
  };
  rosShellDistro = lib.mkOption {
    type = lib.types.str;
    description = "The ROS distribution of the default env and devShell";
    default = "rolling";
  };

  filterPackages = lib.mkOption {
    description = "Function to filter the packages to include in default env and devShell";
    default = _n: _v: true;
  };

  pkgs = lib.mkOption {
    type = lib.types.bool;
    description = "define pkgs from nixpkgs with overlays from nix-ros-overlay, flakoboros, and config.flakoboros.overlays";
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
}
