# Brazil Occupation Pay Anatomy

On 20 July 2026, Folha de S.Paulo published a story about the highest-paid occupations in Brazil. I used it as a starting point for a question that a plain ranking cannot answer well:

**When an occupation looks high-paid, what is hiding inside that number?**

The project uses PNAD Continua/IBGE microdata from Q1 2026 and keeps the survey design intact. That means weights, strata and PSU are part of the pipeline. The result is not a CSV sorted by salary. It is a small wage-anatomy project in R.

The first surprise came fast. `Diretores gerais e gerentes gerais` lead the ranking by mean income, around **R$ 22.4k** per month. Their weighted median is **R$ 11k**. That is a very different story from `Medicos especialistas`, with a mean around **R$ 19.3k** and a median around **R$ 15k**.

Same ranking neighborhood. Different wage structure.

The deeper result is the Theil decomposition. In this run, differences **between occupations** account for about **42.6%** of observed earnings inequality. The other **57.4%** sits **inside occupations**. So occupation matters a lot, but the occupation label still hides a big part of the wage spread.

## What This Repo Does

The analysis is written in R with `PNADcIBGE`, `survey`, `srvyr`, `tidyverse` and `ggplot2`.

It downloads the PNAD quarter, maps IBGE occupation codes, applies the complex survey design and exports aggregate tables and figures. Raw PNAD microdata stay out of the repo. LinkedIn drafts stay out too.

## Main Outputs

- `data/processed/occupation_rank_q1_2026.csv`: weighted ranking by occupation, with mean, confidence interval, median and sample count.
- `data/processed/occupation_wage_anatomy.csv`: P10, P50, P90, Gini, top-10% income share, mean/median ratio and wage archetype.
- `data/processed/occupation_access_anatomy.csv`: income premium, female representation quotient, race/color representation quotient and access profile.
- `data/processed/top15_gender_composition.csv`: gender composition inside the 15 highest-mean-income occupations.
- `data/processed/top15_gender_gap.csv`: descriptive gender gaps for occupation-sex cells with enough observations.
- `data/processed/descriptive_model_terms.csv`: model terms from the descriptive log-income checks.
- `data/processed/inequality_decomposition_theil.json`: Theil T decomposition by occupation, state and education.
- `data/processed/deep_anatomy_highlights.json`: selected findings used to review the story.

The figures are in `figures/`:

- `top20_occupations_income.png`
- `wage_anatomy_map.png`
- `distribution_ladder_selected_occupations.png`
- `access_vs_internal_gender_gap.png`
- `access_representation_quadrants.png`
- `theil_inequality_decomposition.png`

For the short reading of the findings, open `docs/insights.md`.

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

Raw PNAD/cache files are stored outside the repo by default:

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

## Read Before Interpreting

This is descriptive work. It does not prove discrimination, and it does not estimate the causal effect of gender, race/color, education or occupation.

PNAD does not observe the same employer, exact role, seniority, bonus structure, firm size or productivity. Pay differences can also reflect hours, formalization, region, education and selection into employment.

The useful claim is narrower: a public ranking becomes much richer when we inspect distribution, uncertainty, representation and between/within inequality.

## License

Code and documentation are released under the MIT License. IBGE microdata are not redistributed here.
