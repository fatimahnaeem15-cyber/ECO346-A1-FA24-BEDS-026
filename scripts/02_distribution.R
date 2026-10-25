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
# expect 1440, 4500, 4295, 1000, 15500, 15.50, 1

rs <- function(v) paste0("Rs ", format(round(v), big.mark = ",", trim = TRUE))

# Weighted histogram: bins 0.1 wide in log10 units, vertical axis = density per log10 unit
base <- ggplot(inside, aes(x = logx, weight = hhweight)) +
  geom_histogram(aes(y = after_stat(density)), binwidth = 0.1, boundary = 2,
                 closed = "left", fill = "#1f4e79", colour = "white")

bins <- ggplot_build(base)$data[[1]]
cat("Area under histogram (should be 1):",
    round(sum(bins$density * (bins$xmax - bins$xmin)), 4), "\n")
top <- max(bins$density)

p <- base +
  geom_vline(xintercept = log10(c(w_median, p90)), linetype = "dashed",
             colour = "#b5532a", linewidth = 0.7) +
  annotate("text", x = log10(w_median) - 0.04, y = top * 1.12, hjust = 1, vjust = 0,
           colour = "#b5532a", fontface = "bold", size = 3.8,
           label = paste0("Weighted median\n", rs(w_median))) +
  annotate("text", x = log10(p90) + 0.04, y = top * 1.12, hjust = 0, vjust = 0,
           colour = "#b5532a", fontface = "bold", size = 3.8,
           label = paste0("90th percentile\n", rs(p90))) +
  scale_x_continuous(breaks = 2:6, limits = c(2, 6),
                     labels = c("Rs 100", "Rs 1,000", "Rs 10,000",
                                "Rs 100,000", "Rs 1,000,000")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.25))) +
  labs(title = paste0("Half of rural Sindh's students cost their families under ",
                      rs(w_median), " a year,\nbut one in ten costs over ", rs(p90)),
       x = "Annual spending on the student's education (rupees, log scale)",
       y = "Density per log10 unit",
       caption = paste0("Source: PSLM 2019-20, person file merged with household file. ",
                        "Sample: ", format(n_students, big.mark = ","),
                        " students (ed_total > 0), rural Sindh.\n",
                        n_excluded, " student(s) outside Rs 100 - Rs 1,000,000 excluded. ",
                        "Weighted by hhweight; bins 0.1 wide in log10 units.")) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        plot.title.position = "plot", plot.caption.position = "plot",
        plot.title   = element_text(face = "bold"),
        plot.caption = element_text(hjust = 0, size = 9, colour = "grey30"))

ggsave("figures/distribution.svg", p, width = 9, height = 5.8)