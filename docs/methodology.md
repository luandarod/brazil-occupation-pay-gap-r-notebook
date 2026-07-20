# Methodology

This project starts with a simple news hook: a wage ranking by occupation. The technical work is about slowing that ranking down enough to see what is inside it.

## Question

The working question is:

> Which occupations have the highest usual monthly income from the main job in Brazil, and how does the story change when we inspect the distribution, representation patterns and inequality decomposition behind the ranking?

That wording matters. The project does not try to estimate causal effects. It reads the PNAD as a complex survey and produces descriptive estimates.

## Data And Variables

The data come from PNAD Continua/IBGE, Q1 2026. The main outcome is `VD4016`, usual monthly income from the main job. Occupation comes from `V4010`, then gets mapped to the IBGE COD occupation structure.

Variables used in the analysis:

- `UF`: state
- `V2007`: sex
- `V2010`: race/color
- `VD3004`: education
- `VD4002`: work status
- `VD4009`: job position
- `V4010`: detailed occupation code
- `VD4016`: usual monthly income from the main job
- `VD4031`: usual weekly hours in the main job
- `UPA`, `Estrato`, `V1028`: survey design variables loaded by `PNADcIBGE`

## Survey Design

The script creates the survey design before applying the analytic income filter. That avoids treating the filtered subset like a simple flat file.

The design uses:

- PSU: `UPA`
- strata: `Estrato`
- weight: `V1028`

The analytic domain keeps people with positive usual monthly income and a valid occupation code.

## Reliability Rules

Detailed occupation codes get noisy fast. The ranking keeps occupations with at least **80** unweighted observations. The gender-gap table uses a stricter cell rule: each occupation-sex cell must have at least **40** observations.

Mean income is the main ranking metric because it matches the public conversation around average pay. The project also reports weighted medians because the mean can be dragged upward by a small high-income group. That difference is one of the more useful parts of the analysis.

The deeper anatomy keeps occupations with at least **120** unweighted observations. Some access/gap plots use **180** observations to reduce instability in small occupations.

## Wage Anatomy

`R/run_deep_anatomy.R` adds a distributional layer to the project. For each occupation, it estimates:

- P10, P25, P50, P75 and P90 of usual monthly income;
- weighted median hourly income;
- within-occupation Gini;
- top-10% income share inside the occupation;
- mean/median ratio;
- P90/P50 and P50/P10 ratios;
- female and preta/parda/indigena representation shares;
- descriptive within-occupation gender gap.

The script then labels each occupation with a wage archetype:

- `elite_estavel`: high median and a relatively compressed mean/median ratio;
- `elite_de_cauda_longa`: high mean with a large upper-tail pull;
- `teto_alto_base_distante`: large distance between the middle and the upper tail;
- `renda_baixa_comprimida`: low median and compressed distribution;
- `topo_instavel_amostra_pequena`: high uncertainty around the mean;
- `meio_heterogeneo`: mixed profiles that do not fit the sharper categories.

These labels are heuristics for storytelling and exploration. They are not official occupational categories.

## Access Anatomy

The access layer uses location quotients:

- female location quotient = occupation female share / overall female share;
- race/color location quotient = occupation preta/parda/indigena share / overall preta/parda/indigena share.

A value above 1 means over-representation relative to the analytic sample. A value below 1 means under-representation.

The access profile is designed to make the ranking less superficial. A high-income occupation can be:

- high-income with narrow access;
- high-income with broader access;
- low-income with vulnerable concentration;
- female-present with an internal pay gap;
- mixed.

Again, this is descriptive. It should be read as evidence for better questions, not as a causal diagnosis.

## Inequality Decomposition

The project uses a weighted Theil T index because it can be decomposed into between-group and within-group components.

For a grouping variable such as occupation, the method estimates:

- total observed earnings inequality;
- the share explained by differences between group means;
- the share left inside the groups.

In the current output, occupation accounts for about **42.6%** of Theil inequality, while **57.4%** remains within occupations. Education accounts for about **27.3%** between groups, and state accounts for about **5.3%**.

This is one of the strongest interpretations in the project: occupational sorting matters a lot, but it does not erase internal dispersion.

## Models

The model section is a diagnostic, not a proof. It estimates associations with log income using sex, race/color group, education, informality proxy, state and capped weekly hours.

A second weighted model adds occupation fixed effects as a sensitivity check. The published model table keeps only the interpretable terms and leaves the many occupation coefficients out of the CSV.

## Language Rules

Use words like "observed difference", "descriptive gap", "associated with" and "survey-weighted estimate".

Avoid stronger claims such as "caused by", "proves discrimination" or "same work, different pay". PNAD does not observe the same employer, exact role, seniority, firm size, productivity or contract details needed for that claim.

## Raw Data Policy

Raw PNAD files are large. The script stores them outside the repo by default and publishes only aggregate outputs.
