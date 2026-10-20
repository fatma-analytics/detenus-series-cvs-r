# Désaisonnalisation et séries longues de la population détenue (R)

**Question posée :** comment interpréter correctement les évolutions mensuelles du nombre de détenus ?

![Brut vs CVS-CJO](output/graphiques/02_brut_vs_cvs_cjo.png)

Une publication HTML prête à consulter est disponible dans [`publication/index.html`](publication/index.html). La version Quarto est dans [`publication/publication.qmd`](publication/publication.qmd). Une version HTML directement consultable est fournie à la racine dans [`index.html`](index.html).

## Résultats actuels

La série mensuelle correctement extraite couvre janvier 2021 à décembre 2025. La série annuelle Insee permet de replacer le niveau dans une perspective 2000–2025. Le coefficient descriptif associé au nombre de samedis du mois précédent est de **529 détenus par samedi**, mais il n’est pas statistiquement significatif dans cette extraction (**p = 0,751**). Ce résultat est donc présenté comme un contrôle exploratoire, pas comme une preuve d’un effet causal.

## Méthode en quatre étapes

1. Les classeurs mensuels officiels du ministère sont conservés dans `data/raw/`, puis harmonisés dans `R/01_import_series_longues.R`.
2. Les mois manquants, doublons et variations atypiques sont consignés dans `data/clean/anomalies.csv`.
3. `R/02_desaisonnalisation.R` calcule le régresseur des samedis du mois précédent et tente un modèle X-13 avec outliers AO/LS ; un proxy STL est fourni pour rendre le dépôt consultable sans X-13.
4. `R/03_graphiques.R` produit quatre graphiques sobres et `publication/publication.qmd` constitue la note courte.

## Reproductibilité

Avec R installé :

```r
renv::restore()
source("R/00_main.R")
```

Pour le contrôle graphique déjà généré dans le dépôt :

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python build_project.py
```

## Sources

- [Ministère de la Justice — Statistiques mensuelles de la population détenue et écrouée](https://www.justice.gouv.fr/documentation/etudes-et-statistiques/statistiques-mensuelles-population-detenue-ecrouee-9)
- [Jeu data.gouv.fr — archive mensuelle](https://www.data.gouv.fr/datasets/statistique-mensuelle-de-la-population-ecrouee-et-detenue-en-france)
- [Insee — Administration pénitentiaire, données annuelles 2000–2025](https://www.insee.fr/fr/statistiques/2382579)

## Organisation

- `R/` : chaîne R complète ;
- `data/raw/` : fichiers officiels téléchargés sans modification ;
- `data/clean/` : séries harmonisées et contrôles ;
- `output/graphiques/` : quatre graphiques ;
- `publication/` : source Quarto et rendu HTML ;
- `docs/` : documentation et cahier de recette.

Les statistiques sont produites par le ministère de la Justice. Le dépôt contient une analyse reproductible et ne modifie pas les définitions officielles.
