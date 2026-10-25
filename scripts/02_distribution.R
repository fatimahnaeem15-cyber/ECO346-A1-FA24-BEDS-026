# 02_distribution.R -- Question 2: weighted histogram of education spending.
# Variant 2 = Sindh rural (prov_code 3, urban_rural 1).

suppressPackageStartupMessages(library(ggplot2))

# Move to the repo root (the folder above scripts/) so relative paths work from anywhere
cmd    <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", cmd[grepl("^--file=", cmd)])
if (length(script) == 1) setwd(file.path(dirname(normalizePath(script)), ".."))
stopifnot("Cannot find data/pslm_person_subset.csv: run from the repo root" =
            file.exists("data/pslm_person_subset.csv"))
dir.create("figures", showWarnings = FALSE)

# Read the local CSVs and attach hhweight, prov_code and urban_rural by hhid
persons    <- read.csv("data/pslm_person_subset.csv")
households <- read.csv("data/pslm_hh_subset.csv")
keep       <- c("hhid", "hhweight", "prov_code", "urban_rural")
merged     <- merge(persons, households[, keep], by = "hhid", all.x = TRUE)

# Students: rural Sindh persons with ed_total > 0
students <- merged[which(merged$prov_code == 3 & merged$urban_rural == 1 &
                         merged$ed_total > 0), ]
students$logx <- log10(students$ed_total)

# Weighted quantile, exactly the assignment's definition:
# sort by x, cumulate the share of weight, take the smallest x where share >= p
wquantile <- function(x, w, p) {
  ord   <- order(x)
  x     <- x[ord]
  share <- cumsum(w[ord]) / sum(w)
  x[which(share >= p - 1e-12)[1]]
}

n_students <- nrow(students)
w_median   <- wquantile(students$ed_total, students$hhweight, 0.50)
u_median   <- median(students$ed_total)
p10        <- wquantile(students$ed_total, students$hhweight, 0.10)
p90        <- wquantile(students$ed_total, students$hhweight, 0.90)

# Histogram range: log10 from 2.0 to 6.0 (Rs 100 to Rs 1,000,000)
outside    <- students$logx < 2 | students$logx > 6
n_excluded <- sum(outside)
inside     <- students[!outside, ]

cat("Number of students:      ", n_students, "\n")
cat("Weighted median (Rs):    ", w_median, "\n")
cat("Unweighted median (Rs):  ", u_median, "\n")
cat("Weighted 10th pct (Rs):  ", p10, "\n")
cat("Weighted 90th pct (Rs):  ", p90, "\n")
cat("p90 / p10 ratio:         ", sprintf("%.2f", p90 / p10), "\n")
cat("Excluded from histogram: ", n_excluded, "\n")