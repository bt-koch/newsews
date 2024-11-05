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
        sentiment_wma = as.numeric(stats::filter(sentiment, (n:1)/sum(n:1), sides = 1))
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
    dplyr::select(bank, date, sentiment, sentiment_sma, sentiment_wma, cds, cds_return)


# fit model ----
data <- df |> 
    dplyr::select(bank, date, sentiment_wma, cds_return) |> 
    filter(!is.na(sentiment_wma) & !is.na(cds_return))

data$bank <- as.factor(data$bank)
data_var <- data[, c("sentiment_wma", "cds_return")]

tseries::adf.test(data_var$sentiment_wma)
tseries::adf.test(data_var$cds_return)

var_model <- vars::VAR(data_var, ic = "AIC")
summary(var_model)

