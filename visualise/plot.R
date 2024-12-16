create_plot_irfs <- function(oirfs) {
  
  png(filename="tex/images/oirfs.png", width = 600, height = 400, res = 72)
  
  lwd = 1.5
  lwd_grid = 0.75
  
  ymin <- min(c(oirfs$cds, oirfs$sentiment))
  ymax <- max(c(oirfs$cds, oirfs$sentiment))
  
  xvals <- 0:(length(oirfs$cds[,1])-1)

  par(mfrow = c(2,2), oma = c(2,4,1,1) + 0.1, mar = c(1,0,1,1) + 0.1)
  
  plot(xvals, oirfs$cds[,1], type = "n", xlab = "", ylab = "", xaxt = "n", yaxt = "n",
       ylim = c(ymin, ymax))
  grid(nx = NULL, ny = NULL, lty = 2, col = "gray", lwd = lwd_grid)
  par(new = T)
  plot(xvals, oirfs$cds[,1], type = "l", ylim = c(ymin, ymax), xlab = "", ylab = "",
       xaxt = "n", main = "cds on cds", lwd = lwd)
  
  plot(xvals, oirfs$cds[,2], type = "n", xlab = "", ylab = "", xaxt = "n", yaxt = "n",
       ylim = c(ymin, ymax))
  grid(nx = NULL, ny = NULL, lty = 2, col = "gray", lwd = lwd_grid)
  par(new = T)
  plot(xvals, oirfs$cds[,2], type = "l", ylim = c(ymin, ymax), xlab = "", ylab = "",
       xaxt = "n", yaxt = "n", main = "cds on sentiment", lwd = lwd)
  
  plot(xvals, oirfs$cds[,2], type = "n", xlab = "", ylab = "", xaxt = "n", yaxt = "n",
       ylim = c(ymin, ymax))
  grid(nx = NULL, ny = NULL, lty = 2, col = "gray", lwd = lwd_grid)
  par(new = T)
  plot(xvals, oirfs$sentiment[,1], type = "l", ylim = c(ymin, ymax), xlab = "", ylab = "",
       main = "sentiment on cds", lwd = lwd)
  
  plot(xvals, oirfs$cds[,2], type = "n", xlab = "", ylab = "", xaxt = "n", yaxt = "n",
       ylim = c(ymin, ymax))
  grid(nx = NULL, ny = NULL, lty = 2, col = "gray", lwd = lwd_grid)
  par(new = T)
  plot(xvals, oirfs$sentiment[,2], type = "l", ylim = c(ymin, ymax), xlab = "", ylab = "",
       yaxt = "n", main = "sentiment on sentiment", lwd = lwd)
  
  
  
  dev.off()
  
}
