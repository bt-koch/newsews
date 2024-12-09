rm(list=ls()); gc()
library(dplyr)

source("visualise/create_table.R")
source("config/environvars.R")

models <- list()

# =============================================================================.
# 1. Load and Prepare Data ----
# =============================================================================.

# 1.1 load data ----
cds <- read.csv(file.path(paths$path_refinitiv, "cds.csv"), sep = ";")

corpbonds <- read.csv(file.path(paths$path_refinitiv, "corpbonds.csv"), sep = ";") |> 
  select(Instrument, Date, Yield) |> 
  unique()

govbonds <- read.csv(file.path(paths$path_refinitiv, "govbonds.csv"), sep = ";") |> 
  select(Instrument, Date, Mid.Yield) |> 
  unique()

indices <- read.csv(file.path(paths$path_refinitiv, "indices.csv"), sep = ";") |> 
  select(Instrument, Date, Close.Price) |> 
  unique()

stocks <- read.csv(file.path(paths$path_refinitiv, "stocks.csv"), sep = ";") |> 
  select(Instrument, Date, Close.Price) |> 
  unique()

interest <- read.csv(file.path(paths$path_refinitiv, "interest.csv"), sep = ";") |> 
  select(Instrument, Date, Mid.Price) |> 
  unique()

sentiment_euro <- read.csv(file.path(paths$path_results, "sentiment_scores_refinitiv.csv"), sep = ";")

sentiment_swiss <- read.csv(file.path(paths$path_results, "sentiment_scores.csv"), sep = ";")

eurostr <- read.csv(file.path(paths$path_ecb, "euro_short_term_rate.csv")) |> 
  rename(date = 1, value = 3) |> 
  select("date", "value")

saron <- read.csv(file.path(paths$path_snb, "saron.csv"), sep = ";", skip = 3)

vsmi <- read.csv(file.path(paths$path_six, "vsmi.csv"), sep = ";")

meta_ric <- read.csv(file.path(paths$path_meta, "mapping_ric.csv"), sep = ";")

# 1.2 prepare weekly data ----
# dependent variables
cds <- cds |> 
  mutate(
    date = as.Date(date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(ric_cds, week) |> 
  slice_max(order_by = date, n = 1) |> 
  group_by(ric_cds) |> 
  mutate(
    cds = (value-lag(value))/lag(value) * 100
  ) |> 
  ungroup() |> 
  rename(bank = ric_equity) |> 
  select(bank, date, cds)

# sentiment indicator european sample
map_date_euro <- sentiment_euro |> 
  mutate(
    date = as.Date(date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |> 
  select(week, date) |> 
  unique()

sentiment_euro_w <- sentiment_euro |> 
  mutate(
    date = as.Date(date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(bank, week) |> 
  reframe(sentiment = mean(sentiment_score, na.rm = TRUE)) |> 
  group_by(bank) |> 
  mutate(
    sentiment_l1 = lag(sentiment, 1),
    sentiment_l2 = lag(sentiment, 2),
    sentiment_l3 = lag(sentiment, 3),
    sentiment_l4 = lag(sentiment, 4),
    sentiment_l5 = lag(sentiment, 5)
  ) |> 
  right_join(y = map_date_euro, by = "week") |> 
  mutate(
    date = date - 2
  ) |> 
  ungroup()

# sentiment indicator swiss sample
map_date_swiss <- sentiment_swiss |> 
  mutate(
    date = as.Date(date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |> 
  select(week, date) |> 
  unique()

sentiment_swiss_w <- sentiment_swiss |> 
  mutate(
    date = as.Date(date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(bank, week) |> 
  reframe(sentiment = mean(sentiment_score, na.rm = TRUE)) |> 
  group_by(bank) |> 
  mutate(
    sentiment_l1 = lag(sentiment, 1),
    sentiment_l2 = lag(sentiment, 2),
    sentiment_l3 = lag(sentiment, 3),
    sentiment_l4 = lag(sentiment, 4),
    sentiment_l5 = lag(sentiment, 5)
  ) |> 
  right_join(y = map_date_swiss, by = "week") |> 
  mutate(
    date = date - 2
  ) |> 
  ungroup()

# independent variables for cathart2020
stockmarket <- right_join(
  filter(indices, Instrument == ".FTEU1"),
  filter(govbonds, Instrument == "EU1YT=RR"),
  by = "Date"
) |>
  mutate(
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |> 
  mutate(
    date = as.Date(Date),
    marketreturn = (Close.Price-lag(Close.Price))/lag(Close.Price) * 100,
    stockmarket = marketreturn - Mid.Yield
  )

stockmarket_swiss <- right_join(
  filter(indices, Instrument == ".SSHI"),
  filter(govbonds, Instrument == "CH1YT=RR"),
  by = "Date"
) |>
  mutate(
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |> 
  mutate(
    date = as.Date(Date),
    marketreturn = (Close.Price-lag(Close.Price))/lag(Close.Price) * 100,
    stockmarket = marketreturn - Mid.Yield
  )


volatilitypremium <- right_join(
  filter(indices, Instrument == ".V2TX"),
  filter(indices, Instrument == ".FTEU1"),
  by = "Date"
) |> 
  mutate(
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |>
  mutate(
    date = as.Date(Date),
    vola = zoo::rollapply(Close.Price.y, width = 30, FUN = sd, fill = NA, align = "right"),
    volatilitypremium = Close.Price.x - vola
  )

vsmi <- vsmi |> 
  mutate(
    Date = as.Date(Date, format = "%d.%m.%Y"),
    Close.Price = Indexvalue
  )

volatilitypremium_swiss <- right_join(
  vsmi,
  filter(indices, Instrument == ".SSHI") |> mutate(Date = as.Date(Date)),
  by = "Date"
) |> 
  mutate(
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |>
  mutate(
    date = as.Date(Date),
    vola = zoo::rollapply(Close.Price.y, width = 30, FUN = sd, fill = NA, align = "right"),
    volatilitypremium = Close.Price.x - vola
  )

termpremium <- right_join(
  filter(interest, Instrument == "EURAB6E10Y=") |> mutate(date = as.Date(Date)),
  eurostr |> mutate(date = as.Date(date)),
  by = "date"
) |> 
  mutate(
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |>
  mutate(
    termpremium = Mid.Price - value
  )

termpremium_swiss <- right_join(
  filter(interest, Instrument == "CHFAB6L10Y=") |> mutate(date = as.Date(Date)),
  saron |> mutate(date = as.Date(Date)),
  by = "date"
) |> 
  mutate(
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |>
  mutate(
    termpremium = Mid.Price - Value
  )

treasurymarket <- govbonds |> 
  filter(Instrument == "EU5YT=RR") |> 
  mutate(
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |>
  mutate(
    treasurymarket = (Mid.Yield-lag(Mid.Yield))/lag(Mid.Yield) * 100
  )

treasurymarket_swiss <- govbonds |> 
  filter(Instrument == "CH5YT=RR") |> 
  mutate(
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |>
  mutate(
    treasurymarket = (Mid.Yield-lag(Mid.Yield))/lag(Mid.Yield) * 100
  )

investgradespread <- merge(
  x = filter(corpbonds, Instrument == ".MERER10"),
  y = filter(corpbonds, Instrument == ".MERER40"),
  by = "Date"
) |> 
  mutate(
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |>
  mutate(
    investgradespread = (Yield.x-Yield.y)/(lag(Yield.x)-lag(Yield.y))-1
  )

highyieldspread <- merge(
  x = filter(corpbonds, Instrument == ".MERER40"),
  y = filter(corpbonds, Instrument == ".MERHE10"),
  by = "Date"
) |> 
  mutate(
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |>
  mutate(
    highyieldspread = (Yield.x-Yield.y)/(lag(Yield.x)-lag(Yield.y))-1
  )

# independent variables for annaert2013
riskfree <- govbonds |> 
  filter(Instrument == "EU2YT=RR") |> 
  mutate(
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |> 
  mutate(
    riskfree = Mid.Yield - lag(Mid.Yield)
  ) |> 
  select(date, riskfree)

leverage <- stocks |> 
  mutate(
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(Instrument, week) |> 
  slice_max(order_by = date, n = 1) |> 
  group_by(Instrument) |> 
  mutate(
    leverage = (Close.Price-lag(Close.Price))/lag(Close.Price) * 100
  ) |> 
  ungroup() |> 
  rename(bank = Instrument) |> 
  select(bank, date, leverage)

equivol <- stocks |> 
  mutate(
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(Instrument) |> 
  mutate(
    return = (Close.Price-lag(Close.Price))/lag(Close.Price) * 100
  ) |> 
  # page 449 -> weekly historical sd
  group_by(Instrument, week) |>
  mutate(
    historic_sd = sd(return)
  ) |> 
  slice_max(order_by = date, n = 1) |> 
  group_by(Instrument) |> 
  mutate(
    # Standard deviation is in the same units as the mean.
    # So sd of returns is expressed in percent.
    equivol = historic_sd - lag(historic_sd)
  ) |> 
  ungroup() |> 
  rename(bank = Instrument) |> 
  select(bank, equivol, date)

termstructure <- merge(
  x = filter(govbonds, Instrument == "EU10YT=RR"),
  y = filter(govbonds, Instrument == "EU5YT=RR"),
  by = "Date"
) |>
  mutate(
    difference = Mid.Yield.x - Mid.Yield.y,
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  )  |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |> 
  mutate(
    termstructure = difference - lag(difference)
  ) |> 
  select(date, termstructure)

corpbondspread <- merge(
  x = filter(corpbonds, Instrument == ".MERER10"),
  y = filter(corpbonds, Instrument == ".MERER40"),
  by = "Date"
) |> 
  mutate(
    difference = Yield.x - Yield.y,
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |> 
  mutate(
    corpbondspread = difference - lag(difference)
  ) |> 
  select(date, corpbondspread)

marketreturn <- indices |> 
  filter(Instrument == ".FTEU1") |> 
  mutate(
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  )  |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |> 
  mutate(
    marketreturn = (Close.Price-lag(Close.Price))/lag(Close.Price)
  ) |> 
  select(date, marketreturn)

marketvola <- indices |> 
  filter(Instrument == ".V2TX") |> 
  mutate(
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  )  |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |> 
  mutate(
    marketvola = (Close.Price-lag(Close.Price))/lag(Close.Price) * 100
  ) |> 
  select(date, marketvola)

# 1.3 prepare daily data ----

# independent variables
mdd_window <- 14

calc_mdd <- function(close_price, date, w) {
  sapply(seq_along(date), function(x) {
    min_window <- min(close_price[date >= date[x] & date <= date[x] + w])
    (min_window - close_price[x]) / close_price[x]
  })
}

mdd <- stocks |> 
  group_by(Instrument) |> 
  mutate(
    date = as.Date(Date),
    mdd = calc_mdd(Close.Price, date, mdd_window)
  ) |> 
  ungroup() |> 
  merge(y = meta_ric, by.x = "Instrument", by.y = "ric")

stockreturn <- stocks |> 
  group_by(Instrument) |> 
  mutate(
    date = as.Date(Date),
    stockreturn = (Close.Price-lag(Close.Price))/lag(Close.Price)
  ) |> 
  ungroup() |> 
  merge(y = meta_ric, by.x = "Instrument", by.y = "ric") |> 
  rename(bank = query_bank) |> 
  select(bank, date, stockreturn)

cds_d <- read.csv(file.path(paths$path_refinitiv, "cds.csv"), sep = ";") |> 
  mutate(
    date = as.Date(date),
  ) |> 
  group_by(ric_cds, date) |> 
  slice_max(order_by = date, n = 1) |> 
  group_by(ric_cds) |> 
  mutate(
    cds = (value-lag(value))/lag(value) * 100
  ) |> 
  ungroup() |> 
  rename(bank = ric_equity) |> 
  select(bank, date, cds)


# dependent variables
n <- 5
sentiment_euro_d <- sentiment_euro |>
  mutate(
    date = as.Date(date),
    weekday = weekdays(date),
    date = if_else(weekday == "Saturday", date+2, date),
    date = if_else(weekday == "Sunday", date+1, date)
  ) |>
  filter(!weekday %in% c("Saturday", "Sunday")) |>
  group_by(bank, date) |>
  reframe(sentiment = mean(sentiment_score, na.rm = TRUE)) |>
  group_by(bank) |>
  mutate(
    sentiment = zoo::na.approx(sentiment, maxgap = 2, rule = 2),
    sentiment_wma = as.numeric(stats::filter(sentiment, (n:1)/sum(n:1), sides = 1))
  ) |> 
  ungroup()

sentiment_swiss_d <- sentiment_swiss |>
  mutate(
    date = as.Date(date),
    weekday = weekdays(date),
    date = if_else(weekday == "Saturday", date+2, date),
    date = if_else(weekday == "Sunday", date+1, date)
  ) |>
  filter(!weekday %in% c("Saturday", "Sunday")) |>
  group_by(bank, date) |>
  reframe(sentiment = mean(sentiment_score, na.rm = TRUE)) |>
  group_by(bank) |>
  mutate(
    sentiment = zoo::na.approx(sentiment, maxgap = 2, rule = 2),
    sentiment_wma = as.numeric(stats::filter(sentiment, (n:1)/sum(n:1), sides = 1))
  ) |> 
  ungroup()


# =============================================================================.
# 2. Is sentiment determinant of CDS spread? (Annaert 2013) ----
# =============================================================================.

dataset_annaert_euro <- sentiment_euro_w |> 
  left_join(y = meta_ric, by = c("bank" = "query_bank")) |> 
  left_join(y = cds, by = c("date", "ric" = "bank")) |> 
  left_join(y = riskfree, by = "date") |> 
  left_join(y = leverage, by = c("date", "ric" = "bank")) |> 
  left_join(y = equivol, by = c("date", "ric" = "bank")) |> 
  left_join(y = termstructure, by = "date") |> 
  left_join(y = corpbondspread, by = "date") |> 
  left_join(y = marketreturn, by = "date") |> 
  left_join(y = marketvola, by = "date") |> 
  select(
    date, bank, cds, riskfree, leverage, equivol, termstructure,
    corpbondspread, marketreturn, marketvola, sentiment
  ) |> 
  na.omit()

result_annaert_euro <- plm::plm(
  cds ~ riskfree + leverage + equivol + termstructure + corpbondspread + marketreturn + marketvola + sentiment,
  data = dataset_annaert_euro, index = c("bank", "date")
)

models[["annaert_euro"]] <- summary(result_annaert_euro)
models[["annaert_euro"]]["sample"] <- "European Banks"
models[["annaert_euro"]]["groups"] <- dataset_annaert_euro$bank |> unique() |> length()
models[["annaert_euro"]]["nobs"] <- nrow(dataset_annaert_euro)
models[["annaert_euro"]]["obsperiod"] <- paste(min(dataset_annaert_euro$date), "to", max(dataset_annaert_euro$date))

dataset_annaert_swiss <- sentiment_swiss_w |> 
  left_join(y = meta_ric, by = c("bank" = "query_bank")) |> 
  left_join(y = cds, by = c("date", "ric" = "bank")) |> 
  left_join(y = riskfree, by = "date") |> 
  left_join(y = leverage, by = c("date", "ric" = "bank")) |> 
  left_join(y = equivol, by = c("date", "ric" = "bank")) |> 
  left_join(y = termstructure, by = "date") |> 
  left_join(y = corpbondspread, by = "date") |> 
  left_join(y = marketreturn, by = "date") |> 
  left_join(y = marketvola, by = "date") |> 
  select(
    date, bank, cds, riskfree, leverage, equivol, termstructure,
    corpbondspread, marketreturn, marketvola, sentiment
  ) |> 
  na.omit()

result_annaert_swiss <- plm::plm(
  cds ~ riskfree + leverage + equivol + termstructure + corpbondspread + marketreturn + marketvola + sentiment,
  data = dataset_annaert_swiss, index = c("bank", "date")
)

models[["annaert_swiss"]] <- summary(result_annaert_swiss)
models[["annaert_swiss"]]["sample"] <- "Swiss Banks"
models[["annaert_swiss"]]["groups"] <- dataset_annaert_swiss$bank |> unique() |> length()
models[["annaert_swiss"]]["nobs"] <- nrow(dataset_annaert_swiss)
models[["annaert_swiss"]]["obsperiod"] <- paste(min(dataset_annaert_swiss$date), "to", max(dataset_annaert_swiss$date))

create_table(models[grep("annaert_*", names(models))], "Determinant of CDS spread", "cdsdet")


# =============================================================================.
# 3. Is sentiment predictor of CDS spread? (Cathart 2020) ----
# =============================================================================.

dataset_cathart_euro <- sentiment_euro_w |> 
  left_join(y = meta_ric, by = c("bank" = "query_bank")) |> 
  left_join(y = cds, by = c("date", "ric" = "bank")) |> 
  left_join(y = stockmarket, by = "date") |> 
  left_join(y = volatilitypremium, by = "date") |> 
  left_join(y = termpremium, by = "date") |> 
  left_join(y = treasurymarket, by = "date") |> 
  left_join(y = investgradespread, by = "date") |> 
  left_join(y = highyieldspread, by = "date") |>
  mutate(
    stockmarket_l1 = lag(stockmarket),
    volatilitypremium_l1 = lag(volatilitypremium),
    termpremium_l1 = lag(termpremium),
    treasurymarket_l1 = lag(treasurymarket),
    investgradespread_l1 = lag(investgradespread),
    highyieldspread_l1 = lag(highyieldspread)
  ) |> 
  select(
    sentiment,
    stockmarket_l1, volatilitypremium_l1, termpremium_l1, treasurymarket_l1,
    investgradespread_l1, highyieldspread_l1, bank, date, cds
  ) |> 
  na.omit() |> 
  mutate(
    bank = as.factor(bank),
    date = as.factor(date)
  ) |> 
  as.data.frame()

results_cathart_euro <- panelvar::pvarfeols(
  dependent_vars = c("cds", "sentiment"),
  lags = 5,
  exog_vars = c(
    "stockmarket_l1", "volatilitypremium_l1", "termpremium_l1",
    "treasurymarket_l1", "investgradespread_l1", "highyieldspread_l1"
  ),
  data = dataset_cathart_euro,
  panel_identifier = c("bank", "date")
)

models[["cathart_euro"]] <- summary(results_cathart_euro)
models[["cathart_euro"]]["sample"] <- "European Banks"
models[["cathart_euro"]]["obsperiod"] <- paste(min(as.Date(dataset_cathart_euro$date)), "to", max(as.Date(dataset_cathart_euro$date)))


dataset_cathart_swiss <- sentiment_swiss_w |> 
  left_join(y = meta_ric, by = c("bank" = "query_bank")) |> 
  left_join(y = cds, by = c("date", "ric" = "bank")) |> 
  left_join(y = stockmarket_swiss, by = "date") |> 
  left_join(y = volatilitypremium_swiss, by = "date") |> 
  left_join(y = termpremium_swiss, by = "date") |> 
  left_join(y = treasurymarket_swiss, by = "date") |> 
  left_join(y = investgradespread, by = "date") |> 
  left_join(y = highyieldspread, by = "date") |> 
  group_by(bank) |> 
  mutate(
    stockmarket_l1 = lag(stockmarket),
    volatilitypremium_l1 = lag(volatilitypremium),
    termpremium_l1 = lag(termpremium),
    treasurymarket_l1 = lag(treasurymarket),
    investgradespread_l1 = lag(investgradespread),
    highyieldspread_l1 = lag(highyieldspread)
  ) |> 
  ungroup() |> 
  select(
    bank, date, cds, sentiment,
    stockmarket_l1, volatilitypremium_l1, termpremium_l1, treasurymarket_l1,
    investgradespread_l1, highyieldspread_l1,
  ) |> 
  na.omit() |> 
  mutate(
    bank = as.factor(bank),
    date = as.factor(date)
  ) |> 
  as.data.frame()


results_cathart_swiss <- panelvar::pvarfeols(
  dependent_vars = c("cds", "sentiment"),
  lags = 5,
  exog_vars = c(
    "stockmarket_l1", "volatilitypremium_l1", "termpremium_l1",
    "treasurymarket_l1", "investgradespread_l1", "highyieldspread_l1"
  ),
  data = dataset_cathart_swiss,
  panel_identifier = c("bank", "date")
)

models[["cathart_swiss"]] <- summary(results_cathart_swiss)
models[["cathart_swiss"]]["sample"] <- "Swiss Banks"
models[["cathart_swiss"]]["obsperiod"] <- paste(min(as.Date(dataset_cathart_swiss$date)), "to", max(as.Date(dataset_cathart_swiss$date)))

create_table(models[grep("cathart_*", names(models))], "Panel VAR sentiment", "cdspvar")

oirfs <- panelvar::oirf(results_cathart_swiss, 8)

# ymin <- min(c(oirfs$cds, oirfs$sentiment))
# ymax <- max(c(oirfs$cds, oirfs$sentiment))
# 
# par(mfrow = c(2,2))
# plot(oirfs$cds[,1], type = "l", ylim = c(ymin, ymax), xlab = "", ylab = "")
# plot(oirfs$cds[,2], type = "l", ylim = c(ymin, ymax), xlab = "", ylab = "")
# plot(oirfs$sentiment[,1], type = "l", ylim = c(ymin, ymax), xlab = "", ylab = "")
# plot(oirfs$sentiment[,2], type = "l", ylim = c(ymin, ymax), xlab = "", ylab = "")

png(filename="tex/images/oirfs.png")
plot(oirfs)
dev.off()


# to do: schauen ob diese analyse getrieben durch einzelne gruppe?
test <- panelvar::pvarfeols(
  dependent_vars = c("cds", "sentiment"),
  lags = 5,
  exog_vars = c(
    "stockmarket_l1", "volatilitypremium_l1", "termpremium_l1",
    "treasurymarket_l1", "investgradespread_l1", "highyieldspread_l1"
  ),
  data = dataset_cathart_swiss |> filter(bank == "ubs"),
  panel_identifier = c("bank", "date")
)

# additional: granger causality test
# dataset_cds_d <- sentiment_swiss_d |> 
#   left_join(y = meta_ric, by = c("bank" = "query_bank")) |> 
#   left_join(y = cds_d, by = c("ric" = "bank", "date")) |>
#   select(bank, date, sentiment_wma, cds) |>
#   group_by(bank) |>
#   arrange(bank, date) |>
#   ungroup() |>
#   mutate(
#     bank = as.factor(bank),
#     date = as.factor(date)
#   ) |>
#   na.omit() |> 
#   as.data.frame()
# 
# dataset_cds_d_cs <- dataset_cds_d |> filter(bank == "credit_suisse")
# dataset_cds_d_ubs <- dataset_cds_d |> filter(bank == "ubs")
# 
# dataset_cds_d_cs$sentiment_wma <- dataset_cds_d_cs$sentiment
# dataset_cds_d_ubs$sentiment_wma <- dataset_cds_d_ubs$sentiment
# 
# results_granger_d <- data.frame()
# 
# for (i in 1:5) {
#   
#   cds_on_senti_cs <- lmtest::grangertest(
#     x = dataset_cds_d_cs$sentiment_wma, y = dataset_cds_d_cs$cds, order = i
#   )
#   
#   cds_on_senti_ubs <- lmtest::grangertest(
#     x = dataset_cds_d_ubs$sentiment_wma, y = dataset_cds_d_ubs$cds, order = i
#   )
#   
#   senti_on_cds_cs <- lmtest::grangertest(
#     x = dataset_cds_d_cs$cds, y = dataset_cds_d_cs$sentiment_wma, order = i
#   )
#   
#   senti_on_cds_ubs <- lmtest::grangertest(
#     x = dataset_cds_d_ubs$cds, y = dataset_cds_d_ubs$sentiment_wma, order = i
#   )
#   
#   results_granger_d <- rbind(results_granger_d, data.frame(
#     lags = i,
#     cds_on_senti_cs = cds_on_senti_cs$`Pr(>F)`[2],
#     senti_on_cds_cs = senti_on_cds_cs$`Pr(>F)`[2],
#     cds_on_senti_ubs = cds_on_senti_ubs$`Pr(>F)`[2],
#     senti_on_cds_ubs = senti_on_cds_ubs$`Pr(>F)`[2]
#   ))
# }
# 
# create_table_granger(results_granger_d, "Granger Causality Test, daily", "granger_daily")

dataset_cds_d_cs <- dataset_cathart_swiss |> filter(bank == "credit_suisse")
dataset_cds_d_ubs <- dataset_cathart_swiss |> filter(bank == "ubs")

dataset_cds_d_cs$sentiment_wma <- dataset_cds_d_cs$sentiment
dataset_cds_d_ubs$sentiment_wma <- dataset_cds_d_ubs$sentiment

results_granger_w <- data.frame()

for (i in 1:5) {
  
  cds_on_senti_cs <- lmtest::grangertest(
    x = dataset_cds_d_cs$sentiment_wma, y = dataset_cds_d_cs$cds, order = i
  )
  
  cds_on_senti_ubs <- lmtest::grangertest(
    x = dataset_cds_d_ubs$sentiment_wma, y = dataset_cds_d_ubs$cds, order = i
  )
  
  senti_on_cds_cs <- lmtest::grangertest(
    x = dataset_cds_d_cs$cds, y = dataset_cds_d_cs$sentiment_wma, order = i
  )
  
  senti_on_cds_ubs <- lmtest::grangertest(
    x = dataset_cds_d_ubs$cds, y = dataset_cds_d_ubs$sentiment_wma, order = i
  )
  
  results_granger_w <- rbind(results_granger_w, data.frame(
    lags = i,
    cds_on_senti_cs = cds_on_senti_cs$`Pr(>F)`[2],
    senti_on_cds_cs = senti_on_cds_cs$`Pr(>F)`[2],
    cds_on_senti_ubs = cds_on_senti_ubs$`Pr(>F)`[2],
    senti_on_cds_ubs = senti_on_cds_ubs$`Pr(>F)`[2]
  ))
}

create_table_granger(results_granger_w, "Granger Causality Test", "granger_weekly")


# =============================================================================.
# 4. Is sentiment predictor of maximum drawdown? ----
# =============================================================================.

dataset_mdd_euro <- sentiment_euro_d |>
  left_join(y = mdd, by = c("bank" = "query_bank", "date")) |>
  select(bank, date, sentiment_wma, mdd) |>
  group_by(bank) |>
  arrange(bank, date) |>
  ungroup() |>
  mutate(
    bank = as.factor(bank),
    date = as.factor(date),
    sentiment_wma = lag(sentiment_wma),
    sentiment_wma_adj = if_else(sentiment_wma >= -0.25, 0, sentiment_wma)
  ) |>
  na.omit() |> 
  as.data.frame()

result_mdd_euro <- panelvar::pvarfeols(
  dependent_vars = c("mdd"),
  exog_vars = "sentiment_wma",
  lags = 5,
  data = dataset_mdd_euro,
  panel_identifier = c("bank", "date")
)

attr(result_mdd_euro$OLS$coef, "dimnames")[[1]] <- "demeaned_mdd"

models[["mdd_euro"]] <- summary(result_mdd_euro)
models[["mdd_euro"]]["sample"] <- "European Banks"
models[["mdd_euro"]]["obsperiod"] <- paste(min(as.Date(dataset_mdd_euro$date)), "to", max(as.Date(dataset_mdd_euro$date)))

result_mdd_euro_adj <- panelvar::pvarfeols(
  dependent_vars = c("mdd"),
  exog_vars = "sentiment_wma_adj",
  lags = 5,
  data = dataset_mdd_euro,
  panel_identifier = c("bank", "date")
)

attr(result_mdd_euro_adj$OLS$coef, "dimnames")[[1]] <- "demeaned_mdd"

models[["mdd_euro_adj"]] <- summary(result_mdd_euro_adj)
models[["mdd_euro_adj"]]["sample"] <- "European Banks"
models[["mdd_euro_adj"]]["obsperiod"] <- paste(min(as.Date(dataset_mdd_euro$date)), "to", max(as.Date(dataset_mdd_euro$date)))




dataset_mdd_swiss <- sentiment_swiss_d |>
  left_join(y = mdd, by = c("bank" = "query_bank", "date")) |>
  select(bank, date, sentiment_wma, mdd) |>
  group_by(bank) |>
  arrange(bank, date) |>
  ungroup() |>
  mutate(
    bank = as.factor(bank),
    date = as.factor(date),
    sentiment_wma = lag(sentiment_wma),
    sentiment_wma_adj = if_else(sentiment_wma >= -0.25, 0, sentiment_wma)
  ) |>
  na.omit() |> 
  as.data.frame()

result_mdd_swiss <- panelvar::pvarfeols(
  dependent_vars = c("mdd"),
  exog_vars = c("sentiment_wma"),
  lags = 5,
  data = dataset_mdd_swiss,
  panel_identifier = c("bank", "date")
)

attr(result_mdd_swiss$OLS$coef, "dimnames")[[1]] <- "demeaned_mdd"

models[["mdd_swiss"]] <- summary(result_mdd_swiss)
models[["mdd_swiss"]]["sample"] <- "Swiss Banks"
models[["mdd_swiss"]]["obsperiod"] <- paste(min(as.Date(dataset_mdd_swiss$date)), "to", max(as.Date(dataset_mdd_swiss$date)))

result_mdd_swiss_adj <- panelvar::pvarfeols(
  dependent_vars = c("mdd"),
  exog_vars = c("sentiment_wma_adj"),
  lags = 5,
  data = dataset_mdd_swiss,
  panel_identifier = c("bank", "date")
)

attr(result_mdd_swiss_adj$OLS$coef, "dimnames")[[1]] <- "demeaned_mdd"

models[["mdd_swiss_adj"]] <- summary(result_mdd_swiss_adj)
models[["mdd_swiss_adj"]]["sample"] <- "Swiss Banks"
models[["mdd_swiss_adj"]]["obsperiod"] <- paste(min(as.Date(dataset_mdd_swiss$date)), "to", max(as.Date(dataset_mdd_swiss$date)))


create_table(models[grep("mdd_euro_*", names(models))], "Panel VAR MDD", "mddpvar_euro")
create_table(models[grep("mdd_swiss_*", names(models))], "Panel VAR MDD", "mddpvar_swiss")

# =============================================================================.
# 5. Is sentiment predictor of volatility? ----
# =============================================================================.

# garch
dataset_vola_swiss <- sentiment_swiss_d |> 
  left_join(y = stockreturn, by = c("bank", "date")) |> 
  na.omit()

dataset_vola_swiss_cs <- dataset_vola_swiss |> 
  filter(bank == "credit_suisse")

dataset_vola_swiss_ubs <- dataset_vola_swiss |> 
  filter(bank == "ubs")

stockreturn_cs <- dataset_vola_swiss_cs |>
  pull(stockreturn)

sentiment_cs <- dataset_vola_swiss_cs |> 
  pull(sentiment_wma)

stockreturn_ubs <- dataset_vola_swiss_ubs |>
  pull(stockreturn)

sentiment_ubs <- dataset_vola_swiss_ubs |> 
  pull(sentiment_wma)

result_garchx_cs <- garchx::garchx(stockreturn_cs, xreg = sentiment_cs)
models[["garchx_cs"]] <- result_garchx_cs
models[["garchx_cs"]]["sample"] <- "Credit Suisse"
models[["garchx_cs"]]["obsperiod"] <- paste(min(as.Date(dataset_vola_swiss_cs$date)), "to", max(as.Date(dataset_vola_swiss_cs$date)))

result_garchx_ubs <- garchx::garchx(stockreturn_ubs, xreg = sentiment_ubs)
models[["garchx_ubs"]] <- result_garchx_ubs
models[["garchx_ubs"]]["sample"] <- "UBS" 
models[["garchx_ubs"]]["obsperiod"] <- paste(min(as.Date(dataset_vola_swiss_ubs$date)), "to", max(as.Date(dataset_vola_swiss_ubs$date)))

create_table(models[grep("garchx_*", names(models))], "GARCH-X", "garchx")

# heterogeneous autoregressive model

stockreturn_cs <- xts::as.xts(dataset_vola_swiss_cs$stockreturn, order.by = dataset_vola_swiss_cs$date)
sentiment_cs <- xts::as.xts(dataset_vola_swiss_cs$sentiment_wma, order.by = dataset_vola_swiss_cs$date)
stockreturn_ubs <- xts::as.xts(dataset_vola_swiss_ubs$stockreturn, order.by = dataset_vola_swiss_ubs$date)
sentiment_ubs <- xts::as.xts(dataset_vola_swiss_ubs$sentiment_wma, order.by = dataset_vola_swiss_ubs$date)

periods <- c(3, 7, 22)

results_har_cs <- highfrequency::HARmodel(
  data = stockreturn_cs, externalRegressor = sentiment_cs, inputType = "RM",
  periods = periods, periodsJ = periods, periodsQ = periods
)

models[["har_cs"]] <- results_har_cs
models[["har_cs"]]["sample"] <- "Credit Suisse"
models[["har_cs"]]["nobs"] <- length(stockreturn_cs)
models[["har_cs"]]["obsperiod"] <- paste(min(as.Date(dataset_vola_swiss_cs$date)), "to", max(as.Date(dataset_vola_swiss_cs$date)))


results_har_ubs <- highfrequency::HARmodel(
  data = stockreturn_ubs, externalRegressor = sentiment_ubs, inputType = "RM",
  periods = periods, periodsJ = periods, periodsQ = periods
)

models[["har_ubs"]] <- results_har_ubs
models[["har_ubs"]]["sample"] <- "UBS"
models[["har_ubs"]]["nobs"] <- length(stockreturn_ubs)
models[["har_ubs"]]["obsperiod"] <- paste(min(as.Date(dataset_vola_swiss_ubs$date)), "to", max(as.Date(dataset_vola_swiss_ubs$date)))

create_table(models[grep("^har_*", names(models))], "HAR", "har")
