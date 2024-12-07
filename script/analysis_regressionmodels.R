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
mdd <- stocks |> 
  group_by(Instrument) |> 
  mutate(
    date = as.Date(Date),
    mdd = slider::slide_dbl(
      .x = Close.Price,
      .f = ~ min(.x - cummax(.x), na.rm = TRUE),
      .before = mdd_window-1,
      .complete = TRUE
    ),
    mdd = lead(mdd, mdd_window-1)
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
    sentiment = na.approx(sentiment, maxgap = 2, rule = 2),
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
    sentiment = na.approx(sentiment, maxgap = 2, rule = 2),
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
  select(
    sentiment, sentiment_l1, sentiment_l2, sentiment_l3, sentiment_l4,
    sentiment_l5, stockmarket, volatilitypremium, termpremium, treasurymarket,
    investgradespread, highyieldspread, bank, date, cds
  ) |> 
  na.omit() |> 
  mutate(
    bank = as.factor(bank),
    date = as.factor(date)
  ) |> 
  as.data.frame()

result_cathart_euro_nolag <- panelvar::pvargmm(
  dependent_vars = c("cds"),
  lags = 5,
  exog_vars = c(
    "sentiment",
    "stockmarket", "volatilitypremium", "termpremium",
    "treasurymarket", "investgradespread", "highyieldspread"
  ),
  data = dataset_cathart_euro,
  panel_identifier = c("bank", "date"),
  steps = c("onestep"),
  collapse = TRUE
)
models[["cathart_nolag_euro"]] <- summary(result_cathart_euro_nolag)
models[["cathart_nolag_euro"]]["sample"] <- "European Banks"
models[["cathart_nolag_euro"]]["obsperiod"] <- paste(min(as.Date(dataset_cathart_euro$date)), "to", max(as.Date(dataset_cathart_euro$date)))

# result_cathart_euro_onlylag <- panelvar::pvargmm(
#   dependent_vars = c("cds"),
#   lags = 5,
#   exog_vars = c(
#     "sentiment_l1", "sentiment_l2", "sentiment_l3", "sentiment_l4", "sentiment_l5",
#     "stockmarket", "volatilitypremium", "termpremium",
#     "treasurymarket", "investgradespread", "highyieldspread"
#   ),
#   data = dataset_cathart_euro,
#   panel_identifier = c("bank", "date"),
#   steps = c("onestep"),
#   collapse = TRUE
# )
# models[["cathart_onlylag_euro"]] <- summary(result_cathart_euro_onlylag)
# models[["cathart_onlylag_euro"]]["sample"] <- "European Banks"
# models[["cathart_onlylag_euro"]]["obsperiod"] <- paste(min(as.Date(dataset_cathart_euro$date)), "to", max(as.Date(dataset_cathart_euro$date)))

result_cathart_euro_all <- panelvar::pvargmm(
  dependent_vars = c("cds"),
  lags = 5,
  exog_vars = c(
    "sentiment", "sentiment_l1", "sentiment_l2", "sentiment_l3", "sentiment_l4", "sentiment_l5",
    "stockmarket", "volatilitypremium", "termpremium",
    "treasurymarket", "investgradespread", "highyieldspread"
  ),
  data = dataset_cathart_euro,
  panel_identifier = c("bank", "date"),
  steps = c("onestep"),
  collapse = TRUE
)
models[["cathart_all_euro"]] <- summary(result_cathart_euro_all)
models[["cathart_all_euro"]]["sample"] <- "European Banks"
models[["cathart_all_euro"]]["obsperiod"] <- paste(min(as.Date(dataset_cathart_euro$date)), "to", max(as.Date(dataset_cathart_euro$date)))

create_table(models[grep("cathart_[a-z]+_euro", names(models))], "Panel VAR sentiment, European Bank Sample", "cdspvar_euro")


dataset_cathart_swiss <- sentiment_swiss_w |> 
  left_join(y = meta_ric, by = c("bank" = "query_bank")) |> 
  left_join(y = cds, by = c("date", "ric" = "bank")) |> 
  left_join(y = stockmarket, by = "date") |> 
  left_join(y = volatilitypremium, by = "date") |> 
  left_join(y = termpremium, by = "date") |> 
  left_join(y = treasurymarket, by = "date") |> 
  left_join(y = investgradespread, by = "date") |> 
  left_join(y = highyieldspread, by = "date") |> 
  select(
    sentiment, sentiment_l1, sentiment_l2, sentiment_l3, sentiment_l4,
    sentiment_l5, stockmarket, volatilitypremium, termpremium, treasurymarket,
    investgradespread, highyieldspread, bank, date, cds
  ) |> 
  na.omit() |> 
  mutate(
    bank = as.factor(bank),
    date = as.factor(date)
  ) |> 
  as.data.frame()

result_cathart_swiss_nolag <- panelvar::pvargmm(
  dependent_vars = c("cds"),
  lags = 5,
  exog_vars = c(
    "sentiment",
    "stockmarket", "volatilitypremium", "termpremium",
    "treasurymarket", "investgradespread", "highyieldspread"
  ),
  data = dataset_cathart_swiss,
  panel_identifier = c("bank", "date"),
  steps = c("onestep"),
  collapse = TRUE
)
models[["cathart_nolag_swiss"]] <- summary(result_cathart_swiss_nolag)
models[["cathart_nolag_swiss"]]["sample"] <- "Swiss Banks"
models[["cathart_nolag_swiss"]]["obsperiod"] <- paste(min(as.Date(dataset_cathart_swiss$date)), "to", max(as.Date(dataset_cathart_swiss$date)))


# result_cathart_swiss_onlylag <- panelvar::pvargmm(
#   dependent_vars = c("cds"),
#   lags = 5,
#   exog_vars = c(
#     "sentiment_l1", "sentiment_l2", "sentiment_l3", "sentiment_l4", "sentiment_l5",
#     "stockmarket", "volatilitypremium", "termpremium",
#     "treasurymarket", "investgradespread", "highyieldspread"
#   ),
#   data = dataset_cathart_swiss,
#   panel_identifier = c("bank", "date"),
#   steps = c("onestep"),
#   collapse = TRUE
# )
# models[["cathart_onlylag_swiss"]] <- summary(result_cathart_swiss_onlylag)
# models[["cathart_onlylag_swiss"]]["sample"] <- "Swiss Banks"
# models[["cathart_onlylag_swiss"]]["obsperiod"] <- paste(min(as.Date(dataset_cathart_swiss$date)), "to", max(as.Date(dataset_cathart_swiss$date)))


result_cathart_swiss_all <- panelvar::pvargmm(
  dependent_vars = c("cds"),
  lags = 5,
  exog_vars = c(
    "sentiment", "sentiment_l1", "sentiment_l2", "sentiment_l3", "sentiment_l4", "sentiment_l5",
    "stockmarket", "volatilitypremium", "termpremium",
    "treasurymarket", "investgradespread", "highyieldspread"
  ),
  data = dataset_cathart_swiss,
  panel_identifier = c("bank", "date"),
  steps = c("onestep"),
  collapse = TRUE
)
models[["cathart_all_swiss"]] <- summary(result_cathart_swiss_all)
models[["cathart_all_swiss"]]["sample"] <- "Swiss Banks"
models[["cathart_all_swiss"]]["obsperiod"] <- paste(min(as.Date(dataset_cathart_swiss$date)), "to", max(as.Date(dataset_cathart_swiss$date)))

create_table(models[grep("cathart_[a-z]+_swiss", names(models))], "Panel VAR sentiment, Swiss Bank Sample", "cdspvar_swiss")

# to do: schauen ob diese analyse getrieben durch einzelne gruppe?
test <- panelvar::pvargmm(
  dependent_vars = c("cds"),
  lags = 5,
  exog_vars = c(
    "sentiment", "sentiment_l1", "sentiment_l2", "sentiment_l3", "sentiment_l4", "sentiment_l5",
    "stockmarket", "volatilitypremium", "termpremium",
    "treasurymarket", "investgradespread", "highyieldspread"
  ),
  data = dataset_cathart_swiss |> filter(bank == "ubs"),
  panel_identifier = c("bank", "date"),
  steps = c("onestep"),
  collapse = TRUE
)

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
    date = as.factor(date)
  ) |>
  na.omit() |> 
  as.data.frame()

result_mdd_euro_nocontrols <- panelvar::pvargmm(
  dependent_vars = c("mdd"),
  lags = 5,
  exog_vars = c("sentiment_wma"),
  data = dataset_mdd_euro,
  panel_identifier = c("bank", "date"),
  steps = c("onestep"),
  collapse = TRUE
)
models[["mdd_nocontrols_euro"]] <- summary(result_mdd_euro_nocontrols)
models[["mdd_nocontrols_euro"]]["sample"] <- "European Banks"
models[["mdd_nocontrols_euro"]]["obsperiod"] <- paste(min(as.Date(dataset_mdd_euro$date)), "to", max(as.Date(dataset_mdd_euro$date)))



dataset_mdd_swiss <- sentiment_swiss_d |>
  left_join(y = mdd, by = c("bank" = "query_bank", "date")) |>
  select(bank, date, sentiment_wma, mdd) |>
  group_by(bank) |>
  arrange(bank, date) |>
  ungroup() |>
  mutate(
    bank = as.factor(bank),
    date = as.factor(date)
  ) |>
  na.omit() |> 
  as.data.frame()

result_mdd_swiss_nocontrols <- panelvar::pvargmm(
  dependent_vars = c("mdd"),
  lags = 5,
  exog_vars = c("sentiment_wma"),
  data = dataset_mdd_swiss,
  panel_identifier = c("bank", "date"),
  steps = c("onestep"),
  collapse = TRUE
)

models[["mdd_nocontrols_swiss"]] <- summary(result_mdd_swiss_nocontrols)
models[["mdd_nocontrols_swiss"]]["sample"] <- "Swiss Banks"
models[["mdd_nocontrols_swiss"]]["obsperiod"] <- paste(min(as.Date(dataset_mdd_swiss$date)), "to", max(as.Date(dataset_mdd_swiss$date)))

create_table(models[grep("mdd_*", names(models))], "Panel VAR MDD", "mddpvar")

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

stockreturn_cs <- as.xts(dataset_vola_swiss_cs$stockreturn, order.by = dataset_vola_swiss_cs$date)
sentiment_cs <- as.xts(dataset_vola_swiss_cs$sentiment_wma, order.by = dataset_vola_swiss_cs$date)
stockreturn_ubs <- as.xts(dataset_vola_swiss_ubs$stockreturn, order.by = dataset_vola_swiss_ubs$date)
sentiment_ubs <- as.xts(dataset_vola_swiss_ubs$sentiment_wma, order.by = dataset_vola_swiss_ubs$date)

results_har_cs <- highfrequency::HARmodel(
  data = stockreturn_cs, externalRegressor = sentiment_cs, inputType = "RM"
)

models[["har_cs"]] <- results_har_cs
models[["har_cs"]]["sample"] <- "Credit Suisse"
models[["har_cs"]]["nobs"] <- length(stockreturn_cs)
models[["har_cs"]]["obsperiod"] <- paste(min(as.Date(dataset_vola_swiss_cs$date)), "to", max(as.Date(dataset_vola_swiss_cs$date)))


results_har_ubs <- highfrequency::HARmodel(
  data = stockreturn_ubs, externalRegressor = sentiment_ubs, inputType = "RM"
)

models[["har_ubs"]] <- results_har_ubs
models[["har_ubs"]]["sample"] <- "UBS"
models[["har_ubs"]]["nobs"] <- length(stockreturn_ubs)
models[["har_ubs"]]["obsperiod"] <- paste(min(as.Date(dataset_vola_swiss_ubs$date)), "to", max(as.Date(dataset_vola_swiss_ubs$date)))

create_table(models[grep("^har_*", names(models))], "HAR", "har")
