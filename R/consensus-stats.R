options(warn = -1)
suppressPackageStartupMessages(library("ggplot2"))

if (file.exists("stats/consensus-stats-raw")) {
  relaysDay <- read.csv("stats/consensus-stats-raw",
    stringsAsFactors = FALSE)
  to <- Sys.time()
  from <- seq(from = to, length = 2, by = "-3 days")[2]
  relaysDay <- subset(relaysDay, as.POSIXct(datetime, tz = "GMT") >= from)
  if (length(relaysDay$datetime) > 0) {
    m <- melt(relaysDay[,c(1, 5, 2)], id = "datetime")
    ggplot(m, aes(x = as.POSIXct(datetime, tz = "GMT"), y = value,
      colour = variable)) + geom_point() +
      scale_x_datetime(name = "", limits = c(from, to)) +
      scale_y_continuous(name = "") +
      scale_colour_hue("", breaks = c("running", "exit"),
      labels = c("All relays", "Exit relays")) +
      opts(title = "Number of exit relays (past 72 hours)\n")
    ggsave(filename = "website/graphs/exit/exit-72h.png",
      width = 8, height = 5, dpi = 72)
  }
}

if (file.exists("stats/consensus-stats")) {
  consensuses <- read.csv("stats/consensus-stats", header = TRUE,
      stringsAsFactors = FALSE);
  consensuses <- consensuses[1:length(consensuses$date)-1,]
  write.csv(data.frame(date = consensuses$date,
    relays = consensuses$running, bridges = consensuses$brunning),
    "website/csv/networksize.csv", quote = FALSE, row.names = FALSE)
  write.csv(data.frame(date = consensuses$date,
    all = consensuses$running, exit = consensuses$exit),
    "website/csv/exit.csv", quote = FALSE, row.names = FALSE)
}

plot_consensus <- function(directory, filename, title, limits, rows, breaks,
    labels) {
  c <- melt(consensuses[rows], id = "date")
  ggplot(c, aes(x = as.Date(date, "%Y-%m-%d"), y = value,
    colour = variable)) + geom_line() + #stat_smooth() +
    scale_x_date(name = "", limits = limits) +
    #paste("\nhttp://metrics.torproject.org/ -- last updated:",
    #  date(), "UTC"),
    scale_y_continuous(name = "",
    limits = c(0, max(c$value, na.rm = TRUE))) +
    scale_colour_hue("", breaks = breaks, labels = labels) +
    opts(title = title)
  ggsave(filename = paste(directory, filename, sep = ""),
    width = 8, height = 5, dpi = 72)
}

plot_pastdays <- function(directory, filenamePart, titlePart, days, rows,
    breaks, labels) {
  for (day in days) {
    end <- Sys.Date()
    start <- seq(from = end, length = 2, by = paste("-", day, " days",
      sep = ""))[2]
    plot_consensus(directory, paste(filenamePart, "-", day, "d.png",
      sep = ""), paste(titlePart, "(past", day, "days)\n"), c(start, end),
      rows, breaks, labels)
  }
}

plot_years <- function(directory, filenamePart, titlePart, years, rows,
    breaks, labels) {
  for (year in years) {
    plot_consensus(directory, paste(filenamePart, "-", year, ".png",
      sep = ""), paste(titlePart, " (", year, ")\n", sep = ""),
      as.Date(c(paste(year, "-01-01", sep = ""),
      paste(year, "-12-31", sep = ""))), rows, breaks, labels)
  }
}

plot_quarters <- function(directory, filenamePart, titlePart, years,
    quarters, rows, breaks, labels) {
  for (year in years) {
    for (quarter in quarters) {
      start <- as.Date(paste(year, "-", (quarter - 1) * 3 + 1, "-01",
        sep = ""))
      end <- seq(seq(start, length = 2, by = "3 months")[2], length = 2,
        by = "-1 day")[2]
      plot_consensus(directory, paste(filenamePart, "-", year, "-q",
        quarter, ".png",
        sep = ""), paste(titlePart, " (Q", quarter, " ", year, ")\n",
        sep = ""), c(start, end), rows, breaks, labels)
    }
  }
}

plot_months <- function(directory, filenamePart, titlePart, years, months,
    rows, breaks, labels) {
  for (year in years) {
    for (month in months) {
      start <- as.Date(paste(year, "-", month, "-01", sep = ""))
      end <- seq(seq(start, length = 2, by = "1 month")[2], length = 2,
        by = "-1 day")[2]
      plot_consensus(directory, paste(filenamePart, "-", year, "-",
        format(start, "%m"), ".png", sep = ""), paste(titlePart,
        " (", format(start, "%B"), " ", year, ")\n", sep = ""),
        c(start, end), rows, breaks, labels)
    }
  }
}

plot_all <- function(directory, filenamePart, titlePart, rows, breaks,
    labels) {
  plot_consensus(directory, paste(filenamePart, "-all.png", sep = ""),
    paste(titlePart, " (all data)\n", sep = ""),
    as.Date(c(min(consensuses$date), max(consensuses$date))), rows,
    breaks, labels)
}

plot_current <- function(directory, filenamePart, titlePart, rows, breaks,
    labels) {
  plot_pastdays(directory, filenamePart, titlePart, c(30, 90, 180), rows,
    breaks, labels)
  today <- as.POSIXct(Sys.Date(), tz = "GMT")
  one_week_ago <- seq(from = today, length = 2, by = "-7 days")[2]
  year_today <- format(today, "%Y")
  year_one_week_ago <- format(one_week_ago, "%Y")
  quarter_today <- 1 + floor((as.numeric(format(today, "%m")) - 1) / 3)
  quarter_one_week_ago <- 1 + floor((as.numeric(format(one_week_ago,
    "%m")) - 1) / 3)
  month_today <- as.numeric(format(today, "%m"))
  month_one_week_ago <- as.numeric(format(one_week_ago, "%m"))
  plot_years(directory, filenamePart, titlePart, union(year_today,
    year_one_week_ago), rows, breaks, labels)
  if (year_today == year_one_week_ago) {
    plot_quarters(directory, filenamePart, titlePart, year_today,
      union(quarter_today, quarter_one_week_ago), rows, breaks, labels)
  } else {
    plot_quarters(directory, filenamePart, titlePart, year_today,
      quarter_today, rows, breaks, labels)
    plot_quarters(directory, filenamePart, titlePart, year_one_week_ago,
      quarter_one_week_ago, rows, breaks, labels)
  }
  if (year_today == year_one_week_ago) {
    plot_months(directory, filenamePart, titlePart, year_today,
      union(month_today, month_one_week_ago), rows, breaks, labels)
  } else {
    plot_months(directory, filenamePart, titlePart, year_today, month_today,
      rows, breaks, labels)
    plot_months(directory, filenamePart, titlePart, year_one_week_ago,
      month_one_week_ago, rows, breaks, labels)
  }
  plot_all(directory, filenamePart, titlePart, rows, breaks, labels)
}

if (file.exists("stats/consensus-stats")) {
  plot_current("website/graphs/networksize/", "networksize",
    "Number of relays and bridges", c(1, 5, 7),
    c("running", "brunning"), c("Relays", "Bridges"))
  plot_current("website/graphs/exit/", "exit", "Number of exit relays",
    c(1, 5, 2), c("running", "exit"), c("All relays", "Exit relays"))
}

