# Documentation de la chaîne de traitement

## Vue d'ensemble

| Étape | Script | Entrées | Sorties |
|---|---|---|---|
| 1. Séries longues et contrôles | `R/01_import_series_longues.R` | `data/raw/*.xls(x)`, `data/source/insee_admin_penitentiaire.xlsx` | `data/clean/serie_longue_detenus.csv`, `revisions.csv`, `anomalies.csv`, `serie_annuelle_insee.csv` |
| 2. Désaisonnalisation | `R/02_desaisonnalisation.R` | `serie_longue_detenus.csv` | `data/clean/serie_cvs.csv`, `output/comparaison_modeles.csv`, `output/modeles_x13.txt` |
| 3. Graphiques | `R/03_graphiques.R` | `serie_cvs.csv`, `serie_annuelle_insee.csv` | `output/graphiques/*.png` |
| 4. Recette | `R/04_recette.R` | fichiers ci-dessus | `output/recette.csv`, `output/controle_insee.csv` |
| 5. Publication | `publication/publication.qmd` | fichiers ci-dessus | `publication/index.html` |

`R/00_main.R` enchaîne les cinq étapes.

## 1. Constitution des séries longues

- Chaque publication mensuelle contient un « Tableau 2 » : l'évolution mensuelle sur deux ans. En combinant les publications, on reconstitue une série continue, même quand certains mois de publication manquent.
- **Deux formats** coexistent :
  - jusqu'en 2019 (DAP) : colonne de date en texte (« décembre 2014 »), colonnes Prévenus, Condamnés, Ensemble ;
  - depuis 2021 (GENESIS, DAP-SSER) : colonne Date, colonnes PR, CP, CO, Écroués détenus.
- **Millésimes :** un même mois apparaît dans plusieurs publications. On garde la publication la plus récente. Les révisions sont rares (2 mois, écart maximum de 10 personnes) et consignées dans `revisions.csv`.
- **Rupture de nomenclature :** les condamnés-prévenus (CP), auparavant comptés surtout parmi les prévenus, sont isolés depuis 2020-2021. Le total reste comparable ; la ventilation prévenus / condamnés ne l'est pas sans raccord.
- **Trou :** avril 2019 à décembre 2020. Les publications correspondantes ne sont pas dans `data/raw/`. Les publications de 2020 ou de début 2021, dont le tableau couvre deux ans, suffiraient à combler le trou.

## 2. Désaisonnalisation

- **Méthode :** X-13-ARIMA-SEATS, décomposition X-11 (package `seasonal`), modèle additif (pas de transformation log retenue automatiquement), détection automatique des points aberrants.
- **Effets calendaires :** les régresseurs standards (jours ouvrables, Pâques) sont conçus pour des flux ; ils sont désactivés. On teste un seul régresseur : le **nombre de samedis du mois précédent**, car le stock au 1er du mois résulte des entrées et sorties du mois précédent.
- **Choix du modèle :** le régresseur est conservé s'il diminue l'AICc. Résultat : non retenu sur 2008-2019, retenu sur 2021-2025 (gain d'AICc très faible, p = 0,075).
- **Deux périodes séparées :** 2008-01 à 2019-03 (135 mois) et 2021-01 à 2025-12 (60 mois). Imputer 21 mois couvrant la crise sanitaire aurait faussé l'estimation de la saisonnalité.
- **Diagnostics :** pas de saisonnalité résiduelle (test QS) ; détail complet dans `output/modeles_x13.txt`.

## 3. Mise à jour mensuelle

1. Télécharger la nouvelle publication sur justice.gouv.fr et l'enregistrer dans `data/raw/` sous le nom `ministere_AAAA-MM.xlsx`.
2. Lancer `source("R/00_main.R")` depuis la racine du projet.
3. Lire `output/recette.csv` : tous les contrôles doivent être « OK ».
4. Lire `data/clean/anomalies.csv` et `revisions.csv` : toute nouvelle révision ou variation supérieure à 3 % doit être expliquée.
5. Vérifier que les coefficients saisonniers et l'effet samedis restent stables (`output/comparaison_modeles.csv`) : de fortes révisions signalent un problème.
