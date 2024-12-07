rm(list = ls()); gc()
library(dplyr)

setwd("/Users/belakoch/Documents/Studium/Master/MA Thesis/newsews")

source("config/environvars.R")

meta_ric <- read.csv(file.path(paths$path_meta, "mapping_ric.csv"), sep = ";") |> 
  select(ric, query_bank)

sentiment_swiss <- read.csv(file.path(paths$path_results, "sentiment_scores.csv"), sep = ";") |> 
  mutate(
    date = as.Date(date)
  )

n <- 4
sentiment_swiss <- read.csv(file.path(paths$path_results, "sentiment_scores.csv"), sep = ";") |> 
  # filter(bank %in% c("credit_suisse", "ubs")) |> 
  mutate(
    date = as.Date(date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(bank, date) |> 
  reframe(sentiment = mean(sentiment_score, na.rm = TRUE)) |> 
  group_by(bank) |> 
  mutate(
    sentiment_wma = as.numeric(stats::filter(sentiment, (n:1)/sum(n:1), sides = 1))
  )

stocks <- read.csv(file.path(paths$path_refinitiv, "stocks.csv"), sep = ";") |> 
  select(Instrument, Date, Close.Price) |> 
  unique() |> 
  merge(y = meta_ric, by.x = "Instrument", by.y = "ric")

mdd_window <- 14
mdd <- stocks |> 
  group_by(query_bank) |> 
  mutate(
    date = as.Date(Date),
    mdd = slider::slide_dbl(
      .x = Close.Price,
      .f = ~ min(.x - cummax(.x), na.rm = TRUE),
      .before = mdd_window-1,
      .complete = TRUE
    ),
    mdd = lead(mdd, mdd_window-1)
  )


# df <- sentiment_swiss |> 
#   merge(y = mdd, by.x = "bank", by.y = "query_bank", all.x = T)

df_swiss <- sentiment_swiss |> 
  left_join(y = mdd, by = c("bank" = "query_bank", "date")) |> 
  group_by(bank) |> 
  arrange(bank, date)

# df_swiss <- df_swiss |>
#   filter(bank %in% c("credit_suisse", "ubs"#, "julius_baer", "kantonalbank_bern",
#                      #"baloise", "kantonalbank_luzern", "swissquote", "kantonalbank_stgallen",
#                      #"kantonalbank_baselstadt", "cembra_money_bank"
#                      )) #|> 
#   # filter(date >= as.Date("2022-06-01"))

df_swiss <- as.data.frame(df_swiss)
df_swiss <- df_swiss[complete.cases(df_swiss),]
df_swiss$bank <- as.factor(df_swiss$bank)
df_swiss$date <- as.factor(df_swiss$date)

df_swiss <- df_swiss |> 
  select(bank, date, sentiment_wma, mdd)

# data <- df_swiss |> filter(bank == "julius_baer")
# data_var <- data[, c("sentiment", "mdd")]
# tseries::adf.test(data_var$sentiment)
# tseries::adf.test(data_var$mdd)
# var_model <- vars::VAR(data_var, p = 5, ic = "AIC")
# var_model |> summary()

# df_swiss <- df_swiss[0:100,]

# pvar2 <- panelvar::pvargmm(
#   dependent_vars = c("mdd"),
#   lags = 1, # Number of lags of dependent variables
#   exog_vars = c("sentiment"),
#   # transformation = "fd",  # First-difference "fd" or forward orthogonal deviations "fod"
#   data = df_swiss,
#   panel_identifier = c("bank", "date"),  # Vector of panel identifiers
#   steps = c("onestep")#,   # "onestep", "twostep" or "mstep" estimation
#   # system_instruments = FALSE,  #    System GMM estimator
#   # max_instr_dependent_vars = 99, #  Maximum number of instruments for dependent variables
#   # min_instr_dependent_vars = 2L, # Minimum number of instruments for dependent variables
#   # collapse = FALSE
# )
# summary(pvar2)

# rm(list = ls()[ls() != "df_swiss"])
# gc()



pvar2 <- panelvar::pvargmm(
  dependent_vars = c("mdd"),
  lags = 1, # Number of lags of dependent variables
  exog_vars = c("sentiment_wma"),
  # transformation = "fd",  # First-difference "fd" or forward orthogonal deviations "fod"
  data = df_swiss,
  panel_identifier = c("bank", "date"),  # Vector of panel identifiers
  steps = c("onestep"),   # "onestep", "twostep" or "mstep" estimation
  # system_instruments = FALSE,  #    System GMM estimator
  # max_instr_dependent_vars = 99, #  Maximum number of instruments for dependent variables
  # min_instr_dependent_vars = 2L, # Minimum number of instruments for dependent variables
  collapse = T
)
summary(pvar2)

models <- list()
models[["swissdox"]] <- summary(pvar2)
models[["swissdox"]]["sample"] <- "Swiss Banks"
models[["swissdox"]]["obsperiod"] <- paste(min(as.Date(df_swiss$date)), "to", max(as.Date(df_swiss$date)))


source("visualise/create_table.R")
create_table(models, "Panel VAR sentiment MDD", "mddpvar", small_font = F)

# ---------------------------------------------------
#   Dynamic Panel VAR estimation, one-step GMM 
# ---------------------------------------------------
#   Transformation: First-differences 
# Group variable: bank 
# Time variable: date 
# Number of observations = 98 
# Number of groups = 1 
# Obs per group: min = 98 
# avg = 98 
# max = 98 
# Number of instruments = 4852 
# 
# ==========================
#   mdd        
# --------------------------
#   lag1_mdd        0.9205 ***
#   (0.0000)   
# sentiment_wma  -0.6070 ***
#   (0.0000)   
# ==========================
#   *** p < 0.001; ** p < 0.01; * p < 0.05
# 
# ---------------------------------------------------
#   Instruments for  equation
# Standard
# FD.(sentiment_wma)
# GMM-type
# Dependent vars: L(2, 98)
# Collapse =  FALSE 
# ---------------------------------------------------

# cds <- read.csv(file.path(paths$path_refinitiv, "cds.csv"), sep = ";")
# sentiment <- read.csv(file.path(paths$path_results, "sentiment_scores_refinitiv.csv"), sep = ";")
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
# problem: not available in high frequency
# tier1 <- read.csv(file.path(paths$path_refinitiv, "tier1capital.csv"), sep = ";") |> 
#     select(Instrument, Date, Tier.1.Capital.Ratio...Mean) |> 
#     unique()
# roe <- read.csv(file.path(paths$path_refinitiv, "roe.csv"), sep = ";") |> 
#     select(Instrument, Date, Return.On.Equity...Mean) |> 
#     unique()

eurostr <- read.csv("/Users/belakoch/data/ecb/euro_short_term_rate.csv")
names(eurostr) <- c("date", "x", "value")
eurostr <- eurostr |> select("date", "value")

stockmarket <- right_join(
  filter(indices, Instrument == ".FTEU1"),
  filter(govbonds, Instrument == "EU1YT=RR"),
  by = "Date"
) |>
  mutate(
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(date) |> 
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
  group_by(date) |> 
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
  group_by(date) |> 
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
  group_by(date) |> 
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
  group_by(date) |> 
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
  group_by(date) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |>
  mutate(
    highyieldspread = (Yield.x-Yield.y)/(lag(Yield.x)-lag(Yield.y))-1
  )

stockreturn <- stocks |> 
  mutate(
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(Instrument, date) |> 
  slice_max(order_by = date, n = 1) |> 
  group_by(Instrument) |> 
  mutate(
    stockreturn = (Close.Price-lag(Close.Price))/lag(Close.Price)
  ) |> 
  ungroup() |> 
  rename(bank = Instrument) |> 
  select(bank, date, stockreturn)

# map_date_swiss <- read.csv(file.path(paths$path_results, "sentiment_scores.csv"), sep = ";") |> 
#   mutate(
#     date = as.Date(date),
#     week = cut.Date(date, breaks = "1 week", labels = FALSE)
#   ) |> 
#   group_by(week) |> 
#   slice_max(order_by = date, n = 1) |> 
#   ungroup() |> 
#   select(week, date) |> 
#   unique()

meta_ric <- read.csv(file.path(paths$path_meta, "mapping_ric.csv"), sep = ";")

df_swiss <- sentiment_swiss |> 
  left_join(y = meta_ric, by = c("bank" = "query_bank")) |> 
  # left_join(y = cds, by = c("date", "ric" = "bank")) |> 
  left_join(y = mdd, by = c("date", "bank" = "query_bank")) |> 
  left_join(y = stockmarket, by = "date") |> 
  left_join(y = volatilitypremium, by = "date") |> 
  left_join(y = termpremium, by = "date") |> 
  left_join(y = treasurymarket, by = "date") |> 
  left_join(y = investgradespread, by = "date") |> 
  left_join(y = highyieldspread, by = "date") |> 
  select(bank, date, sentiment_wma, mdd, stockmarket, volatilitypremium, termpremium, treasurymarket, investgradespread, highyieldspread)


df_swiss <- as.data.frame(df_swiss)
df_swiss$bank <- as.factor(df_swiss$bank)
df_swiss$date <- as.factor(df_swiss$date)

pvar2 <- panelvar::pvargmm(
  dependent_vars = c("mdd"),
  lags = 1, # Number of lags of dependent variables
  exog_vars = c("sentiment_wma", "stockmarket", "volatilitypremium", "termpremium", "treasurymarket", "investgradespread", "highyieldspread"),
  # transformation = "fd",  # First-difference "fd" or forward orthogonal deviations "fod"
  data = df_swiss,
  panel_identifier = c("bank", "date"),  # Vector of panel identifiers
  steps = c("onestep"),   # "onestep", "twostep" or "mstep" estimation
  # system_instruments = FALSE,  #    System GMM estimator
  # max_instr_dependent_vars = 99, #  Maximum number of instruments for dependent variables
  # min_instr_dependent_vars = 2L, # Minimum number of instruments for dependent variables
  collapse = T
)
summary(pvar2)
