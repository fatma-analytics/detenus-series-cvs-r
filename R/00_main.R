# =============================================================================
# 00_main.R
# Objectif : executer toute la chaine, dans l'ordre, depuis la racine du projet.
#   1. import et controle des series longues
#   2. desaisonnalisation X-13 (avec / sans regresseur samedis)
#   3. graphiques
#   4. recette automatique
#   5. rendu de la publication (Quarto si disponible, sinon R Markdown)
# Auteure  : Fatma Hammami
# =============================================================================

source("R/01_import_series_longues.R")
source("R/02_desaisonnalisation.R")
source("R/03_graphiques.R")
source("R/04_recette.R")

if (nzchar(Sys.which("quarto"))) {
  system("quarto render publication/publication.qmd --to html --output index.html")
} else {
  rmarkdown::render("publication/publication.qmd",
                    output_format = rmarkdown::html_document(self_contained = TRUE, theme = "cosmo"),
                    output_file = "index.html", quiet = TRUE)
}
message("Chaine terminee. Publication : publication/index.html")
