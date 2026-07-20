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
  "broom", "gt", "readxl", "jsonlite", "glue"
)

missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop(
    "Missing R packages: ",
    paste(missing_packages, collapse = ", "),
    "\nRun source('requirements.R') from the project root first.",
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(PNADcIBGE)
  library(survey)
  library(srvyr)
  library(tidyverse)
  library(janitor)
  library(scales)
  library(broom)
  library(gt)
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
docs_dir <- file.path(project_root, "docs")

dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(docs_dir, recursive = TRUE, showWarnings = FALSE)

cache_dir <- Sys.getenv("PNADC_CACHE_DIR")
if (cache_dir == "") {
  local_app_data <- Sys.getenv("LOCALAPPDATA")
  if (local_app_data == "") {
    local_app_data <- tempdir()
  }
  cache_dir <- file.path(local_app_data, "pnadc-cache", "occupation-pay-gap")
}
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

cod_url <- "https://ftp.ibge.gov.br/PNS/Documentacao_Geral/Estrutura_Ocupacao_COD.xls"
cod_path <- file.path(cache_dir, "Estrutura_Ocupacao_COD.xls")
if (!file.exists(cod_path)) {
  download.file(cod_url, cod_path, mode = "wb", quiet = FALSE)
}

vars <- c("UF", "V2007", "V2010", "VD3004", "VD4002", "VD4009", "V4010", "VD4016", "VD4031")

pnad_raw <- get_pnadc(
  year = 2026,
  quarter = 1,
  vars = vars,
  labels = TRUE,
  deflator = TRUE,
  design = FALSE,
  savedir = cache_dir
)

cod_raw <- read_excel(cod_path, col_names = FALSE)
cod <- cod_raw %>%
  transmute(
    occupation = as.character(...4),
    occupation_name = str_squish(as.character(...5))
  ) %>%
  filter(!is.na(occupation), !is.na(occupation_name), str_detect(occupation, "^[0-9]{4}$")) %>%
  distinct(occupation, .keep_all = TRUE)

prepared_df <- pnad_raw %>%
  clean_names() %>%
  mutate(
    income_main = as.numeric(vd4016),
    hours = as.numeric(vd4031),
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
  left_join(cod, by = "occupation") %>%
  mutate(
    occupation_label = if_else(
      is.na(occupation_name),
      paste0("COD ", occupation),
      paste0(occupation, " - ", str_to_sentence(str_to_lower(occupation_name)))
    ),
    analytic_domain = !is.na(income_main) & income_main > 0 & !is.na(occupation) & occupation != ""
  )

design_full <- svydesign(
  ids = ~upa,
  strata = ~estrato,
  weights = ~v1028,
  data = prepared_df,
  nest = TRUE
)

analytic_design <- subset(design_full, analytic_domain)
analysis_svy <- as_survey(analytic_design)
analysis_df <- prepared_df %>% filter(analytic_domain)

min_sample <- 80
min_cell_sample <- 40

weighted_median <- function(x, w) {
  ok <- !is.na(x) & !is.na(w) & w > 0
  x <- x[ok]
  w <- w[ok]
  if (length(x) == 0) return(NA_real_)
  ord <- order(x)
  x <- x[ord]
  w <- w[ord]
  x[which(cumsum(w) >= sum(w) / 2)[1]]
}

occupation_n <- analysis_df %>%
  count(occupation, occupation_label, name = "sample_n")

occupation_medians <- analysis_df %>%
  group_by(occupation, occupation_label) %>%
  summarise(
    median_income = weighted_median(income_main, v1028),
    .groups = "drop"
  )

occupation_rank <- analysis_svy %>%
  group_by(occupation, occupation_label) %>%
  summarise(
    workers = survey_total(vartype = NULL),
    avg_income = survey_mean(income_main, vartype = "ci", na.rm = TRUE),
    avg_hours = survey_mean(hours, vartype = NULL, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(occupation_n, by = c("occupation", "occupation_label")) %>%
  left_join(occupation_medians, by = c("occupation", "occupation_label")) %>%
  filter(sample_n >= min_sample) %>%
  arrange(desc(avg_income)) %>%
  mutate(rank = row_number())

write_csv(occupation_rank, file.path(processed_dir, "occupation_rank_q1_2026.csv"))

format_brl_axis <- label_currency(prefix = "R$ ", big.mark = ".", decimal.mark = ",", accuracy = 1)
wrap_label <- function(x, width = 42) str_wrap(x, width = width)

top20_plot <- occupation_rank %>%
  slice_head(n = 20) %>%
  mutate(occupation_short = fct_reorder(wrap_label(occupation_label, 48), avg_income)) %>%
  ggplot(aes(x = avg_income, y = occupation_short)) +
  geom_errorbar(aes(xmin = avg_income_low, xmax = avg_income_upp), width = 0.2, color = "grey55") +
  geom_point(size = 2.8, color = "#2563eb") +
  scale_x_continuous(labels = format_brl_axis, expand = expansion(mult = c(0.03, 0.10))) +
  labs(
    title = "Ocupacoes com maior rendimento medio no Brasil",
    subtitle = "PNAD Continua/IBGE, 1o trimestre de 2026. Estimativas ponderadas; ocupacoes com n >= 80.",
    x = "Rendimento mensal habitual medio do trabalho principal",
    y = NULL,
    caption = "Fonte: microdados PNAD Continua/IBGE. Analise descritiva; barras indicam IC 95%."
  ) +
  theme(
    plot.title.position = "plot",
    plot.caption.position = "plot",
    panel.grid.minor = element_blank()
  )

ggsave(file.path(figures_dir, "top20_occupations_income.png"), top20_plot, width = 12, height = 8.5, dpi = 180)

top_occupations <- occupation_rank %>% slice_head(n = 15) %>% pull(occupation)

cell_n <- analysis_df %>%
  filter(occupation %in% top_occupations) %>%
  count(occupation, sex, name = "cell_sample_n")

composition_sex <- analysis_svy %>%
  filter(occupation %in% top_occupations, sex %in% c("Homem", "Mulher")) %>%
  group_by(occupation, occupation_label, sex) %>%
  summarise(workers = survey_total(vartype = NULL), .groups = "drop") %>%
  left_join(cell_n, by = c("occupation", "sex")) %>%
  group_by(occupation, occupation_label) %>%
  mutate(share = workers / sum(workers, na.rm = TRUE)) %>%
  ungroup()

write_csv(composition_sex, file.path(processed_dir, "top15_gender_composition.csv"))

gender_plot <- composition_sex %>%
  mutate(occupation_short = fct_reorder(wrap_label(occupation_label, 46), share, .fun = max)) %>%
  ggplot(aes(x = share, y = occupation_short, fill = sex)) +
  geom_col(position = "fill", width = 0.75) +
  scale_x_continuous(labels = percent) +
  scale_fill_manual(values = c("Homem" = "#475569", "Mulher" = "#14b8a6")) +
  labs(
    title = "Composicao por sexo nas ocupacoes de maior rendimento",
    subtitle = "Participacao estimada entre trabalhadores das 15 ocupacoes do topo do ranking.",
    x = "Participacao dos trabalhadores",
    y = NULL,
    fill = NULL,
    caption = "Fonte: microdados PNAD Continua/IBGE. Analise descritiva."
  ) +
  theme(
    plot.title.position = "plot",
    plot.caption.position = "plot",
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

ggsave(file.path(figures_dir, "top15_gender_composition.png"), gender_plot, width = 12, height = 8, dpi = 180)

gender_gap_long <- analysis_svy %>%
  filter(occupation %in% top_occupations, sex %in% c("Homem", "Mulher")) %>%
  group_by(occupation, occupation_label, sex) %>%
  summarise(avg_income = survey_mean(income_main, vartype = "ci", na.rm = TRUE), .groups = "drop") %>%
  left_join(cell_n, by = c("occupation", "sex"))

gender_gap <- gender_gap_long %>%
  filter(cell_sample_n >= min_cell_sample) %>%
  select(occupation, occupation_label, sex, cell_sample_n, avg_income, avg_income_low, avg_income_upp) %>%
  pivot_wider(
    names_from = sex,
    values_from = c(cell_sample_n, avg_income, avg_income_low, avg_income_upp),
    names_sep = "_"
  ) %>%
  filter(!is.na(avg_income_Homem), !is.na(avg_income_Mulher)) %>%
  mutate(
    gap_women_vs_men = avg_income_Mulher / avg_income_Homem - 1,
    gap_note = glue("Cells with unweighted n >= {min_cell_sample} for both Homem and Mulher")
  ) %>%
  arrange(gap_women_vs_men)

write_csv(gender_gap, file.path(processed_dir, "top15_gender_gap.csv"))

model_design <- update(
  analytic_design,
  log_income = log(income_main),
  hours_capped = pmin(hours, 80)
)

fit <- svyglm(
  log_income ~ sex + race_group + education + informal_proxy + state + hours_capped,
  design = model_design
)

fit_with_occupation <- lm(
  log(income_main) ~ sex + race_group + education + informal_proxy + state + pmin(hours, 80) + factor(occupation),
  weights = v1028,
  data = analysis_df
)

tidy_model <- function(model, model_name) {
  tidy(model, conf.int = TRUE) %>%
    filter(!str_detect(term, "^state|^occupation_fe|^factor\\(occupation\\)")) %>%
    mutate(
      model = model_name,
      pct_effect = exp(estimate) - 1,
      pct_low = exp(conf.low) - 1,
      pct_high = exp(conf.high) - 1
    ) %>%
    relocate(model)
}

model_terms <- bind_rows(
  tidy_model(fit, "descriptive_without_occupation_fixed_effects"),
  tidy_model(fit_with_occupation, "weighted_lm_with_occupation_fixed_effects_sensitivity")
)

write_csv(model_terms, file.path(processed_dir, "descriptive_model_terms.csv"))

top_rows <- occupation_rank %>% slice_head(n = 5)
bottom_rows <- occupation_rank %>% slice_tail(n = 5)
women_gap_summary <- gender_gap %>%
  filter(!is.na(gap_women_vs_men)) %>%
  arrange(gap_women_vs_men) %>%
  slice_head(n = 3)

summary <- list(
  generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
  r_version = paste(R.version$major, R.version$minor, sep = "."),
  pnad_year = 2026,
  pnad_quarter = 1,
  rows_imported = nrow(pnad_raw),
  rows_analytic = nrow(analysis_df),
  occupations_total = n_distinct(analysis_df$occupation),
  occupations_after_filter = nrow(occupation_rank),
  min_sample = min_sample,
  min_cell_sample = min_cell_sample,
  cache_dir = normalizePath(cache_dir, winslash = "/", mustWork = FALSE),
  top_occupation = list(
    code = top_rows$occupation[1],
    label = top_rows$occupation_label[1],
    avg_income = unname(top_rows$avg_income[1]),
    median_income = unname(top_rows$median_income[1]),
    sample_n = unname(top_rows$sample_n[1])
  ),
  top5 = top_rows %>% select(rank, occupation_label, avg_income, median_income, sample_n),
  bottom5_after_filter = bottom_rows %>% select(rank, occupation_label, avg_income, median_income, sample_n),
  largest_women_vs_men_gaps_top15 = women_gap_summary %>%
    select(occupation_label, avg_income_Homem, avg_income_Mulher, gap_women_vs_men)
)

write_json(
  summary,
  file.path(processed_dir, "analysis_summary.json"),
  pretty = TRUE,
  auto_unbox = TRUE
)

cat(toJSON(summary, pretty = TRUE, auto_unbox = TRUE))
