# plain lib {#sec-functions-library-}


## `lib.ros2gz` {#function-library-lib.ros2gz}

mapping of recommended Gazebo distro per ROS distro

## `lib.rosWrapperArgs` {#function-library-lib.rosWrapperArgs}

set many env vars in a makeWrapperArgs format for postBuild

## `lib.rosShellHook` {#function-library-lib.rosShellHook}

set many env vars in a bash format for pkgs.mkShell { shellHook = … }

## `lib.getRosBasePackages` {#function-library-lib.getRosBasePackages}

get a list of common ros packages.

Don't hesitate to contact us to extend this list !

## `lib.mkLibFlakoboros` {#function-library-lib.mkLibFlakoboros}

Generate libFlakoboros

## `lib.loadVersion` {#function-library-lib.loadVersion}

Extract version from a structured file

## `lib.rosVersion` {#function-library-lib.rosVersion}

Extract version from a ROS package.xml file

## `lib.pythonVersion` {#function-library-lib.pythonVersion}

Extract version from a python pyproject.toml file
