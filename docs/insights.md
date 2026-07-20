# Findings Worth Reading Twice

The headline ranking is only the front door. Once the PNAD microdata are weighted and the occupation labels are joined back in, the better story is not "who earns more?". It is "what kind of wage structure sits behind each occupation?".

## 1. Occupation matters a lot, but it is not the whole inequality story

The Theil decomposition gives the project a stronger spine.

In this run, differences **between occupations** account for about **42.6%** of observed earnings inequality. Differences **inside occupations** account for about **57.4%**.

That is a useful result because it avoids two weak readings:

- "Everything is just occupation choice."
- "Occupation does not explain much."

The data say something more interesting. Occupational sorting matters, but the occupation label still hides a lot of dispersion.

## 2. Some high-paid occupations have a high middle. Others have a high tail.

`Diretores gerais e gerentes gerais` rank first by average income, at about **R$ 22.4k** per month. The weighted median is **R$ 11k**.

That is not a small detail. The mean is about **2.04 times** the median, and the within-occupation Gini is about **0.55**. This is a high-income occupation, but it is also a long-tail occupation.

`Medicos especialistas` tell a different story. The mean is about **R$ 19.3k**, the median is **R$ 15k**, and the mean/median ratio is much lower. It is still unequal inside, but the middle of the distribution is stronger.

Same top-of-ranking neighborhood. Different anatomy.

## 3. "Elite" is not one category

The script classifies occupations into wage archetypes. The result is not meant to be official; it is meant to make the reading sharper.

Among occupations with enough observations:

- **18** look like `elite_de_cauda_longa`: high mean pulled strongly by the upper tail.
- **13** look like `elite_estavel`: high median with a more stable distribution.
- **24** have `teto_alto_base_distante`: a large jump from the middle to the upper tail.
- **48** show `renda_baixa_comprimida`: lower and more compressed distributions.

This is the kind of segmentation a plain ranking cannot show.

## 4. The strongest "long-tail" cases are not only glamorous jobs

The highest mean/median ratios include law-related occupations, top management and also low-income work.

Examples:

- `Profissionais de nivel medio do direito e servicos legais e afins`: mean/median about **2.05**.
- `Diretores gerais e gerentes gerais`: mean/median about **2.04**.
- `Advogados e juristas`: mean around **R$ 9.3k**, median around **R$ 5k**.
- `Classificadores de residuos`: mean/median about **1.86**, but around a much lower income level.

That last case matters. A long tail is not always a story of wealth. Sometimes it is a sign that a low-paid occupation mixes very different work arrangements under one label.

## 5. Access and pay are different questions

The access map uses location quotients. A value below 1 means the group is under-represented in that occupation relative to the analytic sample.

Some high-median occupations show narrow access:

- `Diretores gerais e gerentes gerais`: median **R$ 11k**, female representation quotient **0.71**, preta/parda/indigena representation quotient **0.37**.
- `Dirigentes de servicos de tecnologia da informacao e comunicacoes`: median **R$ 10k**, female quotient **0.48**, race/color quotient **0.38**.
- `Engenheiros mecanicos`: median **R$ 10k**, female quotient **0.37**, race/color quotient **0.44**.

This does not prove exclusion mechanisms. It does show where a portfolio analyst should look next.

## 6. Presence does not guarantee parity inside the occupation

Women are present in some high-income occupations, but the internal gaps can remain large.

Examples from the deeper output:

- `Medicos especialistas`: women are about **44%** of workers, with mean income about **27% lower** than men's.
- `Dirigentes financeiros`: women are close to half of workers, with mean income about **43% lower** than men's.
- `Diretores gerais e gerentes gerais`: women are about **31%** of workers, with mean income about **53% lower** than men's.

These are descriptive gaps, not proof of equal-work pay differences. PNAD does not observe same company, exact seniority, bonus structure or contract detail. But the pattern is too important to ignore.

## Best one-sentence takeaway

Brazil's wage ranking is less a ladder and more a set of hidden wage architectures: some occupations pay well because the middle is high, some because the top tail pulls the average upward, and much of inequality remains inside the occupation label itself.
