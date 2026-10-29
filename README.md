# Désaisonnalisation et séries longues de la population détenue (R)

**Question posée :** comment interpréter correctement les évolutions mensuelles du nombre de personnes détenues ?

📄 **Publication :** [`publication/index.html`](publication/index.html) (note de 2 pages, rendue depuis [`publication.qmd`](publication/publication.qmd))

![Évolutions mensuelles brutes et corrigées](output/graphiques/04_evolutions_mensuelles.png)

## Résultats

- **Série longue reconstituée :** 195 mois, de janvier 2008 à décembre 2025, à partir de 134 publications mensuelles officielles. Il manque avril 2019 à décembre 2020 (fichiers non disponibles dans le dépôt).
- **Saisonnalité marquée :** l'effectif au 1er du mois est plus élevé en juillet et plus bas en septembre et en janvier. Sur 2021-2025, l'écart moyen entre ces mois atteint environ 1 100 personnes.
- **La lecture change :** au 1er août 2025, l'effectif brut baisse de 0,9 %, mais la série corrigée est stable (+0,0 %). La baisse est saisonnière.
- **Effet « samedis » faible :** le nombre de samedis du mois précédent n'est pas significatif sur 2008-2019 (p = 0,78). Sur 2021-2025, il est à la limite de la significativité (+64 personnes par samedi, p = 0,075, moins de 0,1 % de l'effectif) et améliore très légèrement l'AICc : il est conservé pour cette période.
- **Contrôle externe :** jusqu'en 2019, la série est identique à l'effectif au 1er janvier publié par l'Insee. Depuis 2021, elle le dépasse de 1 089 à 1 332 personnes, car l'Insee exclut les collectivités d'outre-mer.

## Méthode

1. **Séries longues** ([`01_import_series_longues.R`](R/01_import_series_longues.R)) : chaque publication contient un tableau sur deux ans. Le script lit les deux formats de fichiers (ancien format DAP jusqu'en 2019, format GENESIS depuis 2021), garde la valeur de la publication la plus récente pour chaque mois et consigne les révisions.
2. **Contrôles qualité** ([`anomalies.csv`](data/clean/anomalies.csv)) : mois manquants, révisions entre publications, variations supérieures à 3 %, total différent de la somme des catégories, changement de nomenclature (condamnés-prévenus isolés depuis 2020-2021).
3. **Désaisonnalisation** ([`02_desaisonnalisation.R`](R/02_desaisonnalisation.R)) : X-13-ARIMA-SEATS, méthode X-11, avec le package `seasonal`. Comparaison d'un modèle sans et avec régresseur « nombre de samedis du mois précédent » (le stock est mesuré au 1er du mois). Les deux périodes continues sont traitées séparément, sans imputer le trou de 2019-2020.
4. **Graphiques et publication** ([`03_graphiques.R`](R/03_graphiques.R), [`publication.qmd`](publication/publication.qmd)) : 4 graphiques `ggplot2` avec source et champ, et une note courte.
5. **Recette automatique** ([`04_recette.R`](R/04_recette.R)) : 8 contrôles (doublons, cohérence brut = corrigé + saisonnalité, comparaison à l'Insee...), résultats dans [`output/recette.csv`](output/recette.csv).

## Reproduire

Avec R (≥ 4.1) :

```r
install.packages(c("dplyr", "tidyr", "readr", "readxl", "stringr", "lubridate",
                   "purrr", "ggplot2", "scales", "seasonal", "rmarkdown"))
source("R/00_main.R")   # lance toute la chaîne depuis la racine du projet
```

`seasonal` installe automatiquement le programme X-13 (package `x13binary`). Pour mettre la série à jour, il suffit d'ajouter la nouvelle publication mensuelle dans `data/raw/` et de relancer `R/00_main.R` : voir [`docs/documentation_chaine.md`](docs/documentation_chaine.md).

## Organisation

```
R/                 00_main.R (chaîne complète), 01 import, 02 désaisonnalisation, 03 graphiques, 04 recette
data/raw/          publications mensuelles officielles, non modifiées (+ manifest.json : URL de chaque fichier)
data/source/       série annuelle Insee
data/clean/        séries harmonisées, révisions, anomalies
output/            graphiques, comparaison des modèles, sorties X-13, recette
publication/       note Quarto et rendu HTML
docs/              documentation de la chaîne et cahier de recette
```

## Limites et prolongements

- Compléter 2019-2020 avec les publications manquantes, puis modéliser la crise sanitaire par des points aberrants (changement de niveau).
- Comparer avec JDemetra+ (`rjd3x13`, `rjd3tramoseats`).
- Tester l'effet calendaire sur les flux d'entrées et de sorties, où il devrait être plus net que sur le stock.

## Sources

- [Ministère de la Justice : statistiques mensuelles de la population détenue et écrouée](https://www.justice.gouv.fr/documentation/etudes-et-statistiques/statistiques-mensuelles-population-detenue-ecrouee-9)
- [data.gouv.fr : archive mensuelle](https://www.data.gouv.fr/datasets/statistique-mensuelle-de-la-population-ecrouee-et-detenue-en-france)
- [Insee : administration pénitentiaire, données annuelles](https://www.insee.fr/fr/statistiques/2382579)

Les statistiques sont produites par le ministère de la Justice. Ce dépôt propose une analyse reproductible et ne modifie pas les définitions officielles.
