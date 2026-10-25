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
  mutate(thin = n < 30)                       # thin cell: fewer than 30 observations

# Wide band table for the README: one row per band
w <- subset(cells, sex_f == "Women"); m <- subset(cells, sex_f == "Men")
tab <- data.frame(band        = paste0(w$start, "-", w$start + 4),
                  mid         = w$mid,
                  n_women     = w$n,
                  rate_women  = round(w$rate, 1),
                  n_men       = m$n,
                  rate_men    = round(m$rate, 1))
tab$gap <- round(m$rate - w$rate, 1)
write.csv(tab, "tables/band_table_R.csv", row.names = FALSE)
print(tab)

# Numbers for the Google Form
pick <- function(b, col) sprintf("%.1f", tab[[col]][tab$band == b])
cat("Women 15-19:", pick("15-19", "rate_women"), "| Men 15-19:", pick("15-19", "rate_men"), "\n")
cat("Women 55-59:", pick("55-59", "rate_women"), "| Men 55-59:", pick("55-59", "rate_men"), "\n")
big <- tab[which.max(tab$gap), ]
cat("Largest gap:", big$band, "=", sprintf("%.1f", big$gap), "points\n")
cat("Sample size:", nrow(lit), "| smallest cell:", min(cells$n), "\n")
# expect 7171, 28.0 / 59.5, 9.6 / 40.0, largest gap 30-34 = 42.5, smallest cell 77

# The figure
cols  <- c(Women = "#b5532a", Men = "#1f4e79")
last  <- subset(cells, mid == max(mid))                   # last point of each series
solid <- subset(cells, !thin)
hollow <- subset(cells, thin)                             # empty here, as no cell is thin

cap <- paste0("Source: PSLM 2019-20, person file merged with household file. ",
              "Sample: persons aged 10-64 in rural Sindh with non-missing literacy (n = ",
              format(nrow(lit), big.mark = ","), ").\n",
              "Weighted by hhweight; each marker is a five-year band plotted at its midpoint.\n",
              "Hollow markers: cells with fewer than 30 observations",
              if (nrow(hollow) > 0) "." else " (none in this sample).")

p <- ggplot(cells, aes(mid, rate, colour = sex_f, group = sex_f)) +
  geom_line(linewidth = 0.9) +
  geom_point(data = solid,  shape = 16, size = 3.2) +
  geom_point(data = hollow, shape = 1,  size = 3.2, stroke = 1.2) +
  geom_text(data = last, aes(label = sex_f), hjust = 0, nudge_x = 1,
            fontface = "bold", size = 4.2) +
  annotate("segment", x = big$mid, xend = big$mid, y = big$rate_women, yend = big$rate_men,
           colour = "grey30", arrow = arrow(ends = "both", length = unit(0.08, "inches"))) +
  annotate("text", x = big$mid + 1.5, y = (big$rate_women + big$rate_men) / 2,
           hjust = 0, size = 3.8, colour = "grey20",
           label = paste0("Largest gap, ages ", big$band, ":\n", sprintf("%.1f", big$gap), " points")) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_x_continuous(breaks = seq(12, 62, 5), limits = c(10, 70), expand = expansion(0),
                     labels = paste0(seq(10, 60, 5), "-", seq(14, 64, 5))) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20),
                     labels = function(v) paste0(v, "%")) +
  labs(title = paste0("In rural Sindh, men are at least ", floor(min(tab$gap)),
                      " percentage points more literate\nthan women in every age band"),
       x = "Age band (years)", y = "Literate (weighted %)", caption = cap) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        plot.title.position = "plot", plot.caption.position = "plot",
        plot.title   = element_text(face = "bold"),
        plot.caption = element_text(hjust = 0, size = 9, colour = "grey30"))

ggsave("figures/literacy_by_age.svg", p, width = 9, height = 5.8)