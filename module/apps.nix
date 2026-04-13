{
  lib,
  pkgs,

  allPyNames,
  ...
}:
{
  default = {
    type = "app";
    program = lib.getExe (pkgs.python3.withPackages (p: lib.attrVals allPyNames p));
  };
}
