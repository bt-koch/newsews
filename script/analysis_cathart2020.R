rm(list = ls()); gc()
library(dplyr)

source("visualise/create_table.R")

# =================================================================================
# 1. Load and prepare data 
# =================================================================================
source("config/environvars.R")
cds <- read.csv(file.path(paths$path_refinitiv, "cds.csv"), sep = ";")
sentiment <- read.csv(file.path(paths$path_results, "sentiment_scores_refinitiv.csv"), sep = ";")
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

# credit default swaps
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

# tier1 <- tier1 |> 
#     mutate(
#         date = as.Date(Date),
#         week = cut.Date(date, breaks = "1 week", labels = FALSE)
#     ) |> 
#     group_by(Instrument, week) |> 
#     slice_max(order_by = date, n = 1) |> 
#     group_by(Instrument) |> 
#     mutate(
#         tier1 = (Tier.1.Capital.Ratio...Mean-lag(Tier.1.Capital.Ratio...Mean))/lag(Tier.1.Capital.Ratio...Mean) * 100
#     ) |> 
#     ungroup() |> 
#     rename(bank = Instrument) |> 
#     select(bank, date, tier1)
# 
# roe <- roe |> 
#     mutate(
#         date = as.Date(Date),
#         week = cut.Date(date, breaks = "1 week", labels = FALSE)
#     ) |> 
#     group_by(Instrument, week) |> 
#     slice_max(order_by = date, n = 1) |> 
#     group_by(Instrument) |> 
#     mutate(
#         roe = (Return.On.Equity...Mean-lag(Return.On.Equity...Mean))/lag(Return.On.Equity...Mean) * 100
#     ) |> 
#     ungroup() |> 
#     rename(bank = Instrument) |> 
#     select(bank, date, roe)
stockreturn <- stocks |> 
  mutate(
    date = as.Date(Date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(Instrument, week) |> 
  slice_max(order_by = date, n = 1) |> 
  group_by(Instrument) |> 
  mutate(
    stockreturn = (Close.Price-lag(Close.Price))/lag(Close.Price)
  ) |> 
  ungroup() |> 
  rename(bank = Instrument) |> 
  select(bank, date, stockreturn)

map_date_swiss <- read.csv(file.path(paths$path_results, "sentiment_scores.csv"), sep = ";") |> 
  mutate(
    date = as.Date(date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(week) |> 
  slice_max(order_by = date, n = 1) |> 
  ungroup() |> 
  select(week, date) |> 
  unique()
n = 1
sentiment_swiss <- read.csv(file.path(paths$path_results, "sentiment_scores.csv"), sep = ";") |> 
  filter(bank %in% c("credit_suisse", "ubs")) |> 
  mutate(
    date = as.Date(date),
    week = cut.Date(date, breaks = "1 week", labels = FALSE)
  ) |> 
  group_by(bank, week) |> 
  reframe(sentiment = mean(sentiment_score, na.rm = TRUE)) |> 
  group_by(bank) |> 
  mutate(
    sentiment_sma = as.numeric(stats::filter(sentiment, rep(1/n,n), sides = 1)),
    sentiment_wma = as.numeric(stats::filter(sentiment, (n:1)/sum(n:1), sides = 1))#,
    # sentiment_wma = sentiment_wma+1,
    # sentiment = (sentiment_wma-lag(sentiment_wma))/lag(sentiment_wma)
    # ,sentiment=lag(sentiment)
    ,
    sentiment_l1 = lag(sentiment),
    sentiment_l2 = lag(sentiment, 2),
    sentiment_l3 = lag(sentiment, 3),
    sentiment_l4 = lag(sentiment, 4),
    sentiment_l5 = lag(sentiment, 5)
  ) |> 
  right_join(y = map_date_swiss, by = "week") |> 
  mutate(
    date = date - 2
  )


map_date <- read.csv(file.path(paths$path_results, "sentiment_scores_refinitiv.csv"), sep = ";") |> 
    mutate(
        date = as.Date(date),
        week = cut.Date(date, breaks = "1 week", labels = FALSE)
    ) |> 
    group_by(week) |> 
    slice_max(order_by = date, n = 1) |> 
    ungroup() |> 
    select(week, date) |> 
    unique()
n <- 1
sentiment <- read.csv(file.path(paths$path_results, "sentiment_scores_refinitiv.csv"), sep = ";") |> 
    mutate(
        date = as.Date(date),
        week = cut.Date(date, breaks = "1 week", labels = FALSE)
    ) |> 
    group_by(bank, week) |> 
    reframe(sentiment = mean(sentiment_score, na.rm = TRUE)) |> 
    group_by(bank) |> 
    mutate(
        sentiment_sma = as.numeric(stats::filter(sentiment, rep(1/n,n), sides = 1)),
        sentiment_wma = as.numeric(stats::filter(sentiment, (n:1)/sum(n:1), sides = 1)),
        # # sentiment_wma = sentiment_wma+1,
        # # sentiment = (sentiment_wma-lag(sentiment_wma))/lag(sentiment_wma),
        # sentiment = lag(sentiment),
        # # sentiment_wma = sentiment_wma*10,
        # # sentiment = sentiment_wma,
        sentiment_l1 = lag(sentiment),
        sentiment_l2 = lag(sentiment, 2),
        sentiment_l3 = lag(sentiment, 3),
        sentiment_l4 = lag(sentiment, 4),
        sentiment_l5 = lag(sentiment, 5)
    ) |> 
    right_join(y = map_date, by = "week") |> 
    mutate(
        date = date - 2
    )

meta_ric <- read.csv(file.path(paths$path_meta, "mapping_ric.csv"), sep = ";")
df <- sentiment |> 
    left_join(y = meta_ric, by = c("bank" = "query_bank")) |> 
    left_join(y = cds, by = c("date", "ric" = "bank")) |> 
    left_join(y = stockmarket, by = "date") |> 
    left_join(y = volatilitypremium, by = "date") |> 
    left_join(y = termpremium, by = "date") |> 
    left_join(y = treasurymarket, by = "date") |> 
    left_join(y = investgradespread, by = "date") |> 
    left_join(y = highyieldspread, by = "date") |>
    # left_join(y = tier1, by = c("ric" = "bank", "date")) |> 
    left_join(y = stockreturn, by = c("ric" = "bank", "date"))

# panel regression
# result <- plm::plm(cds ~ sentiment+stockmarket+volatilitypremium+termpremium+treasurymarket+investgradespread+highyieldspread+stockreturn, data = df, index = c("bank", "date"))
# summary(result)

df_swiss <- sentiment_swiss |> 
  left_join(y = meta_ric, by = c("bank" = "query_bank")) |> 
  left_join(y = cds, by = c("date", "ric" = "bank")) |> 
  left_join(y = stockmarket, by = "date") |> 
  left_join(y = volatilitypremium, by = "date") |> 
  left_join(y = termpremium, by = "date") |> 
  left_join(y = treasurymarket, by = "date") |> 
  left_join(y = investgradespread, by = "date") |> 
  left_join(y = highyieldspread, by = "date")# |>
  # left_join(y = tier1, by = c("ric" = "bank", "date")) |> 
  # left_join(y = stockreturn, by = c("ric" = "bank", "date"))

# panel regression
# result <- plm::plm(cds ~ sentiment+stockmarket+volatilitypremium+termpremium+treasurymarket+investgradespread+highyieldspread, data = df_swiss, index = c("bank", "date"))
# summary(result)

# # simple VAR
data <- df |>
    dplyr::select(
        bank, date, sentiment, cds, stockmarket, volatilitypremium,
        termpremium, treasurymarket, investgradespread, highyieldspread,
        stockreturn
    )
data <- data[complete.cases(data),]

data_swiss <- df_swiss |>
  dplyr::select(
    bank, date, sentiment, cds, stockmarket, volatilitypremium,
    termpremium, treasurymarket, investgradespread, highyieldspread
  )
data_swiss <- data_swiss[complete.cases(data_swiss),]
# data$bank <- as.factor(data$bank)
# data_var <- data |> filter(bank == "deutsche_bank")
# data_var <- data_var[, c("sentiment", "cds", "stockmarket", "volatilitypremium", "termpremium", "treasurymarket", "investgradespread", "highyieldspread")]
# tseries::adf.test(data_var$sentiment)
# tseries::adf.test(data_var$cds)
# var_model <- vars::VAR(data_var, ic = "AIC")
# summary(var_model)
data_swiss <- as.data.frame(data_swiss)
data_swiss$bank <- as.factor(data_swiss$bank)
data_swiss$date <- as.factor(data_swiss$date)
# panel var
data <- as.data.frame(data)
data$bank <- as.factor(data$bank)
data$date <- as.factor(data$date)

# pvar1 <- panelvar::pvarfeols(
#     dependent_vars = c("cds", "stockmarket", "volatilitypremium", "termpremium", "treasurymarket", "investgradespread", "highyieldspread", "stockreturn"),
#     lags = 1,
#     exog_vars = c("sentiment"),
#     transformation = "fd",
#     data = data,
#     panel_identifier= c("bank", "date"))
# summary(pvar1)

pvar2 <- panelvar::pvargmm(
  dependent_vars = c("cds"),
  lags = 1, # Number of lags of dependent variables
  exog_vars = c("sentiment", "stockmarket", "volatilitypremium", "termpremium", "treasurymarket", "investgradespread", "highyieldspread"),
  # transformation = "fd",  # First-difference "fd" or forward orthogonal deviations "fod"
  data = data,
  panel_identifier = c("bank", "date"),  # Vector of panel identifiers
  steps = c("onestep")#,   # "onestep", "twostep" or "mstep" estimation
  # system_instruments = FALSE,  #    System GMM estimator
  # max_instr_dependent_vars = 99, #  Maximum number of instruments for dependent variables
  # min_instr_dependent_vars = 2L, # Minimum number of instruments for dependent variables
  # collapse = FALSE
)
summary(pvar2)

models <- list()
models[["refinitiv_lag1"]] <- summary(pvar2)
models[["refinitiv_lag1"]]["sample"] <- "European Banks"
models[["refinitiv_lag1"]]["obsperiod"] <- paste(min(as.Date(data$date)), "to", max(as.Date(data$date)))




data <- df |> 
  dplyr::select(
    bank, date, sentiment, sentiment_l1, sentiment_l2, sentiment_l3, sentiment_l4, sentiment_l5, cds, stockmarket, volatilitypremium,
    termpremium, treasurymarket, investgradespread, highyieldspread, stockreturn
  )
data <- data[complete.cases(data),]
data <- as.data.frame(data)
data$bank <- as.factor(data$bank)
data$date <- as.factor(data$date)

pvar2 <- panelvar::pvargmm(
  dependent_vars = c("cds"),
  lags = 5, # Number of lags of dependent variables
  exog_vars = c("sentiment_l1", "sentiment_l2", "sentiment_l3", "sentiment_l4", "sentiment_l5", "stockmarket", "volatilitypremium", "termpremium", "treasurymarket", "investgradespread", "highyieldspread", "stockreturn"),
  # transformation = "fd",  # First-difference "fd" or forward orthogonal deviations "fod"
  data = data,
  panel_identifier = c("bank", "date"),  # Vector of panel identifiers
  steps = c("onestep")#,   # "onestep", "twostep" or "mstep" estimation
  # system_instruments = FALSE,  #    System GMM estimator
  # max_instr_dependent_vars = 99, #  Maximum number of instruments for dependent variables
  # min_instr_dependent_vars = 2L, # Minimum number of instruments for dependent variables
  # collapse = FALSE
)
summary(pvar2)
models[["refinitiv_lag5"]] <- summary(pvar2)
models[["refinitiv_lag5"]]["sample"] <- "European Banks"
models[["refinitiv_lag5"]]["obsperiod"] <- paste(min(as.Date(data$date)), "to", max(as.Date(data$date)))


pvar2 <- panelvar::pvargmm(
  dependent_vars = c("cds"),
  lags = 5, # Number of lags of dependent variables
  exog_vars = c("sentiment", "sentiment_l1", "sentiment_l2", "sentiment_l3", "sentiment_l4", "sentiment_l5", "stockmarket", "volatilitypremium", "termpremium", "treasurymarket", "investgradespread", "highyieldspread", "stockreturn"),
  # transformation = "fd",  # First-difference "fd" or forward orthogonal deviations "fod"
  data = data,
  panel_identifier = c("bank", "date"),  # Vector of panel identifiers
  steps = c("onestep")#,   # "onestep", "twostep" or "mstep" estimation
  # system_instruments = FALSE,  #    System GMM estimator
  # max_instr_dependent_vars = 99, #  Maximum number of instruments for dependent variables
  # min_instr_dependent_vars = 2L, # Minimum number of instruments for dependent variables
  # collapse = FALSE
)
summary(pvar2)



pvar2 <- panelvar::pvargmm(
  dependent_vars = c("cds"),
  lags = 1, # Number of lags of dependent variables
  exog_vars = c("sentiment", "stockmarket", "volatilitypremium", "termpremium", "treasurymarket", "investgradespread", "highyieldspread"),
  # transformation = "fd",  # First-difference "fd" or forward orthogonal deviations "fod"
  data = data_swiss,
  panel_identifier = c("bank", "date"),  # Vector of panel identifiers
  steps = c("onestep")#,   # "onestep", "twostep" or "mstep" estimation
  # system_instruments = FALSE,  #    System GMM estimator
  # max_instr_dependent_vars = 99, #  Maximum number of instruments for dependent variables
  # min_instr_dependent_vars = 2L, # Minimum number of instruments for dependent variables
  # collapse = FALSE
)
summary(pvar2)

models[["swissdox_lag1"]] <- summary(pvar2)
models[["swissdox_lag1"]]["sample"] <- "Swiss Banks"
models[["swissdox_lag1"]]["obsperiod"] <- paste(min(as.Date(data_swiss$date)), "to", max(as.Date(data_swiss$date)))

# THIS SEEMS TO BE MY HOPE.........
data <- df_swiss |> 
  dplyr::select(
    bank, date, sentiment, sentiment_l1, sentiment_l2, sentiment_l3, sentiment_l4, sentiment_l5, cds, stockmarket, volatilitypremium,
    termpremium, treasurymarket, investgradespread, highyieldspread
  )
data <- data[complete.cases(data),]
data <- as.data.frame(data)
data$bank <- as.factor(data$bank)
data$date <- as.factor(data$date)
pvar2 <- panelvar::pvargmm(
  dependent_vars = c("cds"),
  lags = 5, # Number of lags of dependent variables
  exog_vars = c("sentiment_l1", "sentiment_l2", "sentiment_l3", "sentiment_l4", "sentiment_l5", "stockmarket", "volatilitypremium", "termpremium", "treasurymarket", "investgradespread", "highyieldspread"),
  # transformation = "fd",  # First-difference "fd" or forward orthogonal deviations "fod"
  data = data,
  panel_identifier = c("bank", "date"),  # Vector of panel identifiers
  steps = c("onestep")#,   # "onestep", "twostep" or "mstep" estimation
  # system_instruments = FALSE,  #    System GMM estimator
  # max_instr_dependent_vars = 99, #  Maximum number of instruments for dependent variables
  # min_instr_dependent_vars = 2L, # Minimum number of instruments for dependent variables
  # collapse = FALSE
)
summary(pvar2)

models[["swissdox_lag5"]] <- summary(pvar2)
models[["swissdox_lag5"]]["sample"] <- "Swiss Banks"
models[["swissdox_lag5"]]["obsperiod"] <- paste(min(as.Date(data$date)), "to", max(as.Date(data$date)))



create_table(models, "Panel VAR sentiment", "cdspvar", small_font = T)

create_table(models[1:2], "Panel VAR sentiment, European Bank Sample", "cdspvar_euro")
create_table(models[3:4], "Panel VAR sentiment, Swiss Bank Sample", "cdspvar_swiss")



