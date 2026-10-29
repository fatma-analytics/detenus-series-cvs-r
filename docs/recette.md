# Cahier de recette

Les contrôles automatiques sont dans `R/04_recette.R` ; leur résultat est écrit dans `output/recette.csv` à chaque exécution de la chaîne.

| # | Contrôle | Règle | Résultat actuel |
|---|---|---|---|
| 1 | Un seul enregistrement par mois | pas de date en double | OK |
| 2 | Effectifs plausibles | entre 40 000 et 100 000 | OK |
| 3 | Périodes désaisonnalisées continues | aucun mois manquant dans chaque période | OK |
| 4 | Série corrigée complète | aucune valeur manquante | OK |
| 5 | Cohérence de la décomposition | brut = corrigé + saisonnalité (+ effet samedis), à 1 % près | OK |
| 6 | Contrôle externe 2009-2019 | écart à l'Insee au 1er janvier ≤ 1 % | OK (écart nul) |
| 7 | Contrôle externe 2021-2025 | écart positif et < 2 %, expliqué par le champ | OK : +1 089 à +1 332 personnes, l'Insee exclut les collectivités d'outre-mer depuis 2021 |
| 8 | Sorties produites | 4 graphiques PNG | OK |

## Contrôles manuels à faire à chaque mise à jour

- Comparer le dernier mois avec la publication officielle (chiffres clés de la première page).
- Lire `data/clean/anomalies.csv` : toute nouvelle anomalie doit être expliquée.
- Vérifier visuellement les graphiques : pas de saut inexpliqué entre la série brute et la série corrigée.
- Vérifier que la publication se génère sans erreur (`publication/index.html`).
