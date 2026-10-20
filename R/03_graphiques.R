# Objectif: produire les graphiques de la publication.
# Entrées: data/clean/serie_cvs_cjo.csv.
# Sorties: output/graphiques/*.png.
# Auteur: Fatma / Manus AI. Date: 2026-10-20.

suppressPackageStartupMessages({library(ggplot2); library(readr); library(dplyr); library(scales)})
dir.create("output/graphiques", recursive=TRUE, showWarnings=FALSE)
x <- read_csv("data/clean/serie_cvs_cjo.csv", show_col_types=FALSE)
theme_set(theme_minimal(base_size=11))
ggsave("output/graphiques/01_serie_longue_brute.png", ggplot(x, aes(date, detenus)) + geom_line(color="#1f4e79", linewidth=0.8) + scale_y_continuous(labels=label_number(big.mark=" ")) + labs(title="Population détenue au 1er du mois", x=NULL, y="Personnes"), width=10, height=4.8, dpi=180)
ggsave("output/graphiques/02_brut_vs_cvs_cjo.png", ggplot(x, aes(date)) + geom_line(aes(y=detenus, colour="Brut")) + geom_line(aes(y=detenus_cvs_cjo, colour="CVS-CJO"), linewidth=1) + scale_colour_manual(values=c(Brut="#6b7280", `CVS-CJO`="#d97904")) + labs(title="Série brute et série corrigée", x=NULL, y="Personnes", colour=NULL), width=10, height=4.8, dpi=180)
ggsave("output/graphiques/03_effet_samedis.png", ggplot(x, aes(nb_samedis_mois_precedent, detenus)) + geom_point(color="#1f4e79") + geom_smooth(method="lm", se=FALSE, color="#b23a48") + labs(title="Samedis du mois précédent et stock détenu", x="Nombre de samedis", y="Personnes"), width=8, height=4.8, dpi=180)
ggsave("output/graphiques/04_evolutions_mensuelles.png", ggplot(x, aes(date)) + geom_hline(yintercept=0) + geom_line(aes(y=evolution_mensuelle_brute, colour="Brut")) + geom_line(aes(y=evolution_mensuelle_cvs_cjo, colour="CVS-CJO")) + labs(title="Évolutions mensuelles", x=NULL, y="%", colour=NULL), width=10, height=4.8, dpi=180)
