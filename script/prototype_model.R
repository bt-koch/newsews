rm(list=ls()); gc()
library(dplyr)

source("config/environvars.R")

# prepare data ----
# note: seems to be good resource for normalisation of time series: 
# https://www.sciencedirect.com/science/article/pii/S2214579623000400

n <- 10

sentiment <- read.csv("data/sentiment_scores.csv", sep = ";") |> 
    filter(bank %in% c("credit_suisse", "ubs")) |> 
    mutate(
        date = as.Date(date),
        week = cut.Date(date, breaks = "1 week", labels = FALSE)
    ) |> 
    group_by(bank, date) |> 
    reframe(sentiment = mean(sentiment_score)) |> 
    group_by(bank) |> 
    mutate(
        sentiment_sma = as.numeric(stats::filter(sentiment, rep(1/n,n), sides = 1)),
        sentiment_wma = as.numeric(stats::filter(sentiment, (n:1)/sum(n:1), sides = 1)),
        sentiment_l1 = lag(sentiment),
        sentiment_l2 = lag(sentiment, 2),
        sentiment_l3 = lag(sentiment, 3),
        sentiment_l4 = lag(sentiment, 4),
        sentiment_l5 = lag(sentiment, 5)
    )

cds <- read.csv(file.path(paths$path_refinitiv, "cds.csv"), sep = ";")  |> 
    mutate(
        bank = if_else(ric_equity == "UBSG.S", "ubs", "credit_suisse"),
        date = as.Date(date),
        week = cut.Date(date, breaks = "1 week", labels = FALSE),
        cds_return = (value-lag(value))/lag(value)
    ) |> 
    # group_by(date) |> 
    # slice_max(order_by = date, n = 1) |> 
    # ungroup() |> 
    # mutate(cds_return = (value-lag(value))/lag(value)) |> 
    rename(cds = value)

df <- left_join(x = sentiment, y = cds, by = c("bank", "date"))  |> 
    dplyr::select(bank, date, sentiment, sentiment_sma, sentiment_wma, cds, cds_return,
                  sentiment_l1, sentiment_l2, sentiment_l3, sentiment_l4, sentiment_l5)


# fit model ----
data <- df |> 
    dplyr::select(bank, date, sentiment_wma, cds_return) |> 
    filter(!is.na(sentiment_wma) & !is.na(cds_return))

data <- df
data <- data[complete.cases(data),]

data$bank <- as.factor(data$bank)
data_var <- data[, c("sentiment_wma", "cds_return")]
data_var <- data[, c("sentiment", "cds_return")]

tseries::adf.test(data_var$sentiment)
tseries::adf.test(data_var$cds_return)

var_model <- vars::VAR(data_var, ic = "AIC")
summary(var_model)

