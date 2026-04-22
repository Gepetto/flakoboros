{
  description = "flake to generate docs";

  inputs = {
    flakoboros.url = "path:../";

    nixpkgs.follows = "flakoboros/nix-ros-overlay/nixpkgs";
    flake-parts.follows = "flakoboros/flake-parts";
    systems.follows = "flakoboros/systems";

    search = {
      url = "github:NuschtOS/search";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } ({
      systems = import inputs.systems;
      perSystem =
        {
          lib,
          pkgs,
          inputs',
          self',
          ...
        }:
        {
          devShells.default = pkgs.mkShell {
            name = "docs shell";
            packages = [
              pkgs.mdbook
              pkgs.nixdoc
            ];
          };

          packages = {
            default = pkgs.stdenvNoCC.mkDerivation {
              name = "flakoboros-docs-book";
              src = lib.cleanSource ./.;
              postPatch = ''
                substituteInPlace README.md --replace-fail "./docs/" "./"
              '';

              buildInputs = [
                self'.packages.gen-nixdoc
                self'.packages.search
              ];
              nativeBuildInputs = [
                pkgs.mdbook
              ];

              buildPhase = ''
                cp -r ${self'.packages.gen-nixdoc}/* .

                mdbook build -d $out

                mkdir -p $out/search
                cp -r ${self'.packages.search}/* $out/search
              '';
            };

            gen-nixdoc = pkgs.stdenvNoCC.mkDerivation {
              name = "flakoboros-docs-nixdoc";
              dontUnpack = true;
              nativeBuildInputs = [ pkgs.nixdoc ];

              buildPhase = ''
                mkdir $out
                nixdoc -p lib -c "" -d "Plain lib" -f ${inputs.flakoboros}/lib/default.nix > $out/plain-lib.md
                nixdoc -p libFlakoboros -c "" -d "Generated lib" -f ${inputs.flakoboros}/lib/mk-lib.nix > $out/generated-lib.md
              '';
            };

            search = inputs'.search.packages.mkSearch {
              baseHref = "/flakoboros/search/";
              modules = [ inputs.flakoboros.flakeModule ];
              title = "flakoboros";
              urlPrefix = "https://github.com/gepetto/flakoboros/blob/main/";
            };
          };
        };
    });
}
