{
  lib,
}:
{
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

  extraPackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "list of packages to include in addition to packages, overrides & overrideAttrs";
    default = [ ];
  };
  extraPyPackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "list of python packages to include in addition to pyPackages, pyOverrides & pyOverrideAttrs";
    default = [ ];
  };
  extraRosPackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "list of ROS packages to include in addition to rosPackages, rosOverrides & rosOverrideAttrs";
    default = [ ];
  };
}
