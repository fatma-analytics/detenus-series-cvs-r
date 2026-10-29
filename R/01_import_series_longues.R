# =============================================================================
# 01_import_series_longues.R
# Objectif : reconstituer la serie mensuelle longue du nombre de personnes
#            ecrouees detenues (au 1er du mois) a partir des classeurs
#            mensuels du ministere de la Justice, puis la controler.
# Entrees  : data/raw/*.xls, data/raw/*.xlsx (fichiers officiels non modifies)
#            data/source/insee_admin_penitentiaire.xlsx (serie annuelle Insee)
# Sorties  : data/clean/serie_longue_detenus.csv  (une ligne par mois)
#            data/clean/revisions.csv            (ecarts entre millesimes)
#            data/clean/anomalies.csv            (journal des controles)
#            data/clean/serie_annuelle_insee.csv (controle au 1er janvier)
# Auteure  : Fatma Hammami
# =============================================================================

suppressPackageStartupMessages({
  library(readxl); library(dplyr); library(tidyr); library(stringr)
  library(lubridate); library(readr); library(purrr)
})

# --- Outils -------------------------------------------------------------------

# Normalise un texte : minuscules, sans accents, espaces reduits
normaliser <- function(x) {
  x <- stringi::stri_trans_general(as.character(x), "Latin-ASCII")
  str_squish(tolower(x))
}

mois_fr <- c(janvier = 1, fevrier = 2, mars = 3, avril = 4, mai = 5, juin = 6,
             juillet = 7, aout = 8, septembre = 9, octobre = 10,
             novembre = 11, decembre = 12)

# Convertit une cellule de date en Date, quel que soit le format du fichier :
# "decembre 2014" (anciens fichiers), "2021-01-01" ou numero de serie Excel
lire_date <- function(x) {
  x <- normaliser(x)
  out <- as.Date(rep(NA_character_, length(x)))
  # Format texte "mois annee"
  m <- str_match(x, "^(\\p{L}+) (\\d{4})$")
  ok <- !is.na(m[, 1]) & m[, 2] %in% names(mois_fr)
  out[ok] <- make_date(as.integer(m[ok, 3]), mois_fr[m[ok, 2]], 1)
  # Format ISO
  iso <- is.na(out) & str_detect(x, "^\\d{4}-\\d{2}-\\d{2}")
  out[iso] <- as.Date(substr(x[iso], 1, 10))
  # Numero de serie Excel
  num <- is.na(out) & str_detect(x, "^\\d{5}(\\.0+)?$")
  out[num] <- as.Date(as.numeric(x[num]), origin = "1899-12-30")
  out
}

lire_nombre <- function(x) suppressWarnings(as.numeric(str_replace_all(x, "[\\s ]", "")))

# Millesime d'un fichier = mois de reference de la publication
millesime <- function(path) {
  f <- basename(path)
  if (str_detect(f, "^ministere_\\d{4}-\\d{2}")) return(ym(str_extract(f, "\\d{4}-\\d{2}")))
  if (str_detect(f, "^statistique_\\d{8}")) return(dmy(str_extract(f, "\\d{8}")))
  NA
}

# Lit le "Tableau 2" (evolution mensuelle sur deux ans) d'un classeur
lire_tableau2 <- function(path) {
  feuilles <- excel_sheets(path)
  feuille <- feuilles[str_detect(normaliser(feuilles), "^tab ?2($|[^0-9])")][1]
  if (is.na(feuille)) return(NULL)

  x <- suppressMessages(read_excel(path, sheet = feuille, col_names = FALSE,
                                   col_types = "text", .name_repair = "minimal"))
  m <- apply(as.matrix(x), 2, normaliser)

  # Ligne d'en-tete : contient "date" ou "situation au 1er du mois"
  entete <- which(apply(m, 1, function(r) any(r %in% "date" | str_detect(r, "^situation au 1er"), na.rm = TRUE)))[1]
  if (is.na(entete)) return(NULL)
  h <- m[entete, ]
  col_date  <- which(h == "date" | str_detect(h, "^situation au 1er"))[1]
  col_total <- which(h %in% c("ensemble", "ecroues detenus"))[1]
  if (is.na(col_total)) return(NULL)

  corps <- x[(entete + 1):nrow(x), , drop = FALSE]
  col <- function(nom) { j <- which(h == nom)[1]; if (is.na(j)) NA_real_ else lire_nombre(corps[[j]]) }

  tibble(
    date      = lire_date(corps[[col_date]]),
    detenus   = lire_nombre(corps[[col_total]]),
    # Ancien format (jusqu'en 2019) : prevenus / condamnes
    prevenus  = col("prevenus"),
    condamnes = col("condamnes"),
    # Nouveau format GENESIS (a partir de 2021) : PR / CP / CO
    pr = col("pr"), cp = col("cp"), co = col("co"),
    format    = if ("ensemble" %in% h) "ancien (DAP)" else "GENESIS",
    fichier   = basename(path),
    millesime = millesime(path)
  ) |>
    filter(!is.na(date), !is.na(detenus))
}

# --- 1. Lecture de tous les fichiers -------------------------------------------

fichiers <- list.files("data/raw", pattern = "\\.(xls|xlsx)$", full.names = TRUE)
toutes <- map_dfr(fichiers, lire_tableau2)
non_lus <- setdiff(basename(fichiers), unique(toutes$fichier))

message(length(fichiers), " fichiers, ", n_distinct(toutes$fichier), " lus, ",
        nrow(toutes), " observations (avec recouvrements)")

# --- 2. Revisions : un meme mois publie dans plusieurs fichiers ----------------

revisions <- toutes |>
  group_by(date) |>
  summarise(nb_millesimes = n(),
            min = min(detenus), max = max(detenus),
            ecart = max - min, .groups = "drop") |>
  filter(ecart > 0)

# --- 3. Serie finale : on garde le millesime le plus recent ---------------------

serie <- toutes |>
  group_by(date) |>
  slice_max(millesime, n = 1, with_ties = FALSE) |>
  ungroup() |>
  arrange(date) |>
  mutate(variation_mensuelle = 100 * (detenus / lag(detenus) - 1),
         ecart_mois = interval(lag(date), date) %/% months(1))

# --- 4. Controles qualite -------------------------------------------------------

tous_mois <- tibble(date = seq(min(serie$date), max(serie$date), by = "month"))
manquants <- anti_join(tous_mois, serie, by = "date")

controle_somme <- serie |>
  mutate(somme = if_else(format == "GENESIS", pr + cp + co, prevenus + condamnes)) |>
  filter(!is.na(somme), somme != detenus)

anomalies <- bind_rows(
  tibble(controle = "Fichier sans tableau 2 lisible", date = as.Date(NA), detail = non_lus),
  tibble(controle = "Mois manquant", date = manquants$date,
         detail = "Absent de tous les fichiers disponibles"),
  tibble(controle = "Revision entre millesimes", date = revisions$date,
         detail = paste0("ecart de ", revisions$ecart, " personnes entre ",
                         revisions$nb_millesimes, " publications")),
  serie |> filter(abs(variation_mensuelle) > 3, ecart_mois == 1) |>
    transmute(controle = "Variation mensuelle > 3 %", date,
              detail = sprintf("%+.1f %%", variation_mensuelle)),
  tibble(controle = "Total different de la somme des categories",
         date = controle_somme$date,
         detail = paste("ecart", controle_somme$detenus - controle_somme$somme)),
  tibble(controle = "Changement de nomenclature", date = min(serie$date[serie$format == "GENESIS"]),
         detail = paste("Passage de prevenus/condamnes a PR/CP/CO (source GENESIS). Les condamnes-prevenus (CP),",
                        "auparavant comptes surtout parmi les prevenus, sont isoles : total comparable,",
                        "ventilation non comparable sans raccord"))
)

# --- 5. Ecriture ------------------------------------------------------------------

dir.create("data/clean", showWarnings = FALSE, recursive = TRUE)
serie |>
  select(date, detenus, prevenus, condamnes, pr, cp, co, format, fichier) |>
  write_csv("data/clean/serie_longue_detenus.csv", na = "")
write_csv(revisions, "data/clean/revisions.csv")
write_csv(anomalies, "data/clean/anomalies.csv", na = "")

# --- 6. Serie annuelle Insee (controle au 1er janvier) ---------------------------
# Insee, "Administration penitentiaire : milieu ferme", ligne "Personnes detenues"
insee_brut <- suppressMessages(read_excel("data/source/insee_admin_penitentiaire.xlsx",
                                          sheet = "Figure 1", col_names = FALSE, col_types = "text"))
ligne_annees <- which(normaliser(insee_brut[[1]]) == "intitule")[1]
ligne_detenus <- which(normaliser(insee_brut[[1]]) == "personnes detenues")[1]
tibble(annee = as.integer(str_extract(unlist(insee_brut[ligne_annees, -1]), "\\d{4}")),
       detenus_1er_janvier = lire_nombre(unlist(insee_brut[ligne_detenus, -1]))) |>
  filter(!is.na(annee), !is.na(detenus_1er_janvier)) |>
  write_csv("data/clean/serie_annuelle_insee.csv")

message("Serie : ", format(min(serie$date), "%m/%Y"), " - ", format(max(serie$date), "%m/%Y"),
        " | ", nrow(serie), " mois | ", nrow(manquants), " mois manquants | ",
        nrow(revisions), " mois revises")
