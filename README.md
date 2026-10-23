# Data Engineering Projects

Hands-on projects from my path to becoming a data engineer. Each project keeps the code, the result, and the process that got there, including the bugs, wrong turns and fixes along the way.

## Contents

- [Projects](#projects)
- [How each project is organized](#how-each-project-is-organized)
- [Skills practiced](#skills-practiced)
- [Repository structure](#repository-structure)

## Projects

### 01 · TMDB movie analysis with the Linux command line

Analysis of ~10,800 movies answered entirely with shell tools. ✅ Done

- [README](01-tmdb-cli-analysis/README.md) - The questions, the results, and how to run the analysis.
- [Source](01-tmdb-cli-analysis/src/tmdb_analysis.sh) - Bash script for the full pipeline.
- Tools: Bash, `awk`, `sort`, `cut`, `uniq`, Miller (`mlr`)

### 02 · Tiki product scraper

Collects ~200,000 products from the Tiki API into batched JSON files with cleaned descriptions and an error log. 🚧 In progress

- [README](02-tiki-product-scraper/README.md) - The problem, the result, and how to run it.
- [Step-by-step guide](02-tiki-product-scraper/docs/GUIDE.md) - The solution built level by level, each level starting with a problem to think about first.
- [Runbook](02-tiki-product-scraper/docs/RUNBOOK.md) - Commands for running, monitoring and resuming the scraper.
- [Source](02-tiki-product-scraper/src/scraper.py) - The production scraper (v5).
- Tools: Python, `requests`, BeautifulSoup, `tmux`, Git

## How each project is organized

```
NN-project-name/
├── README.md   # start here: problem, result, how to run, links to docs
├── docs/       # guides, runbooks, notes
└── src/        # scripts and code
```

- **Start at the README.** It links to every document you need.
- **Process over polish.** Each project keeps the mistakes I hit and how I solved them, because that is where most of the learning happened.
- **No data in Git.** Raw data and generated output are not committed. Each README explains how to get or regenerate them.

## Skills practiced

- **Linux & shell** - File system navigation, text processing pipelines, `tmux`, processes, logs.
- **Data extraction** - Calling REST APIs, rate limiting, handling blocks and errors, circuit breakers.
- **Data cleaning** - HTML to text, deduplication, input validation.
- **Pipeline reliability** - Batching, checkpoints, atomic writes, resumable runs, reconciliation checks.
- **Git & GitHub** - Commits, `.gitignore`, `git subtree`, restructuring a repository without losing history.

## Repository structure

```
data-engineering-projects/
├── 01-tmdb-cli-analysis/
├── 02-tiki-product-scraper/
├── .gitignore    # shared rules: data, outputs and virtual environments stay out of Git
└── README.md
```
