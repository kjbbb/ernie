# TODO this file is a hack! find a better solution with ggplot2?

t <- read.csv("stats/torperf-stats")

intervals <- c("6m", "2w")
intervalsStr <- c("-6 months", "-2 weeks")

for (intervalInd in 1:length(intervals)) {
  interval <- intervals[intervalInd]
  intervalStr <- intervalsStr[intervalInd]

  end <- seq(from = Sys.Date(), length = 2, by = "-1 day")[2]
  start <- seq(seq(from = end, length = 2,
      by=intervalStr)[2], length=2, by="1 day")[2]
  dates <- seq(from = start, to = end, by="1 day")
  datesStr <- as.character(dates)
  firstdays <- c()
  for (i in datesStr)
    if (intervalInd == 2 || format(as.POSIXct(i, tz="GMT"), "%d") == "01")
      firstdays <- c(firstdays, i)
  monthticks <- which(datesStr %in% firstdays)
  monthlabels <- c() 
  for (i in monthticks[1:(length(monthticks) - 2)])
    monthlabels <- c(monthlabels,
        format(as.POSIXct(dates[i + 1], tz="GMT"),
        ifelse(intervalInd == 1, "%b", "%b %d")))
  monthlabels <- c(monthlabels,
      format(as.POSIXct(dates[monthticks[length(monthticks) - 1] + 1]),
      ifelse(intervalInd == 1, "%b %y", "%b %d")))
  if (intervalInd == 2)
    monthlabels[length(monthlabels)] <- ""
  monthat <- c()
  for (i in 1:(length(monthticks) - 1))
    monthat <- c(monthat, (monthticks[i] + monthticks[i + 1]) / 2 + .5)

  sources <- c("gabelmoo", "moria", "torperf")
  colors <- c("#0000EE", "#EE0000", "#00CD00")
  sizes <- c("5mb", "1mb", "50kb")
  sizePrint <- c("5 MiB", "1 MiB", "50 KiB")

  for (sizeInd in 1:length(sizes)) {
    size <- sizes[sizeInd]
    sizePr <- sizePrint[sizeInd]
    png(paste("website/graphs/torperf-", size, "-", interval, ".png",
        sep = ""), width=600, height=800)
    par(mfrow=c(3, 1))
    par(mar=c(4.3,3.1,2.1,0.1))
    maxY <- max(na.omit(subset(t, source %in% paste(sources, size,
        sep = "-"))$q3)) / 1e3 * .8
    for (sourceInd in 1:length(sources)) {
      sourceStr <- paste(sources[sourceInd], size, sep = "-")
      sourceName <- sources[sourceInd]
      color <- colors[sourceInd]
      title <- ""
      if (sourceInd == 1)
        title <- paste("Time in seconds to complete", sizePr, "request")
      xlab <- ""
      if (sourceInd == length(sources))
        xlab <- paste("Last updated:", date())

      data <- subset(t, source %in% sourceStr)

      q1s_ <- c()
      medians_ <- c()
      q3s_ <- c()
      for (i in datesStr) {
        q1s_ <- c(q1s_, ifelse(i %in% data$date, data$q1[data$date == i],
            NA))
        medians_ <- c(medians_, ifelse(i %in% data$date,
            data$md[data$date == i], NA))
        q3s_ <- c(q3s_, ifelse(i %in% data$date, data$q3[data$date == i],
            NA))
      }
      xp <- c(1:length(q1s_), length(q3s_):1)
      yp <- c(q1s_/1e3, rev(q3s_/1e3))
      xp2 <- c()
      for (i in 1:length(xp)) {
        if (is.na(yp[i]))
          xp2 <- c(xp2, NA)
        else
          xp2 <- c(xp2, xp[i])
      }
      colmed <- color
      colquart <- paste(color, "66", sep="")

      plot(medians_/1e3, ylim=c(0, maxY), type="l", col=colmed, lwd=2,
          main=title, axes=FALSE, ylab="", xlab=xlab, cex.main=1.9)
      polygon(na.omit(xp2), na.omit(yp), col=colquart, lty=0)

      axis(1, at=monthticks - 0.5, labels=FALSE, lwd=0, lwd.ticks=1)
      axis(1, at=c(1, length(datesStr)), labels=FALSE, lwd=1, lwd.ticks=0)
      axis(1, at=monthat, lwd=0, labels=monthlabels)
      axis(2, las=1, lwd=0, lwd.ticks=1)
      axis(2, las=1, at=c(0, maxY), lwd.ticks=0, labels=FALSE)

      legend(title = paste("Measured times on", sourceName, "per day"),
          x=length(datesStr)/2, xjust=0.5, y=maxY, yjust=1, cex=1.5,
          c("Median", "1st to 3rd quartile"), fill=c(colmed, colquart),
          bty="n", ncol=2)
    }
    dev.off()
  }
}
