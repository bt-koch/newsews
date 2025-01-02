create_table <- function(models, caption, label, autoscale = T) {
  
  if ("plm" %in% class(models[[1]])) {
    content <- create_table_plm(models)
  } else if ("summary.pvarfeols" %in% class(models[[1]])) {
    content <- create_table_pvarfeols(models)
  } else if ("summary.pvargmm" %in% class(models[[1]])) {
    content <- create_table_pvargmm(models)
  } else if ("garchx" %in% class(models[[1]])) {
    content <- create_table_garchx(models)
  } else if ("HARmodel" %in% class(models[[1]])) {
    content <- create_table_har(models)
  } else {
    stop("Not specified for this class of model.")
  }
  
  footnote <- "Notes: *** p\\textless{}0.01, ** p\\textless{}0.05, * p\\textless{}0.1. Standard errors reported in parantheses."
  
  textable <- c(
    "\\begin{table}[H]",
    "\\centering",
    if (autoscale) "\\resizebox{\\textwidth}{!}{",
    paste0("\\begin{tabular}{l", strrep("r", ncol(content)-1), "}"),
    paste(paste(names(content), collapse = "&"), "\\\\ \\hline"),
    paste(apply(content, 1, paste, collapse = "&"), "\\\\"),
    "\\hline",
    paste0("\\multicolumn{", ncol(content), "}{l}{", footnote, "}"),
    "\\end{tabular}",
    if (autoscale) "}",
    "",
    paste0("\\caption{", caption, "}"),
    paste0("\\label{tab:", label, "}"),
    "\\end{table}"
  )
  
  output_file <- file(paste0("tex/tables/", label, ".tex"))
  writeLines(textable, output_file)
  close(output_file)
  
}

create_table_plm <- function(models) {
  
  output <- data.frame()
  
  for (i in 1:length(models)) {
    
    temp <- models[[i]]$coefficients |> 
      as.data.frame() |> 
      tibble::rownames_to_column("variable") |> 
      mutate(
        significance = if_else(`Pr(>|t|)` < 0.1, "*", ""),
        significance = if_else(`Pr(>|t|)` < 0.05, "**", significance),
        significance = if_else(`Pr(>|t|)` < 0.01, "***", significance),
        summary = paste0(round(Estimate, 3), significance, " (", round(`Std. Error`, 2), ")"),
        sort_index = 1
        ) |> 
      select(variable, summary, sort_index) |> 
      add_row(
        variable = "$R^2$",
        summary = models[[i]]$r.squared["rsq"] |> round(2) |> as.character(),
        sort_index = 2
      ) |> 
      add_row(
        variable = "adj. $R^2$",
        summary = models[[i]]$r.squared["adjrsq"] |> round(2) |> as.character(),
        sort_index = 3
      ) |> 
      add_row(
        variable = "Sample", summary = models[[i]]$sample,
        sort_index = 4
      ) |> 
      add_row(
        variable = "Groups", summary = models[[i]]$groups |> as.character(),
        sort_index = 5
      ) |> 
      add_row(
        variable = "Number of Obs.", summary = models[[i]]$nobs |> as.character(),
        sort_index = 6
      ) |> 
      add_row(
        variable = "Obs. Period", summary = models[[i]]$obsperiod,
        sort_index = 7
      )
    
    if (ncol(output) == 0) {
      output <- temp
    } else {
      output <- merge(output, temp, by = c("variable", "sort_index"), all = T)
    }
  }
  
  output <- output |> 
    mutate(
      sort_index = if_else(variable == "sentiment", 0, sort_index),
      variable = if_else(variable == "corpbondspread", "corporate bond spread", variable),
      variable = if_else(variable == "equivol", "equity volatility", variable),
      variable = if_else(variable == "marketreturn", "market return", variable),
      variable = if_else(variable == "marketvola", "market volatility", variable),
      variable = if_else(variable == "riskfree", "risk free rate", variable),
      variable = if_else(variable == "termstructure", "term structure", variable)
    )
  
  output <- output |> 
    arrange(sort_index) |> 
    select(!sort_index)
  
  names(output) <- c("", paste("Model", 1:(ncol(output)-1)))
  output[is.na(output)] <- ""
  
  return(output)
}

create_table_pvarfeols <- function(models) {
  
  output <- data.frame()
  
  for (i in 1:length(models)) {
    
    temp <- data.frame(
      variable = models[[i]]$results[[1]]@coef.names,
      coeff = models[[i]]$results[[1]]@coef,
      se = models[[i]]$results[[1]]@se,
      pval = models[[i]]$results[[1]]@pvalues
    ) |> 
      mutate(
        significance = if_else(pval < 0.1, "*", ""),
        significance = if_else(pval < 0.05, "**", significance),
        significance = if_else(pval < 0.01, "***", significance),
        summary = paste0(round(coeff, 3), significance, " (", round(se, 2), ")"),
        sort_index = 3,
        sort_index = if_else(endsWith(variable, "cds") | endsWith(variable, "md"), 2, sort_index),
        sort_index = if_else(endsWith(variable, "sentiment") | endsWith(variable, "wma") | endsWith(variable, "wma_adj"), 1, sort_index),
        variable = gsub("legal|product_news|personnel_change", "", variable)
      ) |> 
      select(variable, summary, sort_index) |>
      add_row(
        variable = "Sample", summary = models[[i]]$sample,
        sort_index = 4
      ) |> 
      add_row(
        variable = "Groups", summary = models[[i]]$nof_groups |> as.character(),
        sort_index = 5
      ) |> 
      add_row(
        variable = "Number of Obs.", summary = models[[i]]$nof_observations |> as.character(),
        sort_index = 6
      ) |> 
      add_row(
        variable = "Obs. Period", summary = models[[i]]$obsperiod,
        sort_index = 7
      )
    
    if ("demeaned_lag1_sentiment_legal" %in% models[[i]]$results[[1]]@coef.names) {
      name <- "Legal"
    } else if ("demeaned_lag1_sentiment_product_news" %in% models[[i]]$results[[1]]@coef.names) {
      name <- "Product News"
    } else if ("demeaned_lag1_sentiment_personnel_change" %in% models[[i]]$results[[1]]@coef.names) {
      name <- "Personnel Change"
    } else {
      name <- paste("Model", i)
    }
    
    names(temp)[names(temp) == "summary"] <- name
    temp$variable <- gsub("_", " ", temp$variable)
    
    if (ncol(output) == 0) {
      output <- temp
    } else {
      output <- merge(output, temp, by = c("variable", "sort_index"), all = T)
    }
  }
  
  output <- output |> 
    mutate(
      variable = gsub("demeaned ", "", variable),
      variable = gsub("l1", "$(t-1)$", variable),
      variable = gsub("^lag(\\d+)\\s(.+)", "\\2 $(t-\\1)$", variable),
      variable = gsub("stockmarket", "stock market", variable),
      variable = gsub("termpremium", "term premium", variable),
      variable = gsub("treasurymarket", "treasury market", variable),
      variable = gsub("volatilitypremium", "volatility premium", variable),
      variable = gsub("highyieldspread", "high yield spread", variable),
      variable = gsub("investgradespread", "investment grade spread", variable)
    )

  
  output <- output |> 
    mutate(sort_index = if_else(grepl("sentiment", variable), 1, sort_index)) |> 
    arrange(sort_index) |> 
    select(!sort_index)
  
  names(output)[names(output) == "variable"] <- ""
  output[is.na(output)] <- ""
  
  return(output)
  
}

create_table_pvargmm <- function(models) {
  
  output <- data.frame()
  
  for (i in 1:length(models)) {
    
    temp <- data.frame(
      variable = models[[i]]$results[[1]]@coef.names,
      coeff = models[[i]]$results[[1]]@coef,
      se = models[[i]]$results[[1]]@se,
      pval = models[[i]]$results[[1]]@pvalues
    ) |> 
      mutate(
        significance = if_else(pval < 0.1, "*", ""),
        significance = if_else(pval < 0.05, "**", significance),
        significance = if_else(pval < 0.01, "***", significance),
        summary = paste0(round(coeff, 3), significance, " (", round(se, 2), ")"),
        sort_index = 1
      ) |> 
      select(variable, summary, sort_index) |>
      add_row(
        variable = "Sample", summary = models[[i]]$sample,
        sort_index = 4
      ) |> 
      add_row(
        variable = "Groups", summary = models[[i]]$nof_groups |> as.character(),
        sort_index = 5
      ) |> 
      add_row(
        variable = "Number of Obs.", summary = models[[i]]$nof_observations |> as.character(),
        sort_index = 6
      ) |> 
      add_row(
        variable = "Obs. Period", summary = models[[i]]$obsperiod,
        sort_index = 7
      )
    
    names(temp)[names(temp) == "summary"] <- paste("Model", i)
    temp$variable <- gsub("_", " ", temp$variable)
    
    if (ncol(output) == 0) {
      output <- temp
    } else {
      output <- merge(output, temp, by = c("variable", "sort_index"), all = T)
    }
  }
  
  output <- output |> 
    arrange(sort_index) |> 
    select(!sort_index)
  
  names(output)[names(output) == "variable"] <- ""
  output[is.na(output)] <- ""
  
  return(output)
}

create_table_garchx <- function(models) {
  
  output <- data.frame()
  
  for (i in 1:length(models)) {
    
    ttest <- models[[i]] |> 
      garchx::ttest0()
    
    temp <- rbind(
      c(ttest[1,1], ttest[1,2], ttest[1,4]),
      c(ttest[2,1], ttest[2,2], ttest[2,4]),
      c(ttest[3,1], ttest[3,2], ttest[3,4])
    ) |> 
      as.data.frame() |> 
      rename(coeff = 1, se = 2, pval = 3) |> 
      mutate(
        significance = if_else(pval < 0.1, "*", ""),
        significance = if_else(pval < 0.05, "**", significance),
        significance = if_else(pval < 0.01, "***", significance),
        summary =  paste0(round(coeff, 3), significance, " (", round(se, 2), ")")
      ) |> 
      add_row(summary = as.character(models[[i]]$y.n)) |> 
      add_row(summary = models[[i]]$obsperiod) |> 
      cbind(dimension = c("$e^2_{t-1}$", "$\\sigma^2_{t-1}$", "$\\tilde{s}_{b,t-1}$", "Number of Obs.", "Obs. Period")) |> 
      select(dimension, summary)
    
    if (ncol(output) == 0) {
      output <- temp
    } else {
      output <- merge(output, temp, by = "dimension")
    }
    
    output <- output |> 
      rename(!!models[[i]]$sample := summary)
  }
  
  names(output)[names(output) == "dimension"] <- ""
  
  return(output)
  
}

create_table_har <- function(models) {
  
  output <- data.frame()
  
  for (i in 1:length(models)) {
    
    summary <- summary(models[[i]])
    
    temp <- summary$coefficients |> 
      as.data.frame() |>
      mutate(
        significance = if_else(`Pr(>|t|)` < 0.1, "*", ""),
        significance = if_else(`Pr(>|t|)` < 0.05, "**", significance),
        significance = if_else(`Pr(>|t|)` < 0.01, "***", significance),
        summary = paste0(round(Estimate, 3), significance, " (", round(`Std. Error`, 2), ")")
      ) |> 
      cbind(variable = rownames(summary$coefficients)) |> 
      select(variable, summary) |> 
      add_row(variable = "Sample", summary = models[[i]]$sample) |> 
      add_row(variable = "Number of Obs.", summary = models[[i]]$nobs |> as.character()) |> 
      add_row(variable = "Obs. Period", summary = models[[i]]$obsperiod)
    
    if (ncol(output) == 0) {
      output <- temp
    } else {
      output <- merge(output, temp, by = "variable")
    }
    
    output <- output |> 
      rename(!!models[[i]]$sample := summary)
    
  }
  
  output <- output |> 
    mutate(
      variable = if_else(variable == "beta0", "$\\alpha_b$", variable),
      variable = if_else(variable == "beta1", "$\\sigma^2_{b,t-2:t}$", variable),
      variable = if_else(variable == "beta2", "$\\sigma^2_{b,t-6:t}$", variable),
      variable = if_else(variable == "beta3", "$\\sigma^2_{b,t-21:t}$", variable),
      variable = if_else(variable == "beta4", "$\\tilde{s}_{b,t-1}$", variable)
    )
  
  names(output)[names(output) == "variable"] <- ""
  
  return(output)
  
}

create_table_granger <- function(dataframe, caption, label, autoscale = TRUE) {
  
  footnote <- "Notes: *** p\\textless{}0.01, ** p\\textless{}0.05, * p\\textless{}0.1."
  
  format_pval <- function(p) {
    rounded <- sprintf("%.2f", p)
    if (p < 0.01) {
      return(paste0(rounded, "***"))
    } else if (p < 0.05) {
      return(paste0(rounded, "**"))
    } else if (p < 0.1) {
      return(paste0(rounded, "*"))
    } else {
      return(as.character(rounded))
    }
  }
  
  content <- dataframe |> 
    mutate(across(-lags, ~ sapply(.x, format_pval)))
  
  stopifnot(identical(names(content), c("lags", "cds_on_senti_cs", "senti_on_cds_cs", "cds_on_senti_ubs", "senti_on_cds_ubs")))
  
  content <- cbind(content[, 1:3], `_` = "", content[, 4:5])
  
  names(content) <- gsub("_", " ", names(content))

  textable <- c(
    "\\begin{table}[H]",
    "\\centering",
    if (autoscale) "\\resizebox{\\textwidth}{!}{",
    "\\begin{tabular}{cccccc}",
    "& \\multicolumn{2}{c}{Credit Suisse} &  & \\multicolumn{2}{c}{UBS} \\\\ \\cline{2-3} \\cline{5-6}",
    "& $s$ causes $cdsspread$ & $cdsspread$ causes $s$ &  & $s$ causes $cdsspread$ & $cdsspread$ causes $s$ \\\\ \\hline",
    paste(apply(content, 1, paste, collapse = "&"), "\\\\"),
    "\\hline",
    paste0("\\multicolumn{", ncol(content), "}{l}{", footnote, "}"),
    "\\end{tabular}",
    if (autoscale) "}",
    "",
    paste0("\\caption{", caption, "}"),
    paste0("\\label{tab:", label, "}"),
    "\\end{table}"
  )
  
  output_file <- file(paste0("tex/tables/", label, ".tex"))
  writeLines(textable, output_file)
  close(output_file)
  
}

create_timestamp <- function(dataframe) {
  
  timestamp <- paste0(
    format(min(as.Date(dataframe$date)), "%b %Y"),
    "-",
    format(max(as.Date(dataframe$date)), "%b %Y")
  )
  
  return(timestamp)
}
