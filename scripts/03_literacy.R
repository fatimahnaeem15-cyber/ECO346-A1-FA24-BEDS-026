# 03_literacy.R -- Question 3 (and the redesign for Question 4):
# weighted literacy rate by five-year age band, women and men.
# Variant 2 = Sindh rural (prov_code 3, urban_rural 1).

suppressPackageStartupMessages({library(ggplot2); library(dplyr)})

# Move to the repo root (the folder above scripts/) so relative paths work from anywhere
cmd    <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", cmd[grepl("^--file=", cmd)])
if (length(script) == 1) setwd(file.path(dirname(normalizePath(script)), ".."))
stopifnot("Cannot find data/pslm_person_subset.csv: run from the repo root" =
            file.exists("data/pslm_person_subset.csv"))
dir.create("figures", showWarnings = FALSE)
dir.create("tables",  showWarnings = FALSE)

# Read the local CSVs and attach hhweight, prov_code and urban_rural by hhid
persons    <- read.csv("data/pslm_person_subset.csv")
households <- read.csv("data/pslm_hh_subset.csv")
keep       <- c("hhid", "hhweight", "prov_code", "urban_rural")
merged     <- merge(persons, households[, keep], by = "hhid", all.x = TRUE)

# Literacy sample: rural Sindh, aged 10 to 64, literate not missing
lit <- merged[which(merged$prov_code == 3 & merged$urban_rural == 1 &
                    merged$age >= 10 & merged$age <= 64 & !is.na(merged$literate)), ]

# Five-year bands 10-14, ..., 60-64, each plotted at its midpoint (12, 17, ..., 62)
lit$band  <- (lit$age - 10) %/% 5            # 0, 1, ..., 10
lit$start <- 10 + 5 * lit$band
lit$mid   <- lit$start + 2
lit$sex_f <- ifelse(lit$sex == 1, "Men", "Women")

# One row per band and sex: unweighted n and weighted literacy rate in percent
cells <- lit |>
  group_by(start, mid, sex_f) |>
  summarise(n = n(), rate = 100 * weighted.mean(literate, hhweight), .groups = "drop") |>
  mutate(thin = n < 30)                       # thin cell: fewer