cd "C:\Users\Ammy\Downloads\DVTE A1\ECO346-A1-FA24-BEDS-026"
$py = @'
"""04_second_language.py -- Question 5: the Question 3 band table and figure, in Python.
Variant 2 = Sindh rural (prov_code 3, urban_rural 1).
Run from anywhere:  python scripts/04_second_language.py   (run 03_literacy.R first)
"""
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
for folder in ("figures", "tables"):
    (ROOT / folder).mkdir(exist_ok=True)

# Read the local CSVs and attach hhweight, prov_code and urban_rural by hhid
persons = pd.read_csv(ROOT / "data" / "pslm_person_subset.csv")
households = pd.read_csv(ROOT / "data" / "pslm_hh_subset.csv")
households = households[["hhid", "hhweight", "prov_code", "urban_rural"]]
merged = persons.merge(households, on="hhid", how="left")

# Literacy sample: rural Sindh, aged 10 to 64, literate not missing
in_sample = ((merged.prov_code == 3) & (merged.urban_rural == 1)
             & (merged.age >= 10) & (merged.age <= 64) & merged.literate.notna())
lit = merged.loc[in_sample].copy()

# Five-year bands by integer division (pd.cut would close its intervals on the right)
lit["start"] = 10 + 5 * ((lit.age - 10) // 5).astype(int)
lit["who"] = np.where(lit.sex == 1, "men", "women")
lit["w_lit"] = lit.hhweight * lit.literate

# Weighted literacy rate = sum(w * literate) / sum(w), per band and sex
cells = lit.groupby(["start", "who"]).agg(n=("literate", "size"),
                                          w_lit=("w_lit", "sum"),
                                          w=("hhweight", "sum"))
cells["rate"] = 100 * cells.w_lit / cells.w
wide = cells[["n", "rate"]].unstack("who")

table = pd.DataFrame({
    "band":       [f"{s}-{s + 4}" for s in wide.index],
    "mid":        (wide.index + 2).to_numpy(),
    "n_women":    wide[("n", "women")].to_numpy(),
    "rate_women": wide[("rate", "women")].to_numpy(),
    "n_men":      wide[("n", "men")].to_numpy(),
    "rate_men":   wide[("rate", "men")].to_numpy(),
})
table["gap"] = table.rate_men - table.rate_women

out = table.copy()
out[["rate_women", "rate_men", "gap"]] = out[["rate_women", "rate_men", "gap"]].round(1)
out.to_csv(ROOT / "tables" / "band_table_python.csv", index=False)
print(out.to_string(index=False))

# Numbers for the Google Form
def pick(band, col):
    return f"{table.loc[table.band == band, col].iloc[0]:.1f}"

print("Women 15-19 (Python):", pick("15-19", "rate_women"))
print("Women 55-59:", pick("55-59", "rate_women"), "| Men 15-19:", pick("15-19", "rate_men"),
      "| Men 55-59:", pick("55-59", "rate_men"))
big = table.loc[table.gap.idxmax()]
print("Largest gap:", big.band, f"{big.gap:.1f}", "points")
print("Sample size:", len(lit), "| smallest cell:", int(cells.n.min()))

# Compare with the R table (written by 03_literacy.R) to one decimal place
r_file = ROOT / "tables" / "band_table_R.csv"
if r_file.exists():
    r = pd.read_csv(r_file)
    worst = max((r[c] - out[c]).abs().max() for c in ("rate_women", "rate_men"))
    same_n = bool((r.n_women == out.n_women).all() and (r.n_men == out.n_men).all())
    print(f"R vs Python: max abs difference in rates = {worst:.4f}; same n: {same_n}")
else:
    print("tables/band_table_R.csv not found: run scripts/03_literacy.R first.")

# The figure, matched to the R version
colour = {"women": "#b5532a", "men": "#1f4e79"}
label = {"women": "Women", "men": "Men"}
fig, ax = plt.subplots(figsize=(9, 5.8))
for who in ("women", "men"):
    x = table["mid"].to_numpy()
    y = table[f"rate_{who}"].to_numpy()
    thin = table[f"n_{who}"].to_numpy() < 30        # thin cell: fewer than 30 observations
    ax.plot(x, y, color=colour[who], linewidth=2, zorder=2)
    ax.scatter(x[~thin], y[~thin], s=55, color=colour[who], zorder=3)
    ax.scatter(x[thin], y[thin], s=55, facecolor="white", edgecolor=colour[who],
               linewidth=1.6, zorder=3)
    ax.text(x[-1] + 1, y[-1], label[who], color=colour[who], fontweight="bold",
            fontsize=12, va="center")                # direct label at the end of the series

# Annotation of the band with the largest gap
ax.annotate("", xy=(big.mid, big.rate_men), xytext=(big.mid, big.rate_women),
            arrowprops=dict(arrowstyle="<->", color="0.3"))
ax.text(big.mid + 1.5, (big.rate_men + big.rate_women) / 2,
        f"Largest gap, ages {big.band}:\n{big.gap:.1f} points",
        fontsize=10.5, va="center", color="0.15")

# ggplot2 pads a y scale by 5% on each side and matplotlib does not set the same padding
# when limits are given, so set the padded limits by hand to make the two figures match.
ax.set_xlim(10, 70)
ax.set_ylim(-5, 105)
ax.set_xticks(range(12, 63, 5))
ax.set_xticklabels([f"{s}-{s + 4}" for s in range(10, 61, 5)])
ax.set_yticks(range(0, 101, 20))
ax.set_yticklabels([f"{v}%" for v in range(0, 101, 20)])
ax.set_xlabel("Age band (years)")
ax.set_ylabel("Literate (weighted %)")
ax.grid(color="0.88", linewidth=0.8)
ax.set_axisbelow(True)
for side in ("top", "right", "left", "bottom"):
    ax.spines[side].set_visible(False)
ax.tick_params(length=0)

floor_gap = int(np.floor(table.gap.min()))
fig.suptitle(f"In rural Sindh, men are at least {floor_gap} percentage points more literate\n"
             "than women in every age band",
             x=0.01, ha="left", fontweight="bold", fontsize=13)
any_thin = bool(((table.n_women < 30) | (table.n_men < 30)).any())
caption = ("Source: PSLM 2019-20, person file merged with household file. "
           f"Sample: persons aged 10-64 in rural Sindh with non-missing literacy (n = {len(lit):,}).\n"
           "Weighted by hhweight; each marker is a five-year band plotted at its midpoint.\n"
           "Hollow markers: cells with fewer than 30 observations"
           + ("." if any_thin else " (none in this sample)."))
fig.text(0.01, 0.01, caption, fontsize=8.5, color="0.3", ha="left", va="bottom")
fig.subplots_adjust(left=0.08, right=0.97, top=0.85, bottom=0.22)
fig.savefig(ROOT / "figures" / "literacy_by_age_python.svg")
print("Saved figures/literacy_by_age_python.svg")
'@
$pypath = Join-Path (Get-Location) "scripts\04_second_language.py"
[System.IO.File]::WriteAllText($pypath, $py, (New-Object System.Text.UTF8Encoding($false)))
(Get-Item $pypath).Length