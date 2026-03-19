# Introduction au packaging circulaire

Le logiciel commence généralement à l’état d’un dépôt de source (par exemple avec git), accompagné d’instructions de construction (par exemple avec cmake, uv ou cargo).

Pour faciliter son utilisation, il peut ensuite être empaqueté au sein d’un index (par exemple PyPI, npm ou hackage), et/ou d’une distribution logicielle (par exemple Debian, nixpkgs ou conda-forge).

Cet ordre des choses est naturellement perçu comme linéaire: on parle d’upstream ou de producer pour la source, et de downstream ou consumer pour la distribution.

Mais si on regarde de plus près, il est clair qu'avant même de commencer à développer, il y avait au préalable l’utilisation d’une distribution de logiciels, au moins pour la chaine de construction, et souvent pour les dépendances.

Il nous parait donc intéressant de refermer la boucle, et d’intégrer au mieux la distribution dans la source. Nous verrons que cela facilite à son tour l’intégration de la source dans la distribution dans une boucle vertueuse, et améliore plusieurs aspects du développement, de la maintenance et de l’utilisation des logiciels.

# Présentation de Flakoboros

Pour concrétiser ces idées, nous prendrons l’example de Flakoboros, une framework fondé sur le langage nix, avec son paradigme de flake, et sa distribution nixpkgs.

Flakoboros a pour objectif de fournir une implémentation de packaging circulaire afin de faciliter le développement, la maintenance et la distribution des logiciels produits et utilisés par le groupe de recherche en robotique Gepetto du LAAS-CNRS. Il s’agit donc principalement de gérer les écosystèmes C++ et python (bien que l’intégration de rust soit sérieusement à l’étude), ainsi que les différentes versions de la distribution ROS.

## Introduction (très rapide) à Nix

Nix est une implémentation du "Modèle de déploiement logiciel purement fonctionnel" (ref. dolstra-2006). Les paquets sont écrits dans un Domain-Specific Language qui ressemble au json, mais où une architecture en appels de fonctions fainéantes permet simplement de modifier toutes les données de la distribution.

Dans le cas présent, on s’intéresse au fait que chaque paquet logiciel ait un champ `src` pointant vers la source, qui peut être par exemple une URL HTTPS vers un tarball, ou un dépôt git sur un tag particulier, ou un chemin sur le sytème de fichier local.

NB: ces travaux ont été réalisés avec Nix, mais une implémentation basée sur Guix serait également certainement possible, puisque les deux projets partagent les fondations nécessaires à une concrétisation très simple du packaging circulaire.

L’un des avantages de Nix est sa distribution nixpkgs qui a une très bonne et très vaste couverture des différents langages de programmation et ecosystèmes logiciels, intègre une distribution linux (NixOS) et un support de MacOS, et est maintenue très à jour par de très nombreux contributeurs pratiquant sérieusement le peer-reviewing (ref. repology-graph).

## Example d’utilisation de Flakoboros avec Pinocchio

Pinocchio est un logiciel issu de l’équipe Gepetto du LAAS-CNRS (Toulouse) et aujourd’hui principalement développé par l’équipe Willow de l’INRIA (Paris), qui est packagé et distribué à travers plusieurs gestionnaires de paquets et distributions logicielles, et notamment nix et nixpkgs.

Refermer la boucle du packaging circulaire pour pinocchio consiste donc à inclure dans le dépôt source de pinocchio une extension du paquet pinocchio de nixpkgs qui défini simplement un override de la propriété `src` du paquet par l’état git courant.

En l’occurence, un fichier `flake.nix` comprenant par exemple:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flakoboros.url = "github:gepetto/flakoboros";
    flake-parts.follows = "flakoboros/flake-parts";
    systems.follows = "flakoboros/systems";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (
    { lib, ... }:
    {
      systems = import inputs.systems;
      imports = [
        inputs.flakoboros.flakeModule
        {
          flakoboros = {
            overrides.pinocchio = _: {
              src = lib.cleanSource ./.;  # ce "./." fait tout le travail
            };
          };
        }
      ];
    });
}
```

# Bénéfices

Pour la maintenance de ce logiciel, il devient alors trivial de mettre à jour régulièrement et automatiquement le commit de l’entrée `nixpkgs` de ce flake (dans le fichier généré `flake.lock`), et valider que la version courante de pinocchio n’est pas cassée par une mise à jour de la chaine de compilation (par exemple GCC v15.0.0 ou glibc v2.40), du système de build (par exemple CMake v4.0.0), des dépendances C++ (par exemple Eigen v5.0.0) ou python (par exemple numpy v2.0.0) au fur et à mesure que ceux-ci sont intégrés dans nixpkgs.

S'il y a quoi que ce soit qui pose problème, les auteurs sont avertis rapidement par une pull-request automatique, mais peuvent continuer à utiliser le dernier commit de nixpkgs connu comme fonctionnel qui est dans `flake.lock` tant que la pull request problématique n’est pas résolue et mergée.

De la même manière, lors de la prochaine release de pinocchio (par exemple v4.0.0), la mise à jour du paquet pinocchio dans nixkpgs se passera sans encombres puisque cette intégration est testée en continu côté upstream. On pourra donc profiter du bot de maintenance des paquets, qui va ouvrir automatiquement une pull-request qui met à jour le numéro de version et le hash du tarball correspondant, puis rebuild pinocchio et les paquets qui dépendent de pinocchio. Si tout passe correctement (ce dont on peut s’assurer par ailleurs avant de tagger la release), les mainteneurs déclarés du paquet pinocchio dans nixpkgs pourront dire au bot de merger cette mise à jour, d’une manière suffisament simple et solide pour que les peer-review soient instantanées voire non nécessaires, et que l’on puisse économiser l’intervention d’une personne ayant les droits d’écriture dans le dépôt nixpkgs.

## Développement et intégration continue

Cette intégration de la distribution dans le dépôt git source permet également aux développeurs d’avoir un shell de développement comprenant automatiquement toutes les dépendances de pinocchio avec `nix develop` (qui peut s’activer tout seul en entrant dans le dossier grace à `nix-direnv`). Ils peuvent alors modifier n’importe quel fichier source et garder leur workflow habituel, par exemple classiquement lancer `cmake -B build $cmakeFlags && cmake --build build && cmake --build build -t test`, ou alors faire construire leur version modifiée du paquet par nix: `nix build`.

Dans le second cas, c’est exactement la même construction qui est lancée par la CI pour construire le projet et lancer ses tests unitaires. Nix offrant de fortes garanties d’isolation et de reproductibilité, si cela passe sur la machine de développement, cela passera dans la CI (à condition de rester sur le même type d’OS, comme linux ou darwin et la même architecture CPU, comme x86_64 ou arm64).

Pour gagner du temps et économiser des ressources (ce qui est très intéressant dans le cas de pinocchio puisqu’il est particulièrement gourmant à la construction), le développeur (auquel on aurait au préalable accordé notre confiance) peut directement pousser le paquet nix construit lors de son développement vers une cache binaire partagée par la CI, qui devient alors un cache-hit instantané, et est directement utilisable par les autres développeurs et utilisateurs, comme nous allons le voir dans le paragraphe suivant.

## Utilisation et déploiement continu

À partir du moment où cette technique est mise en place, chaque commit, chaque branche, chaque tag de chaque fork devient automatiquement un déploiement de pinocchio. Par exemple, pour lancer un interpréteur python comprenant le module pinocchio dans le tout dernier commit de la branche principale de développement, il suffit de lancer `nix run github:stack-of-tasks/pinocchio`. Ou pour intégrer la version d’un développeur tier dans un ensemble de logiciels pour tester, on peut ajouter à un flake une entrée `pinocchio.url = "github:OscarMrZ/pinocchio/omm/mjcf_contacts";`. Ou pour lancer un shell avec une version arbitraire de pinocchio disponible: `nix shell github:stack-of-tasts/pinocchio/v3.7.0`.

C’est particulièrement utile lorsque la version de développement d’un logiciel dépend d’une version de développement d’un autre logiciel. Prenons par exemple Humanoid Path Planner, un autre logiciel développé au sein de l’équipe Gepetto. HPP est un kit de développement logiciel composé de plusieurs paquets C++, ainsi que d’un paquet qui regroupe les bindings python pour tout le projet. Tous ces paquets sont actuellement dans la version 7.0.0, qui est encore fraiche. Dans <https://github.com/humanoid-path-planner/hpp-python/pull/118>, une modification est apportée au paquet hpp-manipulation, et les bindings python doivent être mis à jour en fonction. C’est relativement simple de faire des modifications dans plusieurs paquets à la fois pour un développeur. Mais pour le packaging, la distribution, et l’intégration continue ça ne facilite pas les choses. Pour rendre cette modification disponible dans les bindings python, une solution classique serait de faire une nouvelle release 7.1.0 de hpp-manipulation, d’intégrer cette release dans une distribution, puis de mettre à jour l’environnement utilisé par hpp-python pour utiliser la nouvelle verison de hpp-manipulation dans la nouvelle version de la distribution. Sachant que l’on a tendance à multiplier les canaux de distribution d’un même logiciel, il faudrait potentiellement faire ce travail 4 fois parallèlement (AUR + conda-forge + nix + robotpkg pour les distributions actuellement supportées, et PyPI + ROS ne devraient pas tarder à être ajoutés, et homebrew + vcpkgs seraient également intéressants).

Avec flakoboros, cette situation se résoud plus rapidement et souplement en indiquant au flake de hpp-python d’utiliser un overlay fourni par le flake de hpp-manipulation dans une version incluant les modifications nécessaires:

```diff
 {
   inputs = {
     flakoboros.url = "github:gepetto/flakoboros";
     flake-parts.follows = "flakoboros/flake-parts";
     nixpkgs.follows = "flakoboros/nixpkgs";
     systems.follows = "flakoboros/systems";
+
+    hpp-manipulation.url = "github:humanoid-path-planner/hpp-manipulation";
+    hpp-manipulation.inputs.flakoboros.follows = "flakoboros";
   };

   outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (
     { lib, ... }:
     {
       systems = import inputs.systems;
       imports = [
         inputs.flakoboros.flakeModule
         {
           flakoboros = {
+            overlays = [ inputs.hpp-manipulation.overlays.default ];
             pyOverrides.hpp-python = _: {
               src = lib.cleanSource ./.;
             };
           };
         }
       ];
     });
 }
```

Après cette modification, la CI de hpp-python utilise directement la dernière version de développement de hpp-manipulation qui a été mise en cache binaire par la CI de hpp-manipulation, puis construit automatiquement hpp-manipulation-urdf (qui se trouve dépendre de hpp-manipulation et être une dépendance de hpp-python), puis construit la version de hpp-python dont nous avons besoin.

NB: Dans les ecosystèmes `pip` ou `cargo`, on peut spécifier dans le système de construction qu’une dépendance doit être dans une version décrite par une url git particulière, plutôt que par un tag global de version. L’intégration de Nix et Flakoboros étend simplement cette fonctionnalité à tous les autres langages et ecosystèmes, y compris entre eux (on peut distribuer un paquet rust sur PyPI, mais pas spécifier à pip qu’une des dépendance du paquet rust doit avoir une source git particulière).

# ROS

TODO: distros, use data from source to generate distro, vendoring

# Workspaces

## Mono-repo

Il arrive parfois que dans un dépôt git on trouve plusieurs paquets logiciels. Cela peut-être le cas pour des logiciels ayant des composants dans plusieurs langages (par exemple une application web avec un backend en ruby et un frontend en typescript), et ce cas est théoriquement géré par flakoboros mais pas développé. Le cas qui nous intéresse plus est celui qui est dénommé `Workspace` par `cargo` et `uv` ou `méta-paquet` par `ROS`: plusieurs composants logiciels, généralement dans développés dans le même langage, sont synchronisés entre eux par un mono-repo git. Cela facilite leur développement (HPP pourrait bénéficier d’un passage à ce concept, par exemple), mais du point de vue de la distribution les paquets sont traités indépendaments, comme s’ils avaient des sources séparées.

TODO: catkin/colcon, agimus-franka-ros2

## Multi-repo

TODO: reprendre HPP + Makefile

Dans l’écosystème ROS, un `Workspace` est un dossier dans lequel on va cloner plusieurs dépôts de logiciels (qui peuvent éventuellement être eux-même des `méta-paquets`).

TODO: vcstool, rappel colcon


# Références

flakoboros: https://github.com/Gepetto/flakoboros
dolstra-2006: https://edolstra.github.io/pubs/phd-thesis.pdf
nixpkgs: https://github.com/NixOS/nixpkgs/
repology-graph: https://repology.org/repositories/graphs
pinocchio: https://github.com/stack-of-tasks/pinocchio/ https://hal.science/hal-01866228v2
