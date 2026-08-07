{
  lib,
  python3Packages,
  nix-update-script,
}:

python3Packages.buildPythonApplication (_finalAttrs: {
  pname = "flakoboros";
  version = "0-unstable-2026-08-05";
  pyproject = true;
  __structuredAttrs = true;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./docs/README.md
      ./pyproject.toml
      ./src
      ./README.md
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

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Circular Packaging framework with nix Flakes, including ROS support";
    homepage = "https://github.com/Gepetto/flakoboros";
    license = lib.licenses.bsd2;
    maintainers = with lib.maintainers; [ nim65s ];
    mainProgram = "flakoboros";
  };
})
