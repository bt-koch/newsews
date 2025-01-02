create_plot_irfs <- function(girfs) {
  
  png(filename="tex/images/girfs.png", width = 600, height = 400, res = 72)
  
  lwd = 1.5
  lwd_grid = 0.75
  
  ymin <- min(c(girfs$cds, girfs$sentiment))
  ymax <- max(c(girfs$cds, girfs$sentiment))
  
  xvals <- 1:(length(girfs$cds[,1]))

  par(mfrow = c(2,2), oma = c(4,4,1,4) + 0.1, mar = c(1,0,1,1) + 0.1)
  
  plot(xvals, girfs$cds[,1], type = "n", xlab = "", ylab = "", xaxt = "n", yaxt = "n",
       ylim = c(ymin, ymax))
  grid(nx = NULL, ny = NULL, lty = 2, col = "gray", lwd = lwd_grid)
  par(new = T)
  plot(xvals, girfs$cds[,1], type = "l", ylim = c(ymin, ymax), xlab = "", ylab = "",
       xaxt = "n", main = "cds on cds", lwd = lwd)
  
  plot(xvals, girfs$cds[,2], type = "n", xlab = "", ylab = "", xaxt = "n", yaxt = "n",
       ylim = c(ymin, ymax))
  grid(nx = NULL, ny = NULL, lty = 2, col = "gray", lwd = lwd_grid)
  par(new = T)
  plot(xvals, girfs$cds[,2], type = "l", ylim = c(ymin, ymax), xlab = "", ylab = "",
       xaxt = "n", yaxt = "n", main = "cds on sentiment", lwd = lwd)
  
  plot(xvals, girfs$cds[,2], type = "n", xlab = "", ylab = "", xaxt = "n", yaxt = "n",
       ylim = c(ymin, ymax))
  grid(nx = NULL, ny = NULL, lty = 2, col = "gray", lwd = lwd_grid)
  par(new = T)
  plot(xvals, girfs$sentiment[,1], type = "l", ylim = c(ymin, ymax), xlab = "", ylab = "",
       main = "sentiment on cds", lwd = lwd)
  
  plot(xvals, girfs$cds[,2], type = "n", xlab = "", ylab = "", xaxt = "n", yaxt = "n",
       ylim = c(ymin, ymax))
  grid(nx = NULL, ny = NULL, lty = 2, col = "gray", lwd = lwd_grid)
  par(new = T)
  plot(xvals, girfs$sentiment[,2], type = "l", ylim = c(ymin, ymax), xlab = "", ylab = "",
       yaxt = "n", main = "sentiment on sentiment", lwd = lwd)
  
  mtext("Steps (weeks)", side = 1, outer = TRUE, line = 2)
  mtext("Change in standard deviations", side = 2, outer = TRUE, line = 2.5)
  
  dev.off()
  
}
