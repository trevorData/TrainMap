setwd("~/Projects/CTA")

library(stringr)
library(ggmap)
library(dplyr)

# Import monthly ridership data
cta.riders.raw <- read.csv('CTA_ridership.csv')

# Import dictionary of L stops
cta.stops.raw  <- read.csv('CTA_stops.csv')

# Format data and subset the dataframes to only the necessay columns
cta.riders.raw$month_beginning <- cta.riders.raw$month_beginning %>% as.Date(format = '%m/%d/%Y')
cta.riders.raw$station_id <- cta.riders.raw$station_id %>% as.numeric
cta.riders.raw$month <- cta.riders.raw$month_beginning %>% format('%m' )%>% as.numeric
cta.riders.raw$year  <- cta.riders.raw$month_beginning %>% format('%Y') %>% as.numeric

cta.riders <- cta.riders.raw %>% select(c('station_id', 'stationame', 'month_beginning', 'month', 'year', 'monthtotal'))

cta.stops.raw$Location <- cta.stops.raw$Location %>% str_replace_all('[()]', '')
cta.stops.raw$lat <- cta.stops.raw$Location %>% str_split(', ') %>% sapply(`[`, 1) %>% as.numeric
cta.stops.raw$lon <- cta.stops.raw$Location %>% str_split(', ') %>% sapply(`[`, 2) %>% as.numeric

cta.stops.raw$RED  <- cta.stops.raw$RED  %>% as.logical
cta.stops.raw$BLUE <- cta.stops.raw$BLUE %>% as.logical
cta.stops.raw$G    <- cta.stops.raw$G    %>% as.logical
cta.stops.raw$BRN  <- cta.stops.raw$BRN  %>% as.logical
cta.stops.raw$P    <- cta.stops.raw$P    %>% as.logical
cta.stops.raw$Pexp <- cta.stops.raw$Pexp %>% as.logical
cta.stops.raw$Y    <- cta.stops.raw$Y    %>% as.logical
cta.stops.raw$Pnk  <- cta.stops.raw$Pnk  %>% as.logical
cta.stops.raw$O    <- cta.stops.raw$O    %>% as.logical

cta.stops.raw$MAP_ID <- cta.stops.raw$MAP_ID %>% as.numeric

cta.stops  <- cta.stops.raw %>% select('MAP_ID', 'STATION_NAME', 'lat', 'lon', 'RED', 'BLUE', 'G', 'BRN', 'Pexp', 'Y', 'Pnk', 'O') 

# Aggregate stop data so each train stop has one row
stops.agg <- cta.stops[5:12] %>% aggregate(by=list(cta.stops$MAP_ID, cta.stops$STATION_NAME, cta.stops$lat, cta.stops$lon), FUN=max)

colnames(stops.agg)[colnames(stops.agg) == 'Group.1'] <- 'station_id'
colnames(stops.agg)[colnames(stops.agg) == 'Group.2'] <- 'station_name'
colnames(stops.agg)[colnames(stops.agg) == 'Group.3'] <- 'lat'
colnames(stops.agg)[colnames(stops.agg) == 'Group.4'] <- 'lon'

# Decide which color will be assigned to each train stop
stops.agg$lines <- stops.agg[5:12] %>% rowSums

stops.agg$main <- 'white'

stops.agg[stops.agg$RED & stops.agg$lines == 1, ]$main  <- 'red'
stops.agg[stops.agg$Pnk & stops.agg$lines == 1, ]$main  <- 'pink'
stops.agg[stops.agg$BLUE & stops.agg$lines == 1, ]$main <- 'blue'
stops.agg[stops.agg$G & stops.agg$lines == 1, ]$main    <- 'green'
stops.agg[stops.agg$Y & stops.agg$lines == 1, ]$main    <- 'yellow'
stops.agg[stops.agg$BRN & stops.agg$lines == 1, ]$main  <- 'brown'
stops.agg[stops.agg$Pexp & stops.agg$lines == 1, ]$main <- 'purple'
stops.agg[stops.agg$O & stops.agg$lines == 1, ]$main    <- 'orange'

stops.agg[stops.agg$RED & stops.agg$lines == 2, ]$main  <- 'red'
stops.agg[stops.agg$BRN & stops.agg$lines == 2, ]$main  <- 'brown'
stops.agg[stops.agg$Pnk & stops.agg$lines == 2, ]$main  <- 'pink'
stops.agg[stops.agg$O & stops.agg$lines == 2, ]$main    <- 'orange'

stops.agg[stops.agg$Y & stops.agg$lines == 3, ]$main    <- 'yellow'
stops.agg[stops.agg$BRN & stops.agg$lines == 3, ]$main  <- 'brown'

# Merge data
df <- merge(x=cta.riders, y=stops.agg, 
            by='station_id', 
            all.x=TRUE
            )

# Remove lines for extinct stations
df <- df[!(df$main %>% is.na),]

# Set scale that will be used to plot point sizes
df$total.size <- df$monthtotal/23000

# Create column for ridership with seasonality removed
month.avgs <- df$monthtotal %>% aggregate(by=list(Category=df$month), FUN=mean)
colnames(month.avgs)[1] <- "month"
colnames(month.avgs)[2] <- "month.avg"

df <- df %>% merge(month.avgs)
df$prop.size <- df$monthtotal/df$month.avg
df$prop.size <- df$prop.size * 4.5

# Load Map Background from Google
register_google(Sys.getenv('google_maps_api'))

mapImage <- get_map(location = c(lon = -87.68, lat = 41.9), 
                    color = "bw",
                    maptype = "toner-background",
                    source = 'stamen',
                    zoom = 10)

# Set vizualization styles
cols <- c("brown"  = "#62361b", 
          "blue"   = "#00a1de", 
          "green"  = "#009b3a",
          "orange" = "#f9461c", 
          'white'  = 'grey', 
          'red'    = '#c60c30', 
          'purple' = '#522398',
          'yellow' = '#f9e300',
          'pink'   = '#e27ea6'
          )

ann_x <- -87.41
ann_y <- 42.09
ann_size <- 15

coord_lims <- coord_map(xlim = c(-87.95, -87.4),
                        ylim = c(41.68, 42.1))

themes <- theme(axis.title = element_blank(), 
                axis.text = element_blank(),
                legend.position = 'none'
                ) 

ggmap(mapImage) +
  geom_point(data = df[df$month == 2 & df$year == 2003 & df$main != 'white',],
             aes(x=lon, y=lat, size = total.size, color = main)) +
  scale_color_manual(values = cols) +
  scale_size_identity() +
  coord_lims

# Plot Maps
for (year in 2001:2018){
  for (month in 1:12) {
    
    ggmap(mapImage) +
      geom_point(data = df[df$month == month & df$year == year & df$main != 'white',],
                 aes(x=lon, y=lat, size = total.size, color = main)) +
      scale_color_manual(values = cols) +
      scale_size_identity() +
      coord_lims +
      themes + 
      annotate('text', x= ann_x, y = ann_y, size = ann_size, color = 'white', label = toString(year), fontface = 2, hjust = 1, vjust = 1)
    
    paste('CTA_plot', year, month, '.png', sep = '_') %>% ggsave(device = 'png', height = 7, width = 7, dpi = 'screen')
    
  }
}

# Plot Maps with proportional sizes
for (year in 2001:2018){
  for (month in 1:12) {
    
    ggmap(mapImage) +
      geom_point(data = df[df$month == month & df$year == year & df$main == 'yellow',],
                 aes(x=lon, y=lat, size = prop.size, color = main)) +
      geom_point(data = df[df$month == month & df$year == year & df$main == 'pink',],
                 aes(x=lon, y=lat, size = prop.size, color = main)) +
      geom_point(data = df[df$month == month & df$year == year & df$main == 'orange',],
                 aes(x=lon, y=lat, size = prop.size, color = main)) +
      geom_point(data = df[df$month == month & df$year == year & df$main == 'green',],
                 aes(x=lon, y=lat, size = prop.size, color = main)) +
      geom_point(data = df[df$month == month & df$year == year & df$main == 'purple',],
                 aes(x=lon, y=lat, size = prop.size, color = main)) +
      geom_point(data = df[df$month == month & df$year == year & df$main == 'brown',],
                 aes(x=lon, y=lat, size = prop.size, color = main)) +
      geom_point(data = df[df$month == month & df$year == year & df$main == 'blue',],
                 aes(x=lon, y=lat, size = prop.size, color = main)) +
      geom_point(data = df[df$month == month & df$year == year & df$main == 'red',],
                 aes(x=lon, y=lat, size = prop.size, color = main)) +
      scale_color_manual(values = cols) +
      scale_size_identity() +
      coord_lims +
      themes + 
      annotate('text', x= ann_x, y = ann_y, size = ann_size, color = 'white', label = toString(year), fontface = 2, hjust = 1, vjust = 1)
    
    paste('CTA_prop_plot', year, month, '.png', sep = '_') %>% ggsave(device = 'png', height = 7, width = 7, dpi = 'screen')
    
  }
}
