# Build a ROS workspace

In this example, we will show how to deal with a standard ROS development workflow, where the dependencies are backed by nix.

## Define which repos you want to manually build

We will split the whole dependency tree in two distinct sets: the source repositories you will manually build for your development, and those which will be handled by nix.

> [!NOTE]
> The limitiation here is that we should not have any package in the second set that depend on any package from the first :)

One usual way of defining multiple repositories in the ROS community is with this eg. `agimus.repos` yaml file:

```yaml
repositories:
  agimus-controller:
    type: git
    url: https://github.com/agimus-project/agimus-controller
    version: main
  agimus-demos:
    type: git
    url: https://github.com/agimus-project/agimus-demos
    version: main
  agimus-msgs:
    type: git
    url: https://github.com/agimus-project/agimus-msgs
    version: main
  linear-feedback-controller:
    type: git
    url: https://github.com/loco-3d/linear-feedback-controller
    version: main
  linear-feedback-controller-msgs:
    type: git
    url: https://github.com/loco-3d/linear-feedback-controller-msgs
    version: main
```

Then you can clone all of that in a `src` directory:
```bash
mkdir src
vcs import --input agimus.repos src
```

> [!TIP]
> If you don't already have the `vcs` program, you can eg.:
> `nix run nixpkgs#vcs2l -- import --input agimus.repos src`

## Find all the ROS packages in those repositories

Then we can find all the `package.xml` files in our `src` dir, look for the `name` key, and format that for nix:
```
fd package.xml src -x xq .package.name | tr _ - | sort -u
```

> [!TIP]
> If you don't already have the wonderful [fd](https://github.com/sharkdp/fd) and/or [xq](https://github.com/MiSawa/xq) available:
> `nix shell nixpkgs#{fd,xq} --command fd package.xml src -x xq .package.name | tr _ - | sort -u`

## Write your flake

Now you can create a `flake.nix`:
```nix
{
  description = "example flake for agimus demos with flakoboros";
  inputs.gepetto.url = "github:gepetto/nix";
  outputs =
    inputs:
    inputs.gepetto.lib.mkFlakoboros inputs (
      { lib, ... }:
      {
        rosDistros = [ # We don't have kilted/rolling on those packages yet
          "humble"
          "jazzy"
        ];
        rosShellDistro = "humble"; # rolling would be the default without this
        extraDevRosPackages = [ # Put here the list you got at the previous step
          "agimus-controller"
          "agimus-controller-ros"
          "agimus-demo-00-franka-controller"
          "agimus-demo-01-lfc-alone"
          "agimus-demo-02-simple-pd-plus"
          "agimus-demo-02-simple-pd-plus-tiago-pro"
          "agimus-demo-03-mpc-dummy-traj"
          "agimus-demo-03-mpc-dummy-traj-tiago-pro"
          # "agimus-demo-04-dual-arm-tiago-pro"
          "agimus-demo-04-visual-servoing"
          "agimus-demo-05-pick-and-place"
          "agimus-demo-06-regrasp"
          # "agimus-demo-07-deburring"
          "agimus-demo-08-collision-avoidance"
          "agimus-demos"
          "agimus-demos-common"
          "agimus-demos-controllers"
          "agimus-msgs"
          "linear-feedback-controller"
          "linear-feedback-controller-msgs"
        ];
      }
    );
}
```

> [!WARNING]
> Work in progress: demos 04 and 07 must be commented for now

## Activate your development shell

The standard nix way here is `nix develop`: it will start a `bash` shell with everything you need to continue.

But if you want something a bit more comfortable, you can set up [nix-direnv](https://github.com/nix-community/nix-direnv). Once this is done, auto-activating the `nix develop` in the current folder by adjusting environment variables instead of spawning a new shell can be achieved with:

```bash
echo 'use flake .' > .envrc
direnv allow
```

## Build your packages

```bash
colcon build
```

## Enable the new prefix

This is automatically done on entering `nix develop` if `install/setup.bash` exists, but before the first compilation that was not the case. Therefore, for this time only, you should probably:

```bash
source install/setup.bash
```

## Profit

```bash
ros2 launch agimus_demo_03_mpc_dummy_traj bringup.launch.py use_gazebo:=true use_rviz:=true
```
