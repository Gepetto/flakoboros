# Setup Nix

If you are here and don't have nix yet, here is probably the easiest and fastest way to get started on ubuntu >= 22.04 (jammy) / debian >= 12 (bookworm):

```
# 1. install the right apt package
sudo apt install -y nix-setup-systemd

# 2. activate the new CLI and flake features
echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf

# 3. if you trust us, add our binary caches to avoid recompiling everything
echo 'extra-substituters = https://gepetto.cachix.org https://attic.iid.ciirc.cvut.cz/ros' | sudo tee -a /etc/nix/nix.conf
echo 'extra-trusted-public-keys = gepetto.cachix.org-1:toswMl31VewC0jGkN6+gOelO2Yom0SOHzPwJMY2XiDY= ros:JR95vUYsShSqfA1VTYoFt1Nz6uXasm5QrcOsGry9f6Q=' | sudo tee -a /etc/nix/nix.conf

# 4. activate your new nix.conf
sudo systemctl restart nix-daemon

# 5. allow yourself to use nix
sudo usermod -aG nix-users $(whoami)
newgrp nix-users

# 6. test everything is fine
nix run nixpkgs#ponysay it works
```

## Other setup methods

If you don't want this `nix-setup-systemd` apt package, other options include:

- Nix installer: <https://nixos.org/download/>
- Lix installer: <https://lix.systems/install/>

## Docker

If you want to use nix in docker but don't already know how, please discuss with someone about it.
There are many good solutions, and the best one really depend on your use case. There are also many wrong problems that you should not event start working on.
