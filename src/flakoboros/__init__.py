"""
Sync https://github.com/ros/rosdistro/tree/master/rosdep in $XDG_CACHE_HOME/flakoboros

This will download 3 small files once a month.
Hopefully we won't need GITHUB_TOKEN.
For this let's at least respect some user agent etiquette.
"""

import argparse
import json
import logging
import os
import pathlib
import subprocess
import time

from catkin_pkg.package import parse_package
import httpx
from xdg_base_dirs import xdg_cache_home


NAME = "flakoboros"
LOGGER = logging.getLogger(NAME)
JSON = f"{NAME}.json"
PACKAGE = "package.xml"
CACHE = xdg_cache_home() / JSON

FLAKE_TEMPLATE = """
{
  inputs.gazebros2nix.url = "github:gepetto/gazebros2nix";

  outputs =
    inputs:
    inputs.gazebros2nix.lib.mkFlakoboros inputs (
      { lib, ... }: lib.importJSON ./wsconf.json
    );
}
"""

parser = argparse.ArgumentParser()
parser.add_argument("-r", "--ros", default="rolling")
parser.add_argument(
    "-d",
    "--dist",
    default="https://gepetto.github.io/gazebros2nix",
    help="source for the flakoboros.json file",
)
parser.add_argument(
    "-q",
    "--quiet",
    action="count",
    default=int(os.environ.get("QUIET", "0")),
    help="decrement verbosity level",
)
parser.add_argument(
    "-v",
    "--verbose",
    action="count",
    default=int(os.environ.get("VERBOSITY", "0")),
    help="increment verbosity level",
)


def get_cache(dist):
    CACHE.parent.mkdir(exist_ok=True)

    if not (CACHE.exists() and (time.time() - CACHE.stat().st_mtime) < 24 * 3600):
        r = httpx.get(f"{dist}/{JSON}")
        r.raise_for_status()
        CACHE.write_text(r.text)

    return json.loads(CACHE.read_text())


def ensure_setup():
    flake = pathlib.Path("flake.nix")
    if not flake.is_file():
        flake.write_text(FLAKE_TEMPLATE)

    envrc = pathlib.Path(".envrc")
    if not envrc.is_file():
        envrc.write_text("use flake .")
        try:
            subprocess.run(
                ["direnv", "allow"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except FileNotFoundError:
            LOGGER.warning(
                "direnv is not available, you will need to manually run 'nix develop'"
            )


def main():
    args = parser.parse_args()
    logging.basicConfig(level=30 - 10 * args.verbose + 10 * args.quiet)

    src = pathlib.Path("src")
    if not src.is_dir():
        LOGGER.error("There is no 'src/' directory here")
        return

    ensure_setup()

    cache = get_cache(args.dist)

    wsconf = {
        "extraPackages": set(),
        "extraPyPackages": set(),
        "extraRosPackages": set(),
        "extraDevPackage": set(),
        "extraDevPyPackages": set(),
        "extraDevRosPackages": set(),
    }
    os.environ["ROS_DISTRO"] = "humble" if args.ros == "alum" else args.ros
    os.environ["ROS_VERSION"] = "2"
    os.environ["ROS_PYTHON_VERSION"] = "3"
    for root, _dirs, files in src.walk():
        if PACKAGE in files:
            pkg = parse_package(root)
            name = pkg.name.replace("_", "-")
            if name in cache["ros"]:
                wsconf["extraDevRosPackages"].add(name)
                LOGGER.info("added %s", pkg.name)
            else:
                LOGGER.warning(
                    "%s is not available in the distribution. It would be better to add it.",
                    pkg.name,
                )
                for dep in (
                    pkg.buildtool_depends
                    + pkg.buildtool_export_depends
                    + pkg.doc_depends
                    + pkg.build_depends
                    + pkg.exec_depends
                    + pkg.build_export_depends
                    + pkg.test_depends
                ):
                    name = dep.name.replace("_", "-")
                    if name in cache["ros"]:
                        wsconf["extraRosPackages"].add(name)
                    elif name in cache["rosdep"]:
                        for rosdep in cache["rosdep"][name]:
                            if rosdep.startswith("python3Packages."):
                                wsconf["extraPyPackages"].add(
                                    rosdep.removePrefix("python3Packages.")
                                )
                            else:
                                wsconf["extraPackages"].add(rosdep)
                    elif name in cache["python"]:
                        wsconf["extraPyPackages"].add(name)
                    elif name in cache["pkgs"]:
                        wsconf["extraPackages"].add(name)
                    else:
                        LOGGER.error(
                            "%s is unknown. maybe you should clone it too ?", name
                        )

    wsconf = {k: list(v) for k, v in wsconf.items() if v}
    wsconf["rosShellDistro"] = args.ros
    wsconf["rosDistros"] = [args.ros]
    pathlib.Path("wsconf.json").write_text(json.dumps(wsconf, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
