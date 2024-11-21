rm(list = ls()); gc()
library(dplyr)

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
n <- 3
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
        sentiment = lag(sentiment_wma)
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
    left_join(y = highyieldspread, by = "date")

# panel regression
result <- plm::plm(cds ~ sentiment+stockmarket+volatilitypremium+termpremium+treasurymarket+investgradespread+highyieldspread, data = df, index = c("bank", "date"))
summary(result)

# simple VAR
data <- df |> 
    dplyr::select(
        bank, date, sentiment, cds, stockmarket, volatilitypremium,
        termpremium, treasurymarket, investgradespread, highyieldspread
    )
data <- data[complete.cases(data),]
data$bank <- as.factor(data$bank)
data_var <- data[, c("sentiment", "cds", "stockmarket", "volatilitypremium", "termpremium", "treasurymarket", "investgradespread", "highyieldspread")]
tseries::adf.test(data_var$sentiment)
tseries::adf.test(data_var$cds)
var_model <- vars::VAR(data_var, ic = "AIC")
summary(var_model)

# panel var
data <- as.data.frame(data)
data$bank <- as.factor(data$bank)
data$date <- as.factor(data$date)
pvar1 <- panelvar::pvarfeols(
    dependent_vars = c("cds"),
    lags = 1,
    exog_vars = c("sentiment", "stockmarket", "volatilitypremium", "termpremium", "treasurymarket", "investgradespread", "highyieldspread"),
    transformation = "demean",
    data = data,
    panel_identifier= c("bank", "date"))
summary(pvar1)

pvar2 <- panelvar::pvargmm(
  dependent_vars = c("cds"),
  lags = 4, # Number of lags of dependent variables
  exog_vars = c("sentiment", "stockmarket", "volatilitypremium", "termpremium", "treasurymarket", "investgradespread", "highyieldspread"),
  transformation = "fd",  # First-difference "fd" or forward orthogonal deviations "fod"
  data = data,
  panel_identifier = c("bank", "date"),  # Vector of panel identifiers
  steps = c("onestep"),   # "onestep", "twostep" or "mstep" estimation
  system_instruments = FALSE,  #    System GMM estimator
  max_instr_dependent_vars = 99, #  Maximum number of instruments for dependent variables
  min_instr_dependent_vars = 2L, # Minimum number of instruments for dependent variables
  collapse = FALSE
)
summary(pvar2)




