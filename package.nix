{
  lib,
  python3Packages,
}:
let
  pyproject = lib.importTOML ./pyproject.toml;
in
python3Packages.buildPythonApplication (_finalAttrs: {
  inherit (pyproject.project) name version;
  pyproject = true;
  __structuredAttrs = true;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./docs/README.md
      ./pyproject.toml
      ./README.md
      ./src
    ];
  };

  build-system = [
    python3Packages.uv-build
  ];

  dependencies = with python3Packages; [
    catkin-pkg
    httpx
    xdg-base-dirs
  ];

  pythonImportsCheck = [
    "flakoboros"
  ];

  meta = {
    description = "Circular Packaging framework with nix Flakes, including ROS support";
    homepage = "https://github.com/Gepetto/flakoboros";
    license = lib.licenses.bsd2;
    maintainers = with lib.maintainers; [ nim65s ];
    mainProgram = "flakoboros";
  };
})
