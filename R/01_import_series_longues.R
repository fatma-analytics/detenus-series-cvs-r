# Objectif: harmoniser les tableaux mensuels du ministère et contrôler la série.
# Entrées: classeurs Excel ministere_*.xlsx/xls dans data/raw/.
# Sorties: data/clean/serie_longue_detenus.csv et data/clean/anomalies.csv.
# Auteur: Fatma / Manus AI. Date: 2026-10-20.

suppressPackageStartupMessages({library(readxl); library(dplyr); library(stringr); library(lubridate); library(readr); library(purrr)})
raw_files <- list.files("data/raw", pattern="^ministere_.*\\.(xlsx|xls)$", full.names=TRUE)
parse_one <- function(path) {
  sheets <- excel_sheets(path)
  candidate <- purrr::keep(sheets, ~ grepl("Tab2|evolution|évolution", .x, ignore.case=TRUE))
  for (sheet in candidate) {
    x <- read_excel(path, sheet=sheet, col_names=FALSE)
    header <- which(apply(x, 1, function(z) any(tolower(trimws(as.character(z))) == "date") && any(grepl("déten|deten", tolower(as.character(z))))))[1]
    if (!is.na(header)) {
      names(x) <- make.unique(trimws(as.character(unlist(x[header, ]))))
      x <- x[(header+1):nrow(x), ]
      date_col <- names(x)[tolower(names(x)) == "date"][1]
      total_col <- names(x)[grepl("écroués détenus|ecroués detenus", names(x), ignore.case=TRUE)][1]
      if (!is.na(date_col) && !is.na(total_col)) return(tibble(date=as.Date(x[[date_col]]), detenus=as.numeric(x[[total_col]]), source=basename(path)))
    }
  }
  tibble()
}
serie <- purrr::map_dfr(raw_files, parse_one) |> filter(!is.na(date), !is.na(detenus)) |> distinct(date, .keep_all=TRUE) |> arrange(date)
anomalies <- tibble(type=character(), date=as.Date(character()), detail=character())
missing <- tibble(date=seq(min(serie$date), max(serie$date), by="month")) |> anti_join(serie, by="date") |> mutate(type="mois_manquant", detail="Absence de fichier ou tableau parsable")
duplicates <- serie |> count(date) |> filter(n > 1) |> transmute(type="doublon", date, detail=paste0(n, " valeurs"))
anomalies <- bind_rows(anomalies, missing, duplicates)
write_csv(serie, "data/clean/serie_longue_detenus.csv")
write_csv(anomalies, "data/clean/anomalies.csv")
