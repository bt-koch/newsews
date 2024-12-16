rm(list=ls()); gc()
source("config/environvars.R")
library(tidyverse)

# =============================================================================.
# swissdox ----
# =============================================================================.
df <- read.csv(file.path(paths$path_preprocessed, "dataset_clean.csv"), sep = ";") |> 

n_articles <- df |> 
  group_by(query_bank) |> 
  summarise(n_articles = n()) |> 
  ungroup()

n_articles_day <- df |> 
  mutate(date = as.Date(pubtime)) |> 
  group_by(query_bank, date) |> 
  summarise(n_articles = n()) |> 
  group_by(query_bank) |> 
  summarise(n_articles_mean = mean(n_articles))

output <- merge(x = n_articles, y = n_articles_day, by = "query_bank")


# =============================================================================.
# refinitiv ----
# =============================================================================.
df <- read.csv(file.path(paths$path_preprocessed, "dataset_clean.csv"), sep = ";")

check_rule <- read.csv(file.path(paths$path_refinitiv, "dataset_newsarticles_count.csv"), sep = ";") |> 
  filter(date >= as.Date("2023-09-16"))
mean(check_rule$n_articles > 5)
