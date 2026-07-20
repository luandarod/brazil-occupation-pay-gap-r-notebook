# Literature Review

This is a scoped reading list, not a formal systematic review. The goal is to keep the notebook honest: useful for a portfolio, careful enough not to overstate what the data can say.

## Why These Sources Matter

The Folha article gives the project its public hook. IBGE gives the microdata and the survey design. OECD and ILO help define wage gaps without stretching the language. Brazilian studies on occupation, race and gender explain why a simple ranking is too thin.

The deeper version of the project uses the literature in a more specific way: occupational segregation motivates the access layer, inequality research motivates the between/within decomposition, and wage-gap references keep the language descriptive rather than causal.

## Sources Used

1. **IBGE - PNAD Continua Trimestral**  
   Main source for the survey microdata.  
   https://www.ibge.gov.br/estatisticas/sociais/saude/9173-pesquisa-nacional-por-amostra-de-domicilios-continua-trimestral.html

2. **IBGE - PNAD Continua Q1 2026 labor-market release**  
   Gives context for the quarter analyzed, including unemployment, informality and income indicators.  
   https://agenciadenoticias.ibge.gov.br/agencia-sala-de-imprensa/2013-agencia-de-noticias/releases/46676-pnad-continua-trimestral-desocupacao-sobe-em-15-das-27-ufs-no-1-trimestre-de-2026

3. **PNADcIBGE R package**  
   Used to download and prepare PNAD Continua microdata in R.  
   https://cran.r-project.org/web/packages/PNADcIBGE/index.html

4. **OECD - Gender wage gap indicator**  
   Useful for keeping the gap definition clear: adjusted or unadjusted, mean or median, monthly or hourly.  
   https://www.oecd.org/en/data/indicators/gender-wage-gap.html

5. **ILO - Global Wage Report 2018/19**  
   A strong reference for the warning that "unexplained" does not automatically mean discrimination.  
   https://www.ilo.org/publications/global-wage-report-201819-what-lies-behind-gender-pay-gaps

6. **IPEA - Retrato das Desigualdades de Genero e Raca**  
   Brazilian reference for gender and race/color inequality.  
   https://www.ipea.gov.br/retrato/

7. **IPEA - Desigualdades no mercado de trabalho e pandemia da Covid-19**  
   Useful background for PNAD-based labor-market inequality in Brazil.  
   https://portalantigo.ipea.gov.br/agencia/images/stories/PDFs/TDs/210825_td_2684.pdf

8. **Madalozzo, R. (2010). Occupational segregation and the gender wage gap in Brazil. Economia Aplicada, 14(2), 147-168.**  
   DOI: https://doi.org/10.1590/S1413-80502010000200002

9. **Silveira, L. S. & Leao, N. (2021). Segregacao ocupacional e diferenciais de renda por genero e raca no Brasil. Revista Brasileira de Estudos de Populacao, 38.**  
   DOI: https://doi.org/10.20947/S0102-3098a0151

10. **Campante, F. R., Crespo, A. R. V. & Leite, P. G. P. G. (2004). Desigualdade salarial entre racas no mercado de trabalho urbano brasileiro. Revista Brasileira de Economia, 58(2), 185-210.**  
    DOI: https://doi.org/10.1590/S0034-71402004000200003

11. **Silveira, L. S. & Leao, N. (2021), repository/abstract on occupational segregation and income differentials by gender and race in Brazil.**
    Useful because it directly connects occupational segregation with gender/race income differences in Brazil.
    https://ideas.repec.org/a/eme/ijmpps/ijm-06-2019-0277.html

12. **World Bank Economic Review - Labor Market Experience and Falling Earnings Inequality in Brazil.**
    Useful background for decomposing labor-market inequality and thinking about what changes between groups and within groups.
    https://openknowledge.worldbank.org/bitstreams/e6de7622-2ab2-4b18-ad65-d1e2ea2f7676/download

13. **Salardi, P. - Wage Disparities by Gender and Race in Brazil: A Quantile Decomposition Analysis.**
    Relevant for the project's quantile-focused reading: the gap can look different at different parts of the distribution.
    https://conference.iza.org/conference_files/worldb2012/salardi_p7646.pdf

14. **IPEA PPP - Gender earnings gap in Brazil using PNAD Continua and quantile decomposition.**
    Brazilian applied reference for treating the gender earnings gap as distributional, not only average-based.
    https://www.ipea.gov.br/ppp/index.php/PPP/article/view/1670

15. **R `dineq` documentation for Gini/Theil decomposition reference.**
    The project implements the Theil logic directly, but this package documentation is a useful R-side reference for inequality decomposition workflows.
    https://www.rdocumentation.org/packages/dineq/versions/0.1.0/topics/gini_decomp

## How The Reading Changed The Notebook

The notebook does not stop at "top salaries". It checks medians, uncertainty, composition, distribution tails, access patterns and between/within inequality. It also avoids turning regression residuals into a discrimination claim.

The strongest literature link is occupational segregation. People are not randomly spread across occupations, and occupations are not uniform inside. That is why the project separates four questions: who is in the occupation, what the income distribution looks like, how much inequality sits between occupations, and what associations remain after basic controls.
