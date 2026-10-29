# =============================================================================
# 03_graphiques.R
# Objectif : produire les graphiques de la publication (ggplot2).
# Entrees  : data/clean/serie_cvs.csv, data/clean/serie_annuelle_insee.csv
# Sorties  : output/graphiques/01 a 04 (*.png)
# Auteure  : Fatma Hammami
# =============================================================================

suppressPackageStartupMessages({
  library(ggplot2); library(dplyr); library(readr); library(lubridate); library(scales); library(tidyr)
})

dir.create("output/graphiques", recursive = TRUE, showWarnings = FALSE)
x     <- read_csv("data/clean/serie_cvs.csv", show_col_types = FALSE)
insee <- read_csv("data/clean/serie_annuelle_insee.csv", show_col_types = FALSE) |>
  mutate(date = make_date(annee, 1, 1)) |> filter(annee >= 2008)

source_txt <- paste0("Source : ministère de la Justice (DAP-SSER), statistiques mensuelles de la population ",
                     "détenue et écrouée ; traitement F. Hammami.\nChamp : France (métropole et outre-mer), ",
                     "personnes écrouées détenues au 1er du mois.")
milliers <- label_number(big.mark = " ")
couleurs <- c("Brut" = "#8a94a6", "Corrigé" = "#1f4e79")

theme_pub <- theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"), plot.caption = element_text(hjust = 0, colour = "grey40", size = 8),
        panel.grid.minor = element_blank(), legend.position = "top", legend.justification = "left")
theme_set(theme_pub)
sauver <- function(nom, g, h = 4.6) ggsave(file.path("output/graphiques", nom), g, width = 9, height = h, dpi = 160, bg = "white")

# 1. Serie longue brute ---------------------------------------------------------
trou <- tibble(debut = ymd("2019-04-01"), fin = ymd("2020-12-01"))
g1 <- ggplot(x, aes(date, detenus)) +
  geom_rect(data = trou, aes(xmin = debut, xmax = fin, ymin = -Inf, ymax = Inf), inherit.aes = FALSE,
            fill = "grey92") +
  annotate("text", x = ymd("2020-02-01"), y = 86000, label = "Fichiers mensuels\nnon disponibles",
           size = 3, colour = "grey40") +
  geom_line(aes(group = periode), colour = "#1f4e79", linewidth = 0.7) +
  geom_point(data = insee, aes(date, detenus_1er_janvier), shape = 21, fill = "white", colour = "#d97904", size = 2) +
  scale_y_continuous(labels = milliers) +
  labs(title = "Nombre de personnes détenues au 1er du mois, 2008-2025",
       subtitle = "Ligne : série mensuelle reconstituée. Points : effectif au 1er janvier publié par l'Insee (contrôle).",
       x = NULL, y = "Personnes détenues", caption = source_txt)
sauver("01_serie_longue_brute.png", g1)

# 2. Brut et corrige, periode recente -------------------------------------------
recent <- x |> filter(periode == "2021-2025") |>
  select(date, Brut = detenus, `Corrigé` = corrige) |>
  pivot_longer(-date, names_to = "serie", values_to = "valeur")
g2 <- ggplot(recent, aes(date, valeur, colour = serie, linewidth = serie)) +
  geom_line() +
  scale_colour_manual(values = couleurs) + scale_linewidth_manual(values = c(0.6, 1)) +
  scale_y_continuous(labels = milliers) +
  labs(title = "Série brute et série corrigée (CVS-CJO), 2021-2025",
       subtitle = "Corrigée des variations saisonnières et de l'effet du nombre de samedis (X-13, méthode X-11)",
       x = NULL, y = "Personnes détenues", colour = NULL, linewidth = NULL, caption = source_txt)
sauver("02_brut_vs_corrige.png", g2)

# 3. Profil saisonnier ---------------------------------------------------------------
profil <- x |>
  # libelles en francais, independants de la langue du systeme
  mutate(mois = factor(month(date), 1:12, c("janv.", "févr.", "mars", "avr.", "mai", "juin",
                                             "juil.", "août", "sept.", "oct.", "nov.", "déc."))) |>
  group_by(periode, mois) |> summarise(coef = mean(saisonnalite), .groups = "drop")
g3 <- ggplot(profil, aes(mois, coef, fill = periode)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  geom_hline(yintercept = 0, colour = "grey30") +
  scale_fill_manual(values = c("2008-2019" = "#9db7d5", "2021-2025" = "#1f4e79")) +
  scale_y_continuous(labels = milliers) +
  labs(title = "Profil saisonnier : écart moyen au niveau corrigé, selon le mois",
       subtitle = "Effectif plus élevé au 1er juillet, plus bas au 1er septembre et au 1er janvier",
       x = "Effectif au 1er du mois de...", y = "Personnes", fill = NULL, caption = source_txt)
sauver("03_profil_saisonnier.png", g3)

# 4. Evolutions mensuelles brutes et corrigees (24 derniers mois) ----------------
evol <- x |> filter(date >= ymd("2024-01-01")) |>
  select(date, Brut = evol_brute, `Corrigé` = evol_corrigee) |>
  pivot_longer(-date, names_to = "serie", values_to = "evol")
g4 <- ggplot(evol, aes(date, evol, fill = serie)) +
  geom_col(position = position_dodge(width = 25), width = 24) +
  geom_hline(yintercept = 0, colour = "grey30") +
  scale_fill_manual(values = couleurs) +
  scale_x_date(date_breaks = "3 months", date_labels = "%m/%Y") +
  scale_y_continuous(labels = label_number(accuracy = 0.1, suffix = " %", decimal.mark = ",")) +
  labs(title = "Évolution mensuelle : brute et corrigée, 2024-2025",
       subtitle = "Au 1er août 2025, la baisse brute est saisonnière : la série corrigée est stable",
       x = NULL, y = "Évolution sur un mois", fill = NULL, caption = source_txt)
sauver("04_evolutions_mensuelles.png", g4)
