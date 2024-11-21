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

# risk free rate
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

# leverage
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
    rename(bank = Instrument) |> 
    select(bank, date, leverage)

# equity volatility
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
    rename(bank = Instrument) |> 
    select(bank, equivol, date)

# term structure slope
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

# corporate bond spread
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

# market return
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

# market volatility
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

# sentiment
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

meta_ric <- read.csv(file.path(paths$path_meta, "mapping_ric.csv"), sep = ";")

pvals <- c()
for (n in 1:20) {
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

    # create dataset
    df <- sentiment |> 
        left_join(y = meta_ric, by = c("bank" = "query_bank")) |> 
        left_join(y = cds, by = c("date", "ric" = "bank")) |> 
        left_join(y = riskfree, by = "date") |> 
        left_join(y = leverage, by = c("date", "ric" = "bank")) |> 
        left_join(y = equivol, by = c("date", "ric" = "bank")) |> 
        left_join(y = termstructure, by = "date") |> 
        left_join(y = corpbondspread, by = "date") |> 
        left_join(y = marketreturn, by = "date") |> 
        left_join(y = marketvola, by = "date")

    result <- plm::plm(cds ~ riskfree + leverage + equivol + termstructure + corpbondspread + marketreturn + marketvola + sentiment, data = df, index = c("bank", "date"))
    pval <- summary(result)$coefficients[names(result$coefficients) == "sentiment", 4]
    pvals <- c(pvals, pval)
}

n = 6
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

# create dataset
df <- sentiment |> 
    left_join(y = meta_ric, by = c("bank" = "query_bank")) |> 
    left_join(y = cds, by = c("date", "ric" = "bank")) |> 
    left_join(y = riskfree, by = "date") |> 
    left_join(y = leverage, by = c("date", "ric" = "bank")) |> 
    left_join(y = equivol, by = c("date", "ric" = "bank")) |> 
    left_join(y = termstructure, by = "date") |> 
    left_join(y = corpbondspread, by = "date") |> 
    left_join(y = marketreturn, by = "date") |> 
    left_join(y = marketvola, by = "date")

result <- plm::plm(cds ~ riskfree + leverage + equivol + termstructure + corpbondspread + marketreturn + marketvola + sentiment_wma, data = df, index = c("bank", "date"))
summary(result)

n = 3
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

# create dataset
df <- sentiment |> 
    left_join(y = meta_ric, by = c("bank" = "query_bank")) |> 
    left_join(y = cds, by = c("date", "ric" = "bank")) |> 
    left_join(y = riskfree, by = "date") |> 
    left_join(y = leverage, by = c("date", "ric" = "bank")) |> 
    left_join(y = equivol, by = c("date", "ric" = "bank")) |> 
    left_join(y = termstructure, by = "date") |> 
    left_join(y = corpbondspread, by = "date") |> 
    left_join(y = marketreturn, by = "date") |> 
    left_join(y = marketvola, by = "date")

result <- plm::plm(cds ~ riskfree + leverage + equivol + termstructure + corpbondspread + marketreturn + marketvola + sentiment, data = df, index = c("bank", "date"))
summary(result)


# just to test run simple(st) VAR
data <- df |> 
    dplyr::select(bank, date, sentiment, cds)

data$bank <- as.factor(data$bank)
data_var <- data[, c("sentiment", "cds")]

tseries::adf.test(data_var$sentiment)
tseries::adf.test(data_var$cds)

var_model <- vars::VAR(data_var, ic = "AIC")
summary(var_model)

n = 3
sentiment <- read.csv(file.path(paths$path_results, "sentiment_scores.csv"), sep = ";") |> 
    filter(bank %in% c("ubs")) |> 
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

