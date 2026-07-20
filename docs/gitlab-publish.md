# GitLab Publish Commands

Do not run these commands until the GitLab project exists and the local files have been checked.

Suggested project:

```text
https://gitlab.com/luanda-rodrigues/brazil-occupation-pay-gap-r-notebook
```

From this project root:

```powershell
git init
git add .
git commit -m "Add PNAD occupation wage gap R notebook"
git branch -M main
git remote add origin https://gitlab.com/luanda-rodrigues/brazil-occupation-pay-gap-r-notebook.git
git push -u origin main
```

Before pushing, run:

```powershell
Rscript R/validate_outputs.R
git status
git diff --stat
```

The repository should not include PNAD raw microdata, cache zips, extracted `PNADC_*.txt` files or social-post drafts.
