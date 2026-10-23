# =====================================================================
# TMDB movie analysis with the Linux command line
# Author: Nguyen Thi Kim Tuyen
# Requires: wget, mlr (Miller), awk, sort, cut, tr, uniq, grep
# Usage (from the project folder): bash src/tmdb_analysis.sh
# =====================================================================

mkdir -p output

# ---------------------------------------------------------------------
# 0. Download the original data
# ---------------------------------------------------------------------
wget https://raw.githubusercontent.com/yinghaoz1/tmdb-movie-dataset-analysis/master/tmdb-movies.csv

# ---------------------------------------------------------------------
# 1. Clean: CSV -> TSV
#    Text columns (overview, tagline, cast, ...) contain commas and
#    line breaks inside quotes "...", so splitting on ',' goes wrong.
#    Miller reads the CSV correctly and writes each movie on one line.
# ---------------------------------------------------------------------
mlr --icsv --otsv cat tmdb-movies.csv > tmdb.tsv

# Check: every line must have 21 columns (expected result: 10867 21)
echo "== Check: number of columns per line =="
awk -F'\t' '{print NF}' tmdb.tsv | sort -n | uniq -c

# Columns: 4 budget | 5 revenue | 6 original_title | 7 cast | 9 director
#          14 genres | 16 release_date (m/d/yy) | 17 vote_count
#          18 vote_average | 19 release_year

# ---------------------------------------------------------------------
# Q1. Sort movies by release date, newest first -> save a new file
#     m/d/yy dates can't be sorted as text, so build a YYYYMMDD key
#     (year from release_year), sort by the key, then remove it.
# ---------------------------------------------------------------------
head -1 tmdb.tsv > output/movies_sorted_by_date.tsv
tail -n +2 tmdb.tsv | awk -F'\t' '{ split($16, d, "/"); printf "%04d%02d%02d\t%s\n", $19, d[1], d[2], $0 }' | sort -t$'\t' -k1,1r | cut -f2- >> output/movies_sorted_by_date.tsv
echo
echo "== Q1: 5 newest movies (file: output/movies_sorted_by_date.tsv) =="
head -6 output/movies_sorted_by_date.tsv | cut -f6,16

# ---------------------------------------------------------------------
# Q2. Movies with vote_average > 7.5 -> save a new file
# ---------------------------------------------------------------------
awk -F'\t' 'NR==1 || $18 > 7.5' tmdb.tsv > output/movies_rating_above_7_5.tsv
echo
echo "== Q2: lines in output/movies_rating_above_7_5.tsv (including 1 header line) =="
wc -l output/movies_rating_above_7_5.tsv

# ---------------------------------------------------------------------
# Q3. Movies with the highest and lowest revenue
#     revenue = 0 means missing data -> excluded from "lowest"
# ---------------------------------------------------------------------
cut -f5,6 tmdb.tsv | tail -n +2 | sort -t$'\t' -k1,1n > output/revenue_sorted.tsv
echo
echo "== Q3: highest revenue =="
tail -1 output/revenue_sorted.tsv
echo "== Q3: movies with revenue = 0 (missing data) =="
awk -F'\t' '$1 == 0' output/revenue_sorted.tsv | wc -l
echo "== Q3: lowest revenue (revenue = 0 excluded as missing data) =="
awk -F'\t' '$1 > 0' output/revenue_sorted.tsv | head -3

# ---------------------------------------------------------------------
# Q4. Total revenue of all movies
# ---------------------------------------------------------------------
echo
echo "== Q4: total revenue (USD) =="
awk -F'\t' 'NR > 1 { s += $5 } END { print s }' tmdb.tsv

# ---------------------------------------------------------------------
# Q5. Top 10 movies by profit (revenue - budget),
#     only movies with both budget and revenue
# ---------------------------------------------------------------------
echo
echo "== Q5: top 10 movies by profit =="
awk -F'\t' 'NR > 1 && $4 > 0 && $5 > 0 { print $5 - $4 "\t" $6 }' tmdb.tsv | sort -t$'\t' -k1,1nr | head -10 > output/top10_profit.tsv
awk -F'\t' '{
      v = $1
      if      (v >= 1e9) s = sprintf("$%.2fB", v / 1e9)
      else if (v >= 1e6) s = sprintf("$%.2fM", v / 1e6)
      else if (v >= 1e3) s = sprintf("$%.2fK", v / 1e3)
      else               s = "$" v
      print s "\t" $2
    }' output/top10_profit.tsv

# ---------------------------------------------------------------------
# Q6. Director with the most movies and actor in the most movies
#     Split cells with several values (A|B) and drop empty values before counting
# ---------------------------------------------------------------------
echo
echo "== Q6: directors with the most movies =="
cut -f9 tmdb.tsv | tail -n +2 | tr '|' '\n' | grep -v '^$' | sort | uniq -c | sort -nr | head -5
echo "== Q6: actors in the most movies =="
cut -f7 tmdb.tsv | tail -n +2 | tr '|' '\n' | grep -v '^$' | sort | uniq -c | sort -nr | head -5

# ---------------------------------------------------------------------
# Q7. Number of movies per genre (a movie can have several genres)
# ---------------------------------------------------------------------
echo
echo "== Q7: movies per genre =="
cut -f14 tmdb.tsv | tail -n +2 | tr '|' '\n' | grep -v '^$' | sort | uniq -c | sort -nr
echo "== Q7: movies without a genre =="
cut -f14 tmdb.tsv | tail -n +2 | grep -c '^$'

# ---------------------------------------------------------------------
# Q8. Idea: data quality analysis (details in README, section 4)
#
# Problems found during the project:
#  1. Commas inside quoted text: 9,173 / 10,879 lines split wrongly on commas
#  2. Line breaks inside the overview column: 10,879 lines but only 10,866 movies
#  3. Date format m/d/yy: can't be sorted as text, 2-digit year has no century
#  4. Revenue = 0 (missing data): 6,016 movies
#  5. Empty director or genre: 44 movies without director, 23 without genre
#  6. Broken characters (mojibake), e.g. â€œ
# ---------------------------------------------------------------------
