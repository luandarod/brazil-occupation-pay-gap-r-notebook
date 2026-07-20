# Brazil Occupation Pay Gap

On 20 July 2026, Folha de S.Paulo published a story about the highest-paid occupations in Brazil. The ranking is useful. It is also a little dangerous if we read it too quickly.

This project uses PNAD Continua/IBGE microdata from Q1 2026 to ask a narrower question: when an occupation looks high-paid, is that because most workers in it earn a lot, or because a high-income tail pulls the average upward?

The answer is mixed. `Diretores gerais e gerentes gerais` rank first by mean income, around **R$ 22.4k** per month, but the weighted median is **R$ 11k**. `Medicos especialistas` rank second by mean, around **R$ 19.3k**, while their weighted median is **R$ 15k**. Same headline theme, different distribution.

## What This Repo Does

The analysis is written in R and uses `PNADcIBGE`, `survey`, `srvyr` and `tidyverse`. It downloads the PNAD quarter, maps occupation codes to names, applies the survey design and exports only aggregate tables and figures.

No raw PNAD microdata are stored here. Social-post drafts stay outside the repo.

## Main Outputs

- `data/processed/occupation_rank_q1_2026.csv`: occupation ranking with weighted mean, confidence interval, weighted median and sample count.
- `data/processed/top15_gender_composition.csv`: gender composition inside the 15 highest-mean-income occupations.
- `data/processed/top15_gender_gap.csv`: descriptive gender gaps for occupation-sex cells with enough observations.
- `data/processed/descriptive_model_terms.csv`: interpretable terms from the descriptive models.
- `figures/top20_occupations_income.png`: ranking chart with confidence intervals.
- `figures/top15_gender_composition.png`: composition chart for top occupations.

For the short version of the findings, read `docs/insights.md`.

## Project Structure

```text
.
|-- R/
|   |-- run_analysis.R
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
Rscript R/validate_outputs.R
```

If R is installed but not in `PATH`, use the full Windows path:

```powershell
& "C:\Program Files\R\R-4.6.1\bin\Rscript.exe" requirements.R
& "C:\Program Files\R\R-4.6.1\bin\Rscript.exe" R/run_analysis.R
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

## Read This Before Interpreting The Results

This is descriptive work. It does not prove discrimination, and it does not estimate the causal effect of gender, race/color, education or occupation.

The project compares observed survey-weighted patterns. Pay differences can reflect hours, formalization, region, education, selection into employment, seniority, firm type, sector and variables PNAD does not observe. The notebook says that out loud because the easy version of this analysis would overclaim.

## License

Code and documentation are released under the MIT License. IBGE microdata are not redistributed here.
