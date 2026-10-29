# =============================================================================
# 02_desaisonnalisation.R
# Objectif : desaisonnaliser la serie mensuelle du nombre de detenus avec
#            X-13-ARIMA-SEATS (methode X-11) et tester un effet calendaire :
#            le nombre de samedis du mois precedent.
# Entrees  : data/clean/serie_longue_detenus.csv
# Sorties  : data/clean/serie_cvs.csv          (brut, corrige, saisonnalite, evolutions)
#            output/comparaison_modeles.csv    (avec / sans regresseur samedis)
#            output/modeles_x13.txt            (sorties detaillees des modeles)
# Auteure  : Fatma Hammami
#
# Choix de methode
# - La serie publiee comporte un trou d'avril 2019 a decembre 2020 (fichiers
#   non disponibles, periode qui couvre aussi la crise sanitaire). Plutot que
#   d'imputer 21 mois, on desaisonnalise separement les deux periodes continues :
#   2008-2019 (135 mois) et 2021-2025 (60 mois).
# - Le stock est mesure au 1er du mois : ce sont les entrees et sorties du mois
#   precedent qui le font varier. Le regresseur est donc le nombre de samedis
#   du mois PRECEDENT.
# - Les effets calendaires usuels d'X-13 (jours ouvrables, Paques) sont concus
#   pour des flux ; ils sont desactives (regression.aictest = NULL) pour ne
#   tester que le regresseur samedis.
# - Le regresseur est conserve seulement s'il ameliore le modele (AICc plus bas).
#
# Remarque : le package seasonal installe automatiquement X-13 (x13binary).
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(lubridate); library(seasonal); library(purrr)
})

serie <- read_csv("data/clean/serie_longue_detenus.csv", show_col_types = FALSE)

# --- Regresseur : nombre de samedis du mois precedent ------------------------
nb_jours <- function(debut_mois, jour) {          # jour : 1 = lundi ... 6 = samedi
  vapply(debut_mois, function(m) {
    j <- seq(m, m %m+% months(1) - days(1), by = "day")
    sum(wday(j, week_start = 1) == jour)
  }, integer(1))
}
# On le calcule jusqu'en 2030 : X-13 a besoin du regresseur sur l'horizon de prevision
mois_reg <- seq(ymd("2007-01-01"), ymd("2030-12-01"), by = "month")
samedis_prec <- ts(nb_jours(mois_reg %m-% months(1), 6), start = c(2007, 1), frequency = 12)

# --- Periodes continues ---------------------------------------------------------
periodes <- list(
  "2008-2019" = c(ymd("2008-01-01"), ymd("2019-03-01")),
  "2021-2025" = c(ymd("2021-01-01"), ymd("2025-12-01"))
)

ajuster <- function(nom, bornes) {
  d <- serie |> filter(date >= bornes[1], date <= bornes[2]) |> arrange(date)
  stopifnot(all(diff(d$date) <= 31))                 # controle : pas de trou
  y <- ts(d$detenus, start = c(year(d$date[1]), month(d$date[1])), frequency = 12)

  sans <- seas(y, x11 = "", regression.aictest = NULL)
  avec <- seas(y, x11 = "", regression.aictest = NULL,
               xreg = samedis_prec, regression.usertype = "td")

  coef_sam <- coef(summary(avec))["xreg", ]
  garde <- udg(avec, "aicc") < udg(sans, "aicc")
  retenu <- if (garde) avec else sans

  list(
    comparaison = tibble(
      periode = nom, nb_mois = length(y),
      coef_samedis = coef_sam[["Estimate"]], ecart_type = coef_sam[["Std. Error"]],
      p_value = coef_sam[["Pr(>|z|)"]],
      aicc_sans = udg(sans, "aicc"), aicc_avec = udg(avec, "aicc"),
      modele_retenu = if (garde) "avec samedis (CVS-CJO)" else "sans samedis (CVS)",
      arima = udg(retenu, "arimamdl"),
      qs_saisonnalite_residuelle_p = unname(qs(retenu)["qssadj", "p-val"])
    ),
    serie = d |> transmute(
      date, periode = nom, detenus,
      corrige = as.numeric(final(retenu)),
      saisonnalite = as.numeric(series(retenu, "d10", verbose = FALSE)),
      type_correction = if (garde) "CVS-CJO" else "CVS"
    ),
    detail = list(sans = sans, avec = avec)
  )
}

res <- imap(periodes, ~ ajuster(.y, .x))

# --- Evolutions brutes et corrigees ---------------------------------------------
serie_cvs <- map_dfr(res, "serie") |>
  group_by(periode) |>
  mutate(evol_brute   = 100 * (detenus / lag(detenus) - 1),
         evol_corrigee = 100 * (corrige / lag(corrige) - 1)) |>
  ungroup()

comparaison <- map_dfr(res, "comparaison")

# --- Ecriture ---------------------------------------------------------------------
dir.create("output", showWarnings = FALSE)
write_csv(serie_cvs, "data/clean/serie_cvs.csv")
write_csv(comparaison, "output/comparaison_modeles.csv")

sink("output/modeles_x13.txt")
for (p in names(res)) {
  cat("\n=====================  Periode", p, " =====================\n")
  cat("\n--- Modele SANS regresseur samedis ---\n"); print(summary(res[[p]]$detail$sans))
  cat("\n--- Modele AVEC regresseur samedis du mois precedent ---\n"); print(summary(res[[p]]$detail$avec))
}
sink()

print(comparaison |> mutate(across(where(is.numeric), ~ round(.x, 3))), width = Inf)
