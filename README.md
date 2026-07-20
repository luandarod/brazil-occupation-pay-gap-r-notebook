# Brazil Occupation Pay Anatomy

On 20 July 2026, Folha de S.Paulo published a story about the highest-paid occupations in Brazil. A ranking is a good hook, but it is not the full story.

This project uses PNAD Continua/IBGE microdata from Q1 2026 to ask a deeper question: **when an occupation looks high-paid, what exactly is inside that number?**

The analysis separates four layers:

- the headline ranking by survey-weighted mean income;
- the internal wage distribution by occupation: P10, median, P90, Gini and top-10% income share;
- representation and access patterns by sex and race/color;
- a Theil decomposition to estimate how much observed earnings inequality sits between occupations versus inside occupations.

The core finding is sharper than a top-20 list: **occupation explains a large part of inequality, but most of the measured inequality still happens within occupations.** In this run, the Theil decomposition attributes about **42.6%** of earnings inequality to differences between occupations and **57.4%** to differences inside occupations.

That changes the storytelling. It is not only "which jobs pay more?". It is also "which occupations have a high middle, which ones are pulled up by a small top tail, and who is under-represented in those better-paid spaces?"

## What This Repo Does

The analysis is written in R and uses `PNADcIBGE`, `survey`, `srvyr` and `tidyverse`. It downloads the PNAD quarter, maps occupation codes to names, applies the survey design and exports only aggregate tables and figures.

No raw PNAD microdata are stored here. Social-post drafts stay outside the repo.

## Main Outputs

- `data/processed/occupation_rank_q1_2026.csv`: occupation ranking with weighted mean, confidence interval, weighted median and sample count.
- `data/processed/occupation_wage_anatomy.csv`: distributional anatomy by occupation, including P10/P50/P90, Gini, top-tail share and wage archetype.
- `data/processed/occupation_access_anatomy.csv`: pay premium, female representation quotient, race/color representation quotient and access profile.
- `data/processed/top15_gender_composition.csv`: gender composition inside the 15 highest-mean-income occupations.
- `data/processed/top15_gender_gap.csv`: descriptive gender gaps for occupation-sex cells with enough observations.
- `data/processed/descriptive_model_terms.csv`: interpretable terms from the descriptive models.
- `data/processed/inequality_decomposition_theil.json`: Theil T decomposition by occupation, state and education.
- `data/processed/deep_anatomy_highlights.json`: selected high-signal findings for review and narrative writing.
- `figures/top20_occupations_income.png`: ranking chart with confidence intervals.
- `figures/top15_gender_composition.png`: composition chart for top occupations.
- `figures/wage_anatomy_map.png`: map of median income versus mean/median distortion.
- `figures/distribution_ladder_selected_occupations.png`: P10-P90 ladders for selected occupations.
- `figures/access_vs_internal_gender_gap.png`: female participation versus within-occupation gender gap.
- `figures/access_representation_quadrants.png`: representation map using location quotients.
- `figures/theil_inequality_decomposition.png`: between/within decomposition chart.

For the short version of the findings, read `docs/insights.md`.

## Project Structure

```text
.
|-- R/
|   |-- run_analysis.R
|   |-- run_deep_anatomy.R
|   |-- render_deep_figures.R
|   `-- validate_outputs.R
|-- data/
|   `-- processed/
|-- docs/
|   |-- gitlab-publish.md
|   |-- insights.md
|   |-- literature-review.md
|   `-- methodology.md
|-- figures/
|-- notebooks/
|   `-- occupation_pay_gap_r_notebook.ipynb
|-- requirements.R
|-- README.md
|-- CITATION.cff
`-- LICENSE
```

## Reproduce

From the project root:

```powershell
Rscript requirements.R
Rscript R/run_analysis.R
Rscript R/run_deep_anatomy.R
Rscript R/render_deep_figures.R
Rscript R/validate_outputs.R
```

If R is installed but not in `PATH`, use the full Windows path:

```powershell
& "C:\Program Files\R\R-4.6.1\bin\Rscript.exe" requirements.R
& "C:\Program Files\R\R-4.6.1\bin\Rscript.exe" R/run_analysis.R
& "C:\Program Files\R\R-4.6.1\bin\Rscript.exe" R/run_deep_anatomy.R
& "C:\Program Files\R\R-4.6.1\bin\Rscript.exe" R/render_deep_figures.R
& "C:\Program Files\R\R-4.6.1\bin\Rscript.exe" R/validate_outputs.R
```

The script keeps raw PNAD/cache files outside the repo by default:

```text
%LOCALAPPDATA%\pnadc-cache\occupation-pay-gap
```

To choose another cache folder:

```powershell
$env:PNADC_CACHE_DIR = "D:\pnadc-cache"
```

## Sources

- Folha de S.Paulo, 20 July 2026, story on occupations with the highest average income in Brazil.
- [IBGE PNAD Continua Trimestral](https://www.ibge.gov.br/estatisticas/sociais/saude/9173-pesquisa-nacional-por-amostra-de-domicilios-continua-trimestral.html)
- [IBGE Q1 2026 labor-market release](https://agenciadenoticias.ibge.gov.br/agencia-sala-de-imprensa/2013-agencia-de-noticias/releases/46676-pnad-continua-trimestral-desocupacao-sobe-em-15-das-27-ufs-no-1-trimestre-de-2026)
- [PNADcIBGE on CRAN](https://cran.r-project.org/web/packages/PNADcIBGE/index.html)
- IBGE COD occupation structure.
- Occupational segregation and wage-gap literature cited in `docs/literature-review.md`.

## Read This Before Interpreting The Results

This is descriptive work. It does not prove discrimination, and it does not estimate the causal effect of gender, race/color, education or occupation.

The project compares observed survey-weighted patterns. Pay differences can reflect hours, formalization, region, education, selection into employment, seniority, firm type, sector and variables PNAD does not observe. The notebook says that out loud because the easy version of this analysis would overclaim.

## License

Code and documentation are released under the MIT License. IBGE microdata are not redistributed here.
