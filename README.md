# ECO346 Assignment 1: Education Spending and Literacy in Rural Sindh

**Student:** FA24-BEDS-026 | **Section:** B | **Course:** Data Visualization Techniques for Economists, COMSATS University Islamabad, Lahore Campus

**Variant 2: Sindh rural.** The registration number ends in 26, and 26 = 3 x 8 + 2, so the remainder is 2. Only persons living in rural Sindh (`prov_code` = 3, `urban_rural` = 1) are used.

## Contents

1. [Repository and how to reproduce](#1-repository-and-how-to-reproduce)
2. [The distribution: education spending](#2-the-distribution-education-spending)
3. [The relationship: literacy by age and sex](#3-the-relationship-literacy-by-age-and-sex)
4. [The makeover: default and redesign](#4-the-makeover-default-and-redesign)
5. [A second language: Python](#5-a-second-language-python)
6. [Presentation](#6-presentation)

## Data and definitions

- **Source:** Pakistan Bureau of Statistics, PSLM 2019-20 (`data/pslm_person_subset.csv`, `data/pslm_hh_subset.csv`).
- **Merge:** the person file has no weight, province or area, so `hhweight`, `prov_code` and `urban_rural` are attached from the household file by `hhid`.
- **Weights:** every statistic is weighted by `hhweight`. A weighted mean is sum(w x) / sum(w).
- **Weighted quantile:** sort by x, compute the cumulative share of weight, and take the smallest x whose share reaches or exceeds p. R's built-in `quantile()` is not used.
- **Students (Question 2):** persons in the variant with `ed_total` > 0 (annual spending on that person's education, in rupees).
- **Literacy sample (Questions 3 to 5):** persons in the variant aged 10-64 with non-missing `literate`.
- **Age bands:** five years wide, 10-14 to 60-64 (eleven bands), plotted at their midpoints (12, 17, ..., 62). A cell with fewer than 30 unweighted observations is thin.
- **Rounding:** rupees to the nearest whole rupee, percentages to one decimal.

## 1. Repository and how to reproduce

```
ECO346-A1-FA24-BEDS-026/
|-- README.md                        this file
|-- data/
|   |-- pslm_person_subset.csv
|   `-- pslm_hh_subset.csv
|-- scripts/
|   |-- 01_default.R                 default scatterplot (Question 4)
|   |-- 02_distribution.R            weighted histogram (Question 2)
|   |-- 03_literacy.R                literacy figure and band table (Questions 3, 4)
|   `-- 04_second_language.py        Python band table and figure (Question 5)
|-- figures/
|   |-- default.svg
|   |-- distribution.svg
|   |-- literacy_by_age.svg
|   `-- literacy_by_age_python.svg
|-- tables/
|   |-- band_table_R.csv
|   `-- band_table_python.csv
`-- slides/
    `-- FA24-BEDS-026.pptx
```

Run the scripts in this order. They find the repository root themselves, need no internet connection, read the local copies in `data/`, and save every figure as SVG.

```
Rscript scripts/01_default.R
Rscript scripts/02_distribution.R
Rscript scripts/03_literacy.R
python scripts/04_second_language.py
```

Requirements: R with `ggplot2`, `svglite` and `dplyr`; Python with `pandas`, `numpy` and `matplotlib`.

## 2. The distribution: education spending

![Weighted histogram of annual education spending, rural Sindh](figures/distribution.svg)

*Script: `scripts/02_distribution.R`. Weighted histogram on a log scale, bins 0.1 wide in log10 units from 2.0 to 6.0 (Rs 100 to Rs 1,000,000). The vertical axis is density per log10 unit. Dashed lines mark the weighted median and the weighted 90th percentile.*

| Statistic | Value |
|---|---|
| Number of students | 1,440 |
| Weighted median | Rs 4,500 |
| Unweighted median | Rs 4,295 |
| Weighted 10th percentile | Rs 1,000 |
| Weighted 90th percentile | Rs 15,500 |
| Ratio of 90th to 10th percentile | 15.50 |
| Students excluded from the histogram (outside Rs 100 to Rs 1,000,000) | 1 |

**What the figure shows (76 words).** Most students cost their household a few thousand rupees a year, with a long right tail: the middle 80% lie between Rs 1,000 and Rs 15,500, a 15.5-fold spread. The weighted median (Rs 4,500) is about 5% above the unweighted one (Rs 4,295). The two differ because students from the lowest-weight third of households, who are over-represented in the sample, have a median of Rs 4,000 against Rs 4,500 elsewhere; weighting corrects that, but only slightly.

## 3. The relationship: literacy by age and sex

![Weighted literacy rate by age band, women and men, rural Sindh](figures/literacy_by_age.svg)

*Script: `scripts/03_literacy.R`. Weighted literacy rate (0 to 100 percent) against age band at the band midpoints, with women and men as two series of markers joined by lines. Each series is labelled at its end, and the band with the largest gap is annotated. Hollow markers would mark thin cells; none occur because the smallest cell has 77 observations.*

Literacy sample: 7,171 persons. `n` is the unweighted number of persons; rates are weighted percentages. The same table is in `tables/band_table_R.csv`.

| Band | Midpoint | Women n | Women literate (%) | Men n | Men literate (%) | Gap (points) |
|---|---|---|---|---|---|---|
| 10-14 | 12 | 529 | 35.5 | 718 | 57.6 | 22.1 |
| 15-19 | 17 | 446 | 28.0 | 548 | 59.5 | 31.5 |
| 20-24 | 22 | 455 | 23.4 | 422 | 58.5 | 35.1 |
| 25-29 | 27 | 430 | 24.6 | 419 | 53.4 | 28.9 |
| 30-34 | 32 | 399 | 17.7 | 382 | 60.2 | 42.5 |
| 35-39 | 37 | 319 | 19.5 | 391 | 55.5 | 36.0 |
| 40-44 | 42 | 285 | 13.2 | 274 | 51.2 | 38.0 |
| 45-49 | 47 | 198 | 9.1 | 221 | 49.9 | 40.8 |
| 50-54 | 52 | 152 | 7.2 | 208 | 42.4 | 35.3 |
| 55-59 | 57 | 98 | 9.6 | 100 | 40.0 | 30.4 |
| 60-64 | 62 | 77 | 6.8 | 100 | 36.4 | 29.6 |

(The gap is computed from unrounded rates, so it can differ by 0.1 from the difference of the two rounded columns.)

**Key numbers**

| | Women | Men |
|---|---|---|
| Aged 15-19 | 28.0% | 59.5% |
| Aged 55-59 | 9.6% | 40.0% |

The band with the largest gap is **30-34**, where men lead women by 42.5 percentage points.

**Interpretation (81 words).** Women trail men in every age band, and the gap is persistent: 31.5 points at 15-19, 30.4 at 55-59, and 42.5 at its peak, 30-34. Women's literacy falls from 28.0% in the late teens to 9.6% in the late fifties, men's from 59.5% to 40.0%. Because this is one cross-section, older bands are older birth cohorts, so the slope mixes ageing with generational change. The figure cannot tell us why girls are less literate: it shows the outcome, not the cause.

## 4. The makeover: default and redesign

| Default (R, nothing added) | Redesign (Question 3) |
|---|---|
| ![Default scatterplot](figures/default.svg) | ![Redesigned figure](figures/literacy_by_age.svg) |

*The default is `ggplot(data, aes(age, literate)) + geom_point()` on the literacy sample, produced by `scripts/01_default.R` and committed before the redesign.*

**Explanation of the redesign (122 words).** Three changes. (1) Conditional means: the default stacks 7,171 zeros and ones on two rows, so points overplot and hide how many sit where; I plot the weighted mean of literate in each five-year band, turning a binary outcome into a readable proportion. (2) Perceptual ranking: position on one common 0-100% axis is the most accurately judged channel, so women and men are two lines compared by position and labelled at their ends instead of through a legend. (3) Data-ink and honesty: grey panel removed, a finding as the title, a caption giving source and weights, and hollow markers for thin cells. The default shows what the redesign hides: individual observations at single years of age, so the spread within each band.

## 5. A second language: Python

![Python version of the literacy figure](figures/literacy_by_age_python.svg)

*Script: `scripts/04_second_language.py`. It recomputes the band table (`tables/band_table_python.csv`) and redraws the Question 3 figure. When `tables/band_table_R.csv` exists, it compares the two tables and prints the largest difference.*

| Women aged 15-19 | Literacy rate |
|---|---|
| From R | 28.0% |
| From Python | 28.0% |

The two band tables agree to one decimal place.

**A default that differed (64 words).** ggplot2 pads each axis by 5% beyond its limits, so 0-100 displays as roughly -5 to 105, while matplotlib's `set_ylim(0, 100)` adds no padding and the Python panel looked tighter. I set `ylim(-5, 105)` and fixed the x limits, ticks and labels to match R. I also formed bands by integer division in both languages, because `pd.cut` closes intervals on the right by default.

## 6. Presentation

Slides: [`slides/FA24-BEDS-026.pptx`](slides/FA24-BEDS-026.pptx), four slides covering the variant, the makeover (default and redesign side by side), and the finding I consider most important: women's literacy in rural Sindh is 28.0% at ages 15-19 against 59.5% for men, and the gap, at least 22 points in every band, is widest at ages 30-34 (42.5 points).
