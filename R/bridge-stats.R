options(warn = -1)
suppressPackageStartupMessages(library("ggplot2"))

plot_bridges <- function(filename, title, limits, code) {
  c <- data.frame(date = bridge$date, users = bridge[[code]])
  ggplot(c, aes(x = as.Date(date, "%Y-%m-%d"), y = users)) +
    geom_line() + scale_x_date(name = "", limits = limits) +
    scale_y_continuous(name = "", limits = c(0, max(bridge[[code]],
    na.rm = TRUE))) +
    opts(title = title)
  ggsave(filename = paste("website/graphs/bridge-users/", filename,
    sep = ""), width = 8, height = 5, dpi = 72)
}

plot_alldata <- function(countries) {
  for (country in 1:length(countries$code)) {
    code <- countries[country, 1]
    people <- countries[country, 2]
    filename <- countries[country, 3]
    end <- Sys.Date()
    start <- as.Date(bridge$date[1])
    plot_bridges(paste(filename, "-bridges-all.png", sep = ""),
      paste(people, "Tor users via bridges (all data)\n"),
      c(start, end), code)
  }
}

plot_pastdays <- function(days, countries) {
  for (day in days) {
    for (country in 1:length(countries$code)) {
      code <- countries[country, 1]
      people <- countries[country, 2]
      filename <- countries[country, 3]
      end <- Sys.Date()
      start <- seq(from = end, length = 2, by = paste("-", day, " days",
        sep = ""))[2]
      plot_bridges(paste(filename, "-bridges-", day, "d.png", sep = ""),
        paste(people, "Tor users via bridges (past", day, "days)\n"),
        c(start, end), code)
    }
  }
}

plot_years <- function(years, countries) {
  for (year in years) {
    for (country in 1:length(countries$code)) {
      code <- countries[country, 1]
      people <- countries[country, 2]
      filename <- countries[country, 3]
      plot_bridges(paste(filename, "-bridges-", year, ".png", sep = ""),
        paste(people, " Tor users via bridges (", year, ")\n", sep = ""),
        as.Date(c(paste(year, "-01-01", sep = ""), paste(year, "-12-31",
        sep = ""))), code)
    }
  }
}

plot_quarters <- function(years, quarters, countries) {
  for (year in years) {
    for (quarter in quarters) {
      for (country in 1:length(countries$code)) {
        code <- countries[country, 1]
        people <- countries[country, 2]
        filename <- countries[country, 3]
        start <- as.Date(paste(year, "-", (quarter - 1) * 3 + 1, "-01",
          sep = ""))
        end <- seq(seq(start, length = 2, by = "3 months")[2], length = 2,
          by = "-1 day")[2]
        plot_bridges(paste(filename, "-bridges-", year, "-q", quarter,
          ".png", sep = ""), paste(people, " Tor users via bridges (Q",
          quarter, " ", year, ")\n", sep = ""), c(start, end), code)
      }
    }
  }
}

plot_months <- function(years, months, countries) {
  for (year in years) {
    for (month in months) {
      for (country in 1:length(countries$code)) {
        code <- countries[country, 1]
        people <- countries[country, 2]
        filename <- countries[country, 3]
        start <- as.Date(paste(year, "-", month, "-01", sep = ""))
        end <- seq(seq(start, length = 2, by = "1 month")[2], length = 2,
          by = "-1 day")[2]
        plot_bridges(paste(filename, "-bridges-", year, "-",
          format(start, "%m"), ".png", sep = ""), paste(people,
          " Tor users via bridges (", format(start, "%B"), " ", year,
          ")\n", sep = ""), c(start, end), code)
      }
    }
  }
}

plot_current <- function(countries) {
  plot_alldata(countries)
  plot_pastdays(c(30, 90, 180), countries)
  today <- as.POSIXct(Sys.Date(), tz = "GMT")
  one_week_ago <- seq(from = today, length = 2, by = "-7 days")[2]
  year_today <- format(today, "%Y")
  year_one_week_ago <- format(one_week_ago, "%Y")
  quarter_today <- 1 + floor((as.numeric(format(today, "%m")) - 1) / 3)
  quarter_one_week_ago <- 1 + floor((as.numeric(format(one_week_ago,
    "%m")) - 1) / 3)
  month_today <- as.numeric(format(today, "%m"))
  month_one_week_ago <- as.numeric(format(one_week_ago, "%m"))
  plot_years(union(year_today, year_one_week_ago), countries)
  if (year_today == year_one_week_ago) {
    plot_quarters(year_today, union(quarter_today, quarter_one_week_ago),
      countries)
  } else {
    plot_quarters(year_today, quarter_today, countries)
    plot_quarters(year_one_week_ago, quarter_one_week_ago, countries)
  }
  if (year_today == year_one_week_ago) {
    plot_months(year_today, union(month_today, month_one_week_ago),
      countries)
  } else {
    plot_months(year_today, month_today, countries)
    plot_months(year_one_week_ago, month_one_week_ago, countries)
  }
}

countries <- data.frame(code = c("bh", "cn", "cu", "et", "ir", "mm", "sa",
  "sy", "tn", "tm", "uz", "vn", "ye"), people = c("Bahraini", "Chinese",
  "Cuban", "Ethiopian", "Iranian", "Burmese", "Saudi", "Syrian",
  "Tunisian", "Turkmen", "Uzbek", "Vietnamese", "Yemeni"), filename =
  c("bahrain", "china", "cuba", "ethiopia", "iran", "burma", "saudi",
  "syria", "tunisia", "turkmenistan", "uzbekistan", "vietnam", "yemen"),
  stringsAsFactors = FALSE)

if (file.exists("stats/bridge-stats")) {
  bridge <- read.csv("stats/bridge-stats", header = TRUE,
    stringsAsFactors = FALSE)
  bridge <- bridge[1:length(bridge$date)-1,]
  write.csv(bridge, "website/csv/bridge-users.csv", quote = FALSE,
    row.names = FALSE)
  plot_current(countries)
}

