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

required_packages <- c(
  "PNADcIBGE", "survey", "srvyr", "tidyverse", "janitor", "scales",
  "readxl", "jsonlite", "glue"
)

missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop("Missing R packages: ", paste(missing_packages, collapse = ", "), call. = FALSE)
}

suppressPackageStartupMessages({
  library(PNADcIBGE)
  library(survey)
  library(srvyr)
  library(tidyverse)
  library(janitor)
  library(scales)
  library(readxl)
  library(jsonlite)
  library(glue)
})

options(survey.lonely.psu = "adjust")
theme_set(theme_minimal(base_size = 12))

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
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

cache_dir <- Sys.getenv("PNADC_CACHE_DIR")
if (cache_dir == "") {
  local_app_data <- Sys.getenv("LOCALAPPDATA")
  if (local_app_data == "") local_app_data <- tempdir()
  cache_dir <- file.path(local_app_data, "pnadc-cache", "occupation-pay-gap")
}
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

cod_url <- "https://ftp.ibge.gov.br/PNS/Documentacao_Geral/Estrutura_Ocupacao_COD.xls"
cod_path <- file.path(cache_dir, "Estrutura_Ocupacao_COD.xls")
if (!file.exists(cod_path)) download.file(cod_url, cod_path, mode = "wb", quiet = FALSE)

vars <- c(
  "UF", "V2007", "V2010", "V2009", "VD3004", "VD4002", "VD4009",
  "V4010", "VD4016", "VD4031"
)

pnad_raw <- get_pnadc(
  year = 2026,
  quarter = 1,
  vars = vars,
  labels = TRUE,
  deflator = TRUE,
  design = FALSE,
  savedir = cache_dir
)

cod <- read_excel(cod_path, col_names = FALSE) %>%
  transmute(
    occupation = as.character(...4),
    occupation_name = str_squish(as.character(...5))
  ) %>%
  filter(!is.na(occupation), !is.na(occupation_name), str_detect(occupation, "^[0-9]{4}$")) %>%
  distinct(occupation, .keep_all = TRUE)

weighted_quantile <- function(x, w, probs) {
  ok <- !is.na(x) & !is.na(w) & w > 0
  x <- x[ok]
  w <- w[ok]
  if (length(x) == 0) return(rep(NA_real_, length(probs)))
  ord <- order(x)
  x <- x[ord]
  w <- w[ord]
  cw <- cumsum(w) / sum(w)
  vapply(probs, function(p) x[which(cw >= p)[1]], numeric(1))
}

weighted_gini <- function(x, w) {
  ok <- !is.na(x) & !is.na(w) & w > 0 & x >= 0
  x <- x[ok]
  w <- w[ok]
  if (length(x) < 2 || sum(w) == 0 || sum(x * w) == 0) return(NA_real_)
  ord <- order(x)
  x <- x[ord]
  w <- w[ord]
  cw <- cumsum(w) / sum(w)
  cy <- cumsum(x * w) / sum(x * w)
  cw0 <- c(0, head(cw, -1))
  cy0 <- c(0, head(cy, -1))
  1 - sum((cy + cy0) * (cw - cw0))
}

top_share <- function(x, w, top = 0.10) {
  ok <- !is.na(x) & !is.na(w) & w > 0 & x >= 0
  x <- x[ok]
  w <- w[ok]
  if (length(x) == 0 || sum(x * w) == 0) return(NA_real_)
  ord <- order(x, decreasing = TRUE)
  x <- x[ord]
  w <- w[ord]
  cw <- cumsum(w) / sum(w)
  keep <- cw <= top
  if (!any(keep)) keep[1] <- TRUE
  sum(x[keep] * w[keep]) / sum(x * w)
}

weighted_theil <- function(x, w) {
  ok <- !is.na(x) & !is.na(w) & w > 0 & x > 0
  x <- x[ok]
  w <- w[ok]
  if (length(x) < 2) return(NA_real_)
  mu <- weighted.mean(x, w)
  if (is.na(mu) || mu <= 0) return(NA_real_)
  ratio <- x / mu
  sum((w / sum(w)) * ratio * log(ratio))
}

theil_decomposition <- function(df, group_col) {
  overall_mu <- weighted.mean(df$income_main, df$v1028, na.rm = TRUE)
  total <- weighted_theil(df$income_main, df$v1028)

  by_group <- df %>%
    filter(!is.na(.data[[group_col]]), income_main > 0, v1028 > 0) %>%
    group_by(group = .data[[group_col]]) %>%
    summarise(
      weight = sum(v1028, na.rm = TRUE),
      mean_income = weighted.mean(income_main, v1028, na.rm = TRUE),
      theil_within = weighted_theil(income_main, v1028),
      .groups = "drop"
    ) %>%
    filter(weight > 0, !is.na(mean_income), mean_income > 0)

  total_weight <- sum(by_group$weight)
  between <- by_group %>%
    mutate(component = (weight / total_weight) * (mean_income / overall_mu) * log(mean_income / overall_mu)) %>%
    summarise(value = sum(component, na.rm = TRUE)) %>%
    pull(value)
  within <- by_group %>%
    mutate(component = (weight / total_weight) * (mean_income / overall_mu) * theil_within) %>%
    summarise(value = sum(component, na.rm = TRUE)) %>%
    pull(value)

  list(
    group_variable = group_col,
    total_theil = total,
    between_group_theil = between,
    within_group_theil = within,
    between_share = between / total,
    within_share = within / total,
    groups = by_group %>% arrange(desc(weight))
  )
}

analysis_df <- pnad_raw %>%
  clean_names() %>%
  mutate(
    income_main = as.numeric(vd4016),
    hours = as.numeric(vd4031),
    hourly_income = income_main / pmax(hours * 4.33, 1),
    age = as.numeric(v2009),
    occupation = str_pad(as.character(v4010), 4, pad = "0"),
    sex = as.character(v2007),
    race_color = as.character(v2010),
    education = as.character(vd3004),
    state = as.character(uf),
    job_position = as.character(vd4009),
    race_group = case_when(
      str_detect(str_to_lower(race_color), "branca|amarela") ~ "Branca/amarela",
      str_detect(str_to_lower(race_color), "preta|parda|indig|ind\u00edg") ~ "Preta/parda/indigena",
      TRUE ~ "Outra/sem informacao"
    ),
    informal_proxy = case_when(
      str_detect(str_to_lower(job_position), "sem carteira|conta pr\u00f3pria|conta propria|trabalhador familiar") ~
        "Informal/autonomo proxy",
      TRUE ~ "Formal/empregador/publico proxy"
    )
  ) %>%
  filter(!is.na(income_main), income_main > 0, !is.na(occupation), occupation != "") %>%
  left_join(cod, by = "occupation") %>%
  mutate(
    occupation_label = if_else(
      is.na(occupation_name),
      paste0("COD ", occupation),
      paste0(occupation, " - ", str_to_sentence(str_to_lower(occupation_name)))
    )
  )

design <- svydesign(
  ids = ~upa,
  strata = ~estrato,
  weights = ~v1028,
  data = analysis_df,
  nest = TRUE
)
svy <- as_survey(design)

min_sample <- 120

occupation_core <- svy %>%
  group_by(occupation, occupation_label) %>%
  summarise(
    workers = survey_total(vartype = NULL),
    mean_income = survey_mean(income_main, vartype = "ci", na.rm = TRUE),
    mean_hourly_income = survey_mean(hourly_income, vartype = NULL, na.rm = TRUE),
    mean_hours = survey_mean(hours, vartype = NULL, na.rm = TRUE),
    .groups = "drop"
  )

occupation_distribution <- analysis_df %>%
  group_by(occupation, occupation_label) %>%
  summarise(
    sample_n = n(),
    p10 = weighted_quantile(income_main, v1028, 0.10),
    p25 = weighted_quantile(income_main, v1028, 0.25),
    p50 = weighted_quantile(income_main, v1028, 0.50),
    p75 = weighted_quantile(income_main, v1028, 0.75),
    p90 = weighted_quantile(income_main, v1028, 0.90),
    hourly_p50 = weighted_quantile(hourly_income, v1028, 0.50),
    gini_within = weighted_gini(income_main, v1028),
    top10_income_share = top_share(income_main, v1028, 0.10),
    .groups = "drop"
  )

occupation_composition <- svy %>%
  group_by(occupation, occupation_label, sex) %>%
  summarise(workers = survey_total(vartype = NULL), .groups = "drop") %>%
  group_by(occupation, occupation_label) %>%
  mutate(sex_share = workers / sum(workers, na.rm = TRUE)) %>%
  ungroup() %>%
  filter(sex %in% c("Homem", "Mulher")) %>%
  select(occupation, occupation_label, sex, sex_share) %>%
  pivot_wider(names_from = sex, values_from = sex_share, names_prefix = "share_")

race_composition <- svy %>%
  group_by(occupation, occupation_label, race_group) %>%
  summarise(workers = survey_total(vartype = NULL), .groups = "drop") %>%
  group_by(occupation, occupation_label) %>%
  mutate(race_share = workers / sum(workers, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(
    race_key = case_when(
      race_group == "Preta/parda/indigena" ~ "pretapardaindigena",
      race_group == "Branca/amarela" ~ "brancaamarela",
      TRUE ~ "outra"
    )
  ) %>%
  select(occupation, occupation_label, race_key, race_share) %>%
  pivot_wider(names_from = race_key, values_from = race_share, names_prefix = "share_")

gender_income <- svy %>%
  filter(sex %in% c("Homem", "Mulher")) %>%
  group_by(occupation, occupation_label, sex) %>%
  summarise(mean_income = survey_mean(income_main, vartype = NULL, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = sex, values_from = mean_income, names_prefix = "mean_") %>%
  mutate(gender_gap_women_vs_men = mean_Mulher / mean_Homem - 1)

anatomy <- occupation_core %>%
  left_join(occupation_distribution, by = c("occupation", "occupation_label")) %>%
  left_join(occupation_composition, by = c("occupation", "occupation_label")) %>%
  left_join(race_composition, by = c("occupation", "occupation_label")) %>%
  left_join(gender_income, by = c("occupation", "occupation_label")) %>%
  filter(sample_n >= min_sample) %>%
  mutate(
    mean_median_ratio = mean_income / p50,
    p90_p50_ratio = p90 / p50,
    p50_p10_ratio = p50 / p10,
    ci_relative_width = (mean_income_upp - mean_income_low) / mean_income,
    share_Mulher = replace_na(share_Mulher, 0),
    share_Homem = replace_na(share_Homem, 0),
    share_pretapardaindigena = replace_na(share_pretapardaindigena, 0),
    share_brancaamarela = replace_na(share_brancaamarela, 0),
    wage_anatomy_type = case_when(
      p50 >= quantile(p50, 0.80, na.rm = TRUE) & mean_median_ratio <= quantile(mean_median_ratio, 0.45, na.rm = TRUE) ~
        "elite_estavel",
      mean_income >= quantile(mean_income, 0.85, na.rm = TRUE) & mean_median_ratio >= quantile(mean_median_ratio, 0.75, na.rm = TRUE) ~
        "elite_de_cauda_longa",
      p90_p50_ratio >= quantile(p90_p50_ratio, 0.80, na.rm = TRUE) & gini_within >= quantile(gini_within, 0.70, na.rm = TRUE) ~
        "teto_alto_base_distante",
      p50 <= quantile(p50, 0.30, na.rm = TRUE) & p90_p50_ratio <= quantile(p90_p50_ratio, 0.45, na.rm = TRUE) ~
        "renda_baixa_comprimida",
      ci_relative_width >= quantile(ci_relative_width, 0.85, na.rm = TRUE) ~
        "topo_instavel_amostra_pequena",
      TRUE ~ "meio_heterogeneo"
    )
  ) %>%
  arrange(desc(mean_income))

write_csv(anatomy, file.path(processed_dir, "occupation_wage_anatomy.csv"))

overall_p50 <- weighted_quantile(analysis_df$income_main, analysis_df$v1028, 0.50)
overall_women_share <- with(
  analysis_df,
  sum(v1028[sex == "Mulher"], na.rm = TRUE) / sum(v1028[sex %in% c("Homem", "Mulher")], na.rm = TRUE)
)
overall_pretapardaindigena_share <- with(
  analysis_df,
  sum(v1028[race_group == "Preta/parda/indigena"], na.rm = TRUE) / sum(v1028, na.rm = TRUE)
)

access_anatomy <- anatomy %>%
  mutate(
    p50_premium_vs_overall = p50 / overall_p50 - 1,
    women_location_quotient = share_Mulher / overall_women_share,
    race_location_quotient = share_pretapardaindigena / overall_pretapardaindigena_share,
    access_profile = case_when(
      p50_premium_vs_overall >= quantile(p50_premium_vs_overall, 0.75, na.rm = TRUE) &
        women_location_quotient < 0.75 & race_location_quotient < 0.75 ~
        "alta_renda_porta_estreita",
      p50_premium_vs_overall >= quantile(p50_premium_vs_overall, 0.75, na.rm = TRUE) &
        (women_location_quotient >= 1 | race_location_quotient >= 1) ~
        "alta_renda_acesso_mais_amplo",
      p50_premium_vs_overall < 0 &
        women_location_quotient >= 1.15 & race_location_quotient >= 1.15 ~
        "baixa_renda_concentracao_vulneravel",
      gender_gap_women_vs_men <= -0.20 & women_location_quotient >= 1 ~
        "presenca_feminina_com_gap_interno",
      TRUE ~ "perfil_misto"
    )
  ) %>%
  arrange(desc(p50_premium_vs_overall))

write_csv(access_anatomy, file.path(processed_dir, "occupation_access_anatomy.csv"))

occupation_theil <- theil_decomposition(analysis_df, "occupation")
state_theil <- theil_decomposition(analysis_df, "state")
education_theil <- theil_decomposition(analysis_df, "education")

theil_summary <- list(
  generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
  interpretation = "Theil T decomposes earnings inequality into between-group and within-group components. It is descriptive and survey-weighted with PNAD expansion weights.",
  occupation = occupation_theil[setdiff(names(occupation_theil), "groups")],
  state = state_theil[setdiff(names(state_theil), "groups")],
  education = education_theil[setdiff(names(education_theil), "groups")]
)

write_json(
  theil_summary,
  file.path(processed_dir, "inequality_decomposition_theil.json"),
  pretty = TRUE,
  auto_unbox = TRUE
)

bind_rows(
  occupation_theil$groups %>% mutate(group_variable = "occupation"),
  state_theil$groups %>% mutate(group_variable = "state"),
  education_theil$groups %>% mutate(group_variable = "education")
) %>%
  write_csv(file.path(processed_dir, "inequality_decomposition_groups.csv"))

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

anatomy_map <- anatomy %>%
  ggplot(aes(x = p50, y = mean_median_ratio, size = workers, color = wage_anatomy_type)) +
  geom_hline(yintercept = 1.4, linetype = "dashed", color = "grey70") +
  geom_vline(xintercept = median(anatomy$p50, na.rm = TRUE), linetype = "dashed", color = "grey70") +
  geom_point(alpha = 0.78) +
  scale_x_continuous(labels = label_currency(prefix = "R$ ", big.mark = ".", decimal.mark = ",", accuracy = 1)) +
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
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    plot.title.position = "plot"
  ) +
  guides(
    color = guide_legend(ncol = 2, override.aes = list(size = 4)),
    size = guide_legend(nrow = 1)
  )

ggsave(file.path(figures_dir, "wage_anatomy_map.png"), anatomy_map, width = 12, height = 8, dpi = 180)

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
  scale_x_continuous(labels = label_currency(prefix = "R$ ", big.mark = ".", decimal.mark = ",", accuracy = 1)) +
  labs(
    title = "A escada salarial por dentro",
    subtitle = "Linha: P10 a P90. Verde: mediana. Dourado: media.",
    x = "Rendimento mensal habitual",
    y = NULL,
    caption = "Fonte: PNAD Continua/IBGE 1T2026. Analise descritiva."
  ) +
  theme(panel.grid.minor = element_blank(), plot.title.position = "plot")

ggsave(file.path(figures_dir, "distribution_ladder_selected_occupations.png"), distribution_ladder, width = 12, height = 8, dpi = 180)

access_gap <- anatomy %>%
  filter(!is.na(gender_gap_women_vs_men), sample_n >= 180) %>%
  mutate(label_flag = share_Mulher >= 0.40 & gender_gap_women_vs_men <= -0.20) %>%
  ggplot(aes(x = share_Mulher, y = gender_gap_women_vs_men, size = workers, color = p50)) +
  geom_hline(yintercept = 0, color = "grey75") +
  geom_vline(xintercept = 0.5, color = "grey75", linetype = "dashed") +
  geom_point(alpha = 0.75) +
  scale_x_continuous(labels = percent) +
  scale_y_continuous(labels = percent) +
  scale_color_viridis_c(option = "C", labels = label_currency(prefix = "R$ ", big.mark = ".", decimal.mark = ",")) +
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
  scale_color_gradient(low = "#64748b", high = "#eab308", labels = label_currency(prefix = "R$ ", big.mark = ".", decimal.mark = ",")) +
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
    occupation_theil$between_share,
    state_theil$between_share,
    education_theil$between_share
  ),
  within = c(
    occupation_theil$within_share,
    state_theil$within_share,
    education_theil$within_share
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

highlights <- list(
  generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
  rows = nrow(analysis_df),
  occupations_after_filter = nrow(anatomy),
  archetypes = anatomy %>% count(wage_anatomy_type, sort = TRUE),
  most_tail_led = anatomy %>%
    arrange(desc(mean_median_ratio)) %>%
    select(occupation_label, mean_income, p50, mean_median_ratio, gini_within, sample_n) %>%
    slice_head(n = 8),
  most_stable_elite = anatomy %>%
    filter(wage_anatomy_type == "elite_estavel") %>%
    arrange(desc(p50)) %>%
    select(occupation_label, mean_income, p50, p90_p50_ratio, gini_within, sample_n) %>%
    slice_head(n = 8),
  access_gap_cases = anatomy %>%
    filter(share_Mulher >= 0.40, gender_gap_women_vs_men <= -0.20, sample_n >= 180) %>%
    arrange(gender_gap_women_vs_men) %>%
    select(occupation_label, share_Mulher, mean_Mulher, mean_Homem, gender_gap_women_vs_men, p50, sample_n) %>%
    slice_head(n = 8),
  access_profiles = access_anatomy %>%
    count(access_profile, sort = TRUE),
  narrow_high_income_access = access_anatomy %>%
    filter(access_profile == "alta_renda_porta_estreita") %>%
    arrange(desc(p50_premium_vs_overall)) %>%
    select(
      occupation_label, p50, p50_premium_vs_overall, women_location_quotient,
      race_location_quotient, share_Mulher, share_pretapardaindigena, sample_n
    ) %>%
    slice_head(n = 8),
  inequality_decomposition = theil_summary
)

write_json(highlights, file.path(processed_dir, "deep_anatomy_highlights.json"), pretty = TRUE, auto_unbox = TRUE)

cat(toJSON(highlights, pretty = TRUE, auto_unbox = TRUE))
