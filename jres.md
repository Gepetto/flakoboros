# Introduction au packaging circulaire

Le logiciel commence généralement à l’état d’un dépôt de source (par exemple avec git), accompagné d’instructions de construction (par exemple avec cmake, uv ou cargo).

Pour faciliter son utilisation, il peut ensuite être empaqueté au sein d’un index (par exemple PyPI, npm ou hackage), et/ou d’une distribution logicielle (par exemple Debian, nixpkgs ou conda-forge).

Cet ordre des choses est naturellement perçu comme linéaire: on parle d’upstream ou de producer pour la source, et de downstream ou consumer pour la distribution.

Mais si on regarde de plus près, il est clair qu'avant même de commencer à développer, il y avait au préalable l’utilisation d’une distribution de logiciel, au moins pour la chaine de construction, et souvent pour les dépendances.

Il nous parait donc intéressant de refermer la boucle, et d’intégrer au mieux la distribution dans la source. Nous verrons que cela facilite à son tour l’intégration de la source dans la distribution dans une boucle vertueuse, et améliore plusieurs aspects du développement, de la maintenance et de l’utilisation des logiciels.

# Présentation de Flakoboros

Pour concrétiser ces idées, nous prendrons l’example de Flakoboros, une framework fondé sur le langage nix, son paradigme de flake, et sa distribution nixpkgs.

Flakoboros a pour objectif de fournir une implémentation de packaging circulaire afin de faciliter le développement, la maintenance et la distribution des logiciels produits et utilisés par le groupe de recherche en robotique Gepetto du LAAS-CNRS. Il s’agit donc principalement de gérer les écosystèmes C++ et python (bien que l’intégration de rust soit sérieusement à l’étude), ainsi que les différentes versions de la distribution ROS.

## Introduction (très rapide) à Nix

Nix (ref. dolstra-2006) est une implémentation du "Modèle de déploiement logiciel purement fonctionnel". Les paquets sont écrits dans un langage qui ressemble au json, mais où des fonctions permettent simplement de modifier toutes les données de la distribution.

Dans le cas présent, on s’intéresse au fait que chaque paquet logiciel ait un champ `src` pointant vers la source, qui peut être par exemple une URL HTTPS vers un tarball, ou un dépôt git sur un tag particulier, ou un chemin sur le sytème de fichier local.

NB: ces travaux ont été réalisés avec Nix, mais une implémentation basée sur Guix serait également certainement possible, puisque les deux projets partagent les fondations nécessaires à une concrétisation très simple du packaging circulaire.

L’un des avantages de Nix est sa distribution nixpkgs qui a une très bonne et très vaste couverture des différents langages de programmation et ecosystèmes logiciels, intègre une distribution linux (NixOS) et un support de MacOS, et est maintenue très à jour par de très nombreux contributeurs pratiquant sérieusement le peer-reviewing (ref. repology-graph).

## Example d’utilisation de Flakoboros avec Pinocchio

Pinocchio est un logiciel issu du groupe Gepetto du LAAS-CNRS (Toulouse) et aujourd’hui principalement développé par l’équipe Willow de l’INRIA (Paris), qui est packagé et distribué à travers plusieurs gestionnaires de paquets et distributions logicielles, et notamment nix et nixpkgs.

Refermer la boucle du packaging circulaire avec pinocchio consiste donc à inclure dans le dépôt source de pinocchio une extension du paquet pinocchio de nixpkgs qui défini simplement un override de la propriété `src` du paquet par l’état git courant.

En l’occurence, un fichier `flake.nix` comprenant par exemple:

```
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
          flakoboros.overrides.pinocchio = _: {
            src = lib.cleanSource ./.;
          };
        }
      ];
    });
}
```

# Bénéfices

Pour la maintenance de ce logiciel, il devient alors trivial de mettre à jour régulièrement et automatiquement le commit de l’entrée `nixpkgs` de ce flake (dans le fichier généré `flake.lock`), et valider que la version courante de pinocchio n’est pas cassée par une mise à jour de la chaine de compilation (par exemple GCC v14), du système de build (par exemple CMake v4), ou des dépendances (par exemple Eigen v5).

De la même manière, lors de la prochaine release de pinocchio (par exemple v4), la mise à jour du paquet pinocchio dans nixkpgs se passera sans encombres puisque cette intégration est testée en continu côté upstream. On pourra donc profiter du bot de mise à jour des paquets, qui pourra se contenter de mettre à jour le numéro de version et le hash du tarball correspondant, 

## Développement et intégration continue

Cette intégration de la distribution dans le dépôt git source permet également aux développeurs d’avoir un shell de développement comprenant automatiquement toutes les dépendances de pinocchio avec `nix develop` (ou automatiquement en entrant dans le dossier grace à nix-direnv). Ils peuvent alors modifier n’importe quel fichier source et classiquement lancer `cmake -B build $cmakeFlags && cmake --build build`, ou alors faire construire leur version modifiée du paquet par nix: `nix build`.

Dans le second cas, c’est exactement la même commande qui est lancée par la CI pour construire le projet et lancer ses tests unitaires. Nix offrant de fortes garanties d’isolation et de reproductibilité, si cela passe sur la machine de développement, cela passera dans la CI (à condition de rester sur le même type d’OS, comme linux ou darwin et la même architecture CPU, comme x86_64 ou arm64).

Pour gagner du temps (ce qui est très intéressant dans le cas de pinocchio qui demande énormément de ressources à la construction), le développeur (auquel on aurait au préalable accordé notre confiance) peut directement pousser le paquet nix construit dans une cache binaire partagée par la CI, qui devient alors un cache-hit instantané.

## Utilisation et déploiement continu

(je n’ai pas réussi à rédiger la suite, désolé :()


# Références

flakoboros: https://github.com/Gepetto/flakoboros
dolstra-2006: https://edolstra.github.io/pubs/phd-thesis.pdf
nixpkgs: https://github.com/NixOS/nixpkgs/
repology-graph: https://repology.org/repositories/graphs
pinocchio: https://github.com/stack-of-tasks/pinocchio/ https://hal.science/hal-01866228v2
