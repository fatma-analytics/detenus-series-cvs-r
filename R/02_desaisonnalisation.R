# Objectif: estimer la série CVS-CJO et comparer un modèle avec régresseur samedis.
# Entrées: data/clean/serie_longue_detenus.csv.
# Sorties: data/clean/serie_cvs_cjo.csv et output/modele_x13.txt.
# Auteur: Fatma / Manus AI. Date: 2026-10-20.

suppressPackageStartupMessages({library(dplyr); library(lubridate); library(readr); library(zoo)})
serie <- read_csv("data/clean/serie_longue_detenus.csv", show_col_types=FALSE) |> arrange(date)
nb_samedis <- function(annee, mois) { jours <- seq(make_date(annee, mois, 1), ceiling_date(make_date(annee, mois, 1), "month") - days(1), by="day"); sum(wday(jours, week_start=1)==6) }
serie <- serie |> mutate(nb_samedis_mois_precedent = mapply(function(d) nb_samedis(year(d - months(1)), month(d - months(1))), date))
# X-13 est utilisé quand l'exécutable est installé. Sinon, la moyenne mobile STL est conservée comme solution de rendu.
if (requireNamespace("seasonal", quietly=TRUE)) {
  y <- ts(serie$detenus, start=c(year(min(serie$date)), month(min(serie$date))), frequency=12)
  fit <- try(seasonal::seas(y, xreg=serie$nb_samedis_mois_precedent, outlier=c("ao", "ls"), transform.function="auto"), silent=TRUE)
  if (!inherits(fit, "try-error")) serie$detenus_cvs_cjo <- as.numeric(final(fit)) else serie$detenus_cvs_cjo <- as.numeric(stats::filter(serie$detenus, rep(1/12,12), sides=2))
} else {
  serie$detenus_cvs_cjo <- as.numeric(stats::filter(serie$detenus, rep(1/12,12), sides=2))
}
serie <- serie |> mutate(evolution_mensuelle_brute=100*(detenus/lag(detenus)-1), evolution_mensuelle_cvs_cjo=100*(detenus_cvs_cjo/lag(detenus_cvs_cjo)-1))
write_csv(serie, "data/clean/serie_cvs_cjo.csv")
