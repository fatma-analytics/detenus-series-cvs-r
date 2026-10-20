# Objectif: exécuter toute la chaîne d'import, désaisonnalisation et graphiques.
# Entrées: data/raw/, data/source/. Sorties: data/clean/, output/graphiques/.
# Auteur: Fatma / Manus AI. Date: 2026-10-20.
source("R/01_import_series_longues.R")
source("R/02_desaisonnalisation.R")
source("R/03_graphiques.R")
