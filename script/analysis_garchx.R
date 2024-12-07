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

n <- 14
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
  merge(y = meta_ric, by.x = "Instrument", by.y = "ric") |> 
  group_by(query_bank) |> 
  mutate(
    date = as.Date(Date),
    return = (Close.Price-lag(Close.Price))/lag(Close.Price)
  )


test <- garchx::garchx(stocks |> filter(query_bank == "credit_suisse") |> pull(return))
garchx::ttest0(test)


data <- sentiment_swiss |> 
  left_join(y = stocks, by = c("bank" = "query_bank", "date")) |> 
  group_by(bank) |> 
  arrange(bank, date) |> 
  select(date, bank, return, sentiment_wma)

df <- data |> 
  filter(bank == "credit_suisse") |> 
  filter(!is.na(return) & !is.na(sentiment_wma))

test <- garchx::garchx(df$return, xreg = df$sentiment_wma)
garchx::ttest0(test)
