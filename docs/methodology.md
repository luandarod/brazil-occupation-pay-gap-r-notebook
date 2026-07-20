# Methodology

This project starts with a simple news hook: a wage ranking by occupation. The technical work is about slowing that ranking down enough to see what is inside it.

## Question

The working question is:

> Which occupations have the highest usual monthly income from the main job in Brazil, and how does the story change when we look at uncertainty, medians, gender composition and observable worker characteristics?

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

## Models

The model section is a diagnostic, not a proof. It estimates associations with log income using sex, race/color group, education, informality proxy, state and capped weekly hours.

A second weighted model adds occupation fixed effects as a sensitivity check. The published model table keeps only the interpretable terms and leaves the many occupation coefficients out of the CSV.

## Language Rules

Use words like "observed difference", "descriptive gap", "associated with" and "survey-weighted estimate".

Avoid stronger claims such as "caused by", "proves discrimination" or "same work, different pay". PNAD does not observe the same employer, exact role, seniority, firm size, productivity or contract details needed for that claim.

## Raw Data Policy

Raw PNAD files are large. The script stores them outside the repo by default and publishes only aggregate outputs.
