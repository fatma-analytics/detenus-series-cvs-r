# Documentation de la chaîne

La chaîne part des classeurs officiels mensuels du ministère de la Justice conservés dans `data/raw/`. Le script `01_import_series_longues.R` repère le tableau d’évolution mensuelle, harmonise la date et le nombre de personnes détenues, puis produit `serie_longue_detenus.csv` et un journal des anomalies.

Le périmètre mensuel correctement parsable dans cette version couvre janvier 2021 à décembre 2025. La série annuelle Insee couvre 2000–2025 et sert de contrôle de niveau au 1er janvier. Les périmètres doivent rester séparés : le ministère mensuel est France métropolitaine et outre-mer, tandis que le champ Insee évolue selon les années.

`02_desaisonnalisation.R` calcule le nombre de samedis du mois précédent. Il tente un modèle X-13 via `seasonal`, avec régressseur externe et outliers AO/LS autour de la rupture Covid. Si X-13 n’est pas installé, il utilise une moyenne mobile pour permettre un rendu reproductible, en le signalant dans les résultats. Le coefficient descriptif calculé sur la base 2021–2025 n’est pas significatif dans cette extraction : il doit être ré-estimé et interprété avec prudence.

Pour mettre à jour la série, déposer les nouveaux fichiers dans `data/raw/`, lancer `R/00_main.R`, comparer les nouveaux contrôles Insee/Justice, vérifier `data/clean/anomalies.csv`, puis régénérer la publication.
