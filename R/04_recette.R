# =============================================================================
# 04_recette.R
# Objectif : verifier automatiquement les resultats de la chaine (recette).
# Entrees  : data/clean/*.csv, output/
# Sorties  : output/recette.csv (un controle par ligne, statut OK / A VERIFIER)
#            output/controle_insee.csv (comparaison au 1er janvier)
# Auteure  : Fatma Hammami
# =============================================================================

suppressPackageStartupMessages({ library(dplyr); library(readr); library(lubridate) })

serie <- read_csv("data/clean/serie_longue_detenus.csv", show_col_types = FALSE)
cvs   <- read_csv("data/clean/serie_cvs.csv", show_col_types = FALSE)
insee <- read_csv("data/clean/serie_annuelle_insee.csv", show_col_types = FALSE)

# Comparaison avec l'effectif au 1er janvier publie par l'Insee
controle_insee <- insee |>
  mutate(date = make_date(annee, 1, 1)) |>
  inner_join(select(serie, date, detenus), by = "date") |>
  mutate(ecart = detenus - detenus_1er_janvier, ecart_pct = round(100 * ecart / detenus_1er_janvier, 2))
write_csv(controle_insee, "output/controle_insee.csv")

avant <- filter(controle_insee, annee <= 2019)
apres <- filter(controle_insee, annee >= 2021)

controle <- function(nom, ok, detail = "") tibble(controle = nom, statut = if (isTRUE(ok)) "OK" else "A VERIFIER", detail = detail)

recette <- bind_rows(
  controle("Un seul enregistrement par mois", !any(duplicated(serie$date))),
  controle("Effectifs positifs et plausibles (40 000 - 100 000)", all(between(serie$detenus, 40000, 100000))),
  controle("Periodes desaisonnalisees sans mois manquant",
           all(tapply(cvs$date, cvs$periode, function(d) all(diff(d) <= 31)))),
  controle("Serie corrigee calculee pour chaque mois", !anyNA(cvs$corrige)),
  controle("Brut = corrige + saisonnalite (+ effet samedis) a 1 % pres",
           all(abs(cvs$detenus - cvs$corrige - cvs$saisonnalite) / cvs$detenus < 0.01)),
  controle("Ecart a l'Insee <= 1 % jusqu'en 2019", all(abs(avant$ecart_pct) <= 1),
           sprintf("ecart max %.2f %%", max(abs(avant$ecart_pct)))),
  # Depuis 2021, le champ Insee exclut les collectivites d'outre-mer (COM), que le
  # ministere inclut : on attend donc un ecart positif et limite (< 2 %).
  controle("Ecart a l'Insee depuis 2021 explique par le champ (0 a 2 %)",
           all(apres$ecart > 0 & apres$ecart_pct < 2),
           sprintf("ecart de %s a %s personnes : l'Insee exclut les collectivites d'outre-mer depuis 2021",
                   min(apres$ecart), max(apres$ecart))),
  controle("Graphiques produits", length(list.files("output/graphiques", "\\.png$")) == 4)
)

write_csv(recette, "output/recette.csv")
print(recette, width = Inf)
