user_library <- file.path(
  Sys.getenv("USERPROFILE"),
  "Documents",
  "R",
  "win-library",
  paste0(R.version$major, ".", R.version$minor)
)
if (Sys.getenv("USERPROFILE") != "" && dir.exists(user_library)) {
  .libPaths(c(user_library, .libPaths()))
}

required_packages <- c("tidyverse", "scales", "jsonlite")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop("Missing R packages: ", paste(missing_packages, collapse = ", "), call. = FALSE)
}

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(jsonlite)
})

detect_project_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) == 1) {
    script_path <- normalizePath(sub("^--file=", "", file_arg), winslash = "/", mustWork = TRUE)
    return(normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE))
  }
  normalizePath(getwd(), winslash = "/", mustWork = TRUE)
}

project_root <- detect_project_root()
processed_dir <- file.path(project_root, "data", "processed")
figures_dir <- file.path(project_root, "figures")

anatomy <- read_csv(file.path(processed_dir, "occupation_wage_anatomy.csv"), show_col_types = FALSE)
access_anatomy <- read_csv(file.path(processed_dir, "occupation_access_anatomy.csv"), show_col_types = FALSE)
theil_summary <- fromJSON(file.path(processed_dir, "inequality_decomposition_theil.json"))

format_brl_axis <- label_currency(prefix = "R$ ", big.mark = ".", decimal.mark = ",", accuracy = 1)

type_palette <- c(
  "elite_estavel" = "#14b8a6",
  "elite_de_cauda_longa" = "#eab308",
  "teto_alto_base_distante" = "#8b5cf6",
  "renda_baixa_comprimida" = "#64748b",
  "topo_instavel_amostra_pequena" = "#ef4444",
  "meio_heterogeneo" = "#334155"
)

type_labels <- c(
  "elite_estavel" = "elite estavel",
  "elite_de_cauda_longa" = "elite de cauda longa",
  "teto_alto_base_distante" = "teto alto distante",
  "renda_baixa_comprimida" = "baixa renda comprimida",
  "topo_instavel_amostra_pequena" = "estimativa instavel",
  "meio_heterogeneo" = "meio heterogeneo"
)

theme_set(theme_minimal(base_size = 12))

anatomy_map <- anatomy %>%
  ggplot(aes(x = p50, y = mean_median_ratio, size = workers, color = wage_anatomy_type)) +
  geom_hline(yintercept = 1.4, linetype = "dashed", color = "grey70") +
  geom_vline(xintercept = median(anatomy$p50, na.rm = TRUE), linetype = "dashed", color = "grey70") +
  geom_point(alpha = 0.78) +
  scale_x_continuous(labels = format_brl_axis) +
  scale_size_continuous(range = c(1.5, 12), labels = label_number(big.mark = ".", decimal.mark = ",")) +
  scale_color_manual(values = type_palette, labels = type_labels) +
  labs(
    title = "Mapa anatomico dos salarios por ocupacao",
    subtitle = "Eixo X: renda tipica (mediana). Eixo Y: quanto a media se afasta da mediana.",
    x = "Mediana ponderada do rendimento mensal habitual",
    y = "Media / mediana",
    color = "Tipo salarial",
    size = "Trabalhadores estimados",
    caption = "Fonte: PNAD Continua/IBGE 1T2026. Ocupacoes com n >= 120. Analise descritiva."
  ) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank(), plot.title.position = "plot") +
  guides(color = guide_legend(ncol = 2, override.aes = list(size = 4)), size = guide_legend(nrow = 1))

ggsave(file.path(figures_dir, "wage_anatomy_map.png"), anatomy_map, width = 13.5, height = 8.2, dpi = 180)

selected <- anatomy %>%
  filter(
    occupation %in% c("1120", "2212", "2611", "2512", "2310", "7533") |
      wage_anatomy_type %in% c("elite_estavel", "elite_de_cauda_longa", "teto_alto_base_distante")
  ) %>%
  arrange(desc(mean_income)) %>%
  slice_head(n = 14) %>%
  mutate(occupation_short = fct_reorder(str_wrap(occupation_label, 42), p50))

distribution_ladder <- selected %>%
  ggplot(aes(y = occupation_short)) +
  geom_segment(aes(x = p10, xend = p90, yend = occupation_short), color = "grey70", linewidth = 1.1) +
  geom_point(aes(x = p50), color = "#14b8a6", size = 3) +
  geom_point(aes(x = mean_income), color = "#eab308", size = 3) +
  scale_x_continuous(labels = format_brl_axis) +
  labs(
    title = "A escada salarial por dentro",
    subtitle = "Linha: P10 a P90. Verde: mediana. Dourado: media.",
    x = "Rendimento mensal habitual",
    y = NULL,
    caption = "Fonte: PNAD Continua/IBGE 1T2026. Analise descritiva."
  ) +
  theme(panel.grid.minor = element_blank(), plot.title.position = "plot")

ggsave(file.path(figures_dir, "distribution_ladder_selected_occupations.png"), distribution_ladder, width = 12, height = 8, dpi = 180)

access_gap <- access_anatomy %>%
  filter(!is.na(gender_gap_women_vs_men), sample_n >= 180) %>%
  ggplot(aes(x = share_Mulher, y = gender_gap_women_vs_men, size = workers, color = p50)) +
  geom_hline(yintercept = 0, color = "grey75") +
  geom_vline(xintercept = 0.5, color = "grey75", linetype = "dashed") +
  geom_point(alpha = 0.75) +
  scale_x_continuous(labels = percent) +
  scale_y_continuous(labels = percent) +
  scale_color_gradient(low = "#64748b", high = "#eab308", labels = format_brl_axis) +
  scale_size_continuous(range = c(1.5, 10), labels = label_number(big.mark = ".", decimal.mark = ",")) +
  labs(
    title = "Acesso nao e o mesmo que paridade de rendimento",
    subtitle = "Cada ponto e uma ocupacao. X: participacao feminina. Y: gap medio mulher vs homem.",
    x = "Participacao feminina estimada",
    y = "Gap medio mulher vs homem",
    color = "Mediana",
    size = "Trabalhadores",
    caption = "Fonte: PNAD Continua/IBGE 1T2026. Ocupacoes com n >= 180. Analise descritiva."
  ) +
  theme(panel.grid.minor = element_blank(), plot.title.position = "plot", legend.position = "bottom")

ggsave(file.path(figures_dir, "access_vs_internal_gender_gap.png"), access_gap, width = 12, height = 8, dpi = 180)

access_quadrants <- access_anatomy %>%
  filter(sample_n >= 180) %>%
  ggplot(aes(x = women_location_quotient, y = race_location_quotient, color = p50, size = workers)) +
  geom_hline(yintercept = 1, color = "grey75", linetype = "dashed") +
  geom_vline(xintercept = 1, color = "grey75", linetype = "dashed") +
  geom_point(alpha = 0.72) +
  scale_x_continuous(labels = label_number(accuracy = 0.1)) +
  scale_y_continuous(labels = label_number(accuracy = 0.1)) +
  scale_color_gradient(low = "#64748b", high = "#eab308", labels = format_brl_axis) +
  scale_size_continuous(range = c(1.5, 10), labels = label_number(big.mark = ".", decimal.mark = ",")) +
  labs(
    title = "Quem entra nas ocupacoes de maior renda?",
    subtitle = "Quocientes de localizacao: acima de 1 significa sobre-representacao no grupo.",
    x = "Representacao feminina relativa",
    y = "Representacao preta/parda/indigena relativa",
    color = "Mediana",
    size = "Trabalhadores",
    caption = "Fonte: PNAD Continua/IBGE 1T2026. Ocupacoes com n >= 180. Analise descritiva."
  ) +
  theme(panel.grid.minor = element_blank(), plot.title.position = "plot", legend.position = "bottom")

ggsave(file.path(figures_dir, "access_representation_quadrants.png"), access_quadrants, width = 12, height = 8, dpi = 180)

theil_plot_df <- tibble(
  variable = c("Ocupacao", "UF", "Escolaridade"),
  between = c(
    theil_summary$occupation$between_share,
    theil_summary$state$between_share,
    theil_summary$education$between_share
  ),
  within = c(
    theil_summary$occupation$within_share,
    theil_summary$state$within_share,
    theil_summary$education$within_share
  )
) %>%
  pivot_longer(c(between, within), names_to = "component", values_to = "share") %>%
  mutate(
    component = recode(component, between = "Entre grupos", within = "Dentro dos grupos"),
    variable = fct_reorder(variable, share, .fun = max)
  )

theil_plot <- theil_plot_df %>%
  ggplot(aes(x = share, y = variable, fill = component)) +
  geom_col(width = 0.72) +
  scale_x_continuous(labels = percent) +
  scale_fill_manual(values = c("Entre grupos" = "#eab308", "Dentro dos grupos" = "#334155")) +
  labs(
    title = "De onde vem a desigualdade salarial observada?",
    subtitle = "Decomposicao Theil T por ocupacao, UF e escolaridade.",
    x = "Participacao na desigualdade Theil T",
    y = NULL,
    fill = NULL,
    caption = "Fonte: PNAD Continua/IBGE 1T2026. Decomposicao ponderada; resultado descritivo."
  ) +
  theme(panel.grid.minor = element_blank(), plot.title.position = "plot", legend.position = "bottom")

ggsave(file.path(figures_dir, "theil_inequality_decomposition.png"), theil_plot, width = 11, height = 6.5, dpi = 180)

cat("Deep figures rendered.\n")
