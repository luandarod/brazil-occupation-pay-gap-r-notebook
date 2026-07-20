# Findings Worth Reading Twice

The headline ranking is only the front door. Once the PNAD microdata are weighted and the occupation labels are joined back in, a few less obvious patterns show up.

## 1. The top occupation is not the most "typical" high-income occupation

`Diretores gerais e gerentes gerais` rank first by average income, at about **R$ 22.4k** per month. The weighted median is **R$ 11k**.

That gap is the clue. A mean twice the median usually means the upper tail is doing a lot of work. Some directors earn very high amounts, and the average moves with them. For a worker asking "what does someone in this occupation usually earn?", the median tells a colder story.

`Medicos especialistas` look steadier. They rank second by mean income, around **R$ 19.3k**, but their weighted median is **R$ 15k**. Lower mean, higher middle. That is a more compressed distribution near the top.

## 2. Legal occupations have a long upper tail

Several law-related occupations sit high in the ranking, but the mean-median gap is large.

Among the top 50 occupations, `Profissionais de nivel medio do direito e servicos legais e afins` have one of the highest mean-to-median ratios: about **2.05**. `Advogados e juristas` are also pulled upward, with a mean around **R$ 9.3k** and a median around **R$ 5k**.

The project should not read that as a problem by itself. It reads as heterogeneity. Legal work likely mixes public jobs, private practice, seniority, geography and very different kinds of contracts under labels that look tidy on a chart.

## 3. Some high-ranking occupations are statistically noisier than they look

The confidence interval for `Diretores gerais e gerentes gerais` is wide: roughly **R$ 15.7k to R$ 29.1k** for the mean. That is not a small footnote. It means the exact top rank is less stable than the point estimate makes it feel.

The same caution applies to small, specialized groups near the top. A clean sorted bar chart can hide how much uncertainty is behind each dot.

## 4. Representation and pay do not move together neatly

In the top 15 occupations, women are estimated to be a majority in some groups. Two examples:

- `Profissionais em direito nao classificados anteriormente`: about **56% women**
- `Medicos gerais`: about **54% women**

But women being present in a high-income occupation does not mean the income gap disappears. Among `Medicos especialistas`, women are about **44%** of workers in the composition table, yet their estimated mean income is about **27% lower** than men's within that occupation group.

That is one of the stronger portfolio angles: access to the occupation and pay inside the occupation are related questions, but not the same question.

## 5. The "manager/director" label hides different stories

Management roles dominate the top of the ranking, but they are not one pattern.

`Diretores gerais e gerentes gerais` have a very high mean, wide uncertainty and a large gender gap. `Dirigentes financeiros` have a lower mean than the top directors but a sharper gender gap among the reliable cells. `Dirigentes de vendas e comercializacao` sit lower in the top group, with a different composition again.

So the better question is not "are managers paid more?" The better question is which kind of management role, with which composition, and how stable the estimate is.

## 6. The model says occupation matters, but it does not erase everything

The descriptive model without occupation fixed effects estimates lower income associated with being a woman, being in the preta/parda/indigena group, and being in an informal/autonomous proxy category. When a weighted sensitivity model adds occupation fixed effects, those associations shrink but do not vanish.

This is not causal evidence. It is a useful warning for interpretation: part of the gap is connected to who is sorted into which occupations, and part remains visible even after comparing workers within detailed occupation groups.

## Best one-sentence takeaway

Brazil's wage ranking is less a ladder and more a map of uneven distributions. Some occupations are high because the middle is high. Others are high because the top tail pulls the average upward.
