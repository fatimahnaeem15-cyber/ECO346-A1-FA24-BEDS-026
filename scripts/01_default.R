# 01_default.R -- Question 4: R's default scatterplot of literate against age.
# Variant 2 = Sindh rural (prov_code 3, urban_rural 1).

suppressPackageStartupMessages(library(ggplot2))

# Move to the repo root (the folder above scripts/) so the relative paths below work
# whether this is run with Rscript from any folder or from a code runner.
cmd    <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", cmd[grepl("^--file=", cmd)])
if (length(script) == 1) setwd(file.path(dirname(normalizePath(script)), ".."))
stopifnot("Cannot find data/pslm_person_subset.csv: run from the repo root" =
            file.exists("data/pslm_person_subset.csv"))
dir.create("figures", showWarnings = FALSE)

# Read the two local CSVs and attach the household variables by hhid
persons    <- read.csv("data/pslm_person_subset.csv")
households <- read.csv("data/pslm_hh_subset.csv")
keep       <- c("hhid", "hhweight", "prov_code", "urban_rural")
merged     <- merge(persons, households[, keep], by = "hhid", all.x = TRUE)

# Literacy sample: rural Sindh, aged 10 to 64, literate not missing
in_variant <- merged$prov_code == 3 & merged$urban_rural == 1
in_range   <- merged$age >= 10 & merged$age <= 64
has_lit    <- !is.na(merged$literate)
lit        <- merged[which(in_variant & in_range & has_lit), ]
cat("Literacy sample size:", nrow(lit), "\n")   # expect 7171

# The default figure: nothing added
p <- ggplot(lit, aes(age, literate)) + geom_point()
ggsave("figures/default.svg", p, width = 7, height = 4.5)