# Hlaða inn nauðsynlegum pökkum
library(tidyverse)   # Fyrir gagnavinnslu
library(sf)          # Fyrir landfræðileg gögn (Simple Features)
library(leaflet)     # Fyrir gagnvirk kort
library(DBI)         # Fyrir gagnagrunnstengingar
library(RPostgres)   # Fyrir PostgreSQL tengingar
library(config)      # Fyrir að lesa úr config.yml

# Lesa upplýsingar úr config.yml
db_config <- config::get("db")

# Tengjast PostgreSQL gagnagrunninum
conn <- dbConnect(
  RPostgres::Postgres(),
  dbname = db_config$name,
  host = db_config$host,
  port = db_config$port,
  user = db_config$user,
  password = db_config$password
)

# Sækja gögn um staðsetningar í Westeros
query <- "SELECT gid, name, ST_AsText(geog) as geom_wkt FROM atlas.locations"
location_data <- RPostgres::dbGetQuery(conn, query) %>%
  st_as_sf(wkt = "geom_wkt", crs = 4326)

# Sækja gögn um landamæri ríkja í Westeros
query <- "SELECT gid, name, ST_AsText(geog) as geom_wkt FROM atlas.kingdoms"
kingdom_data <- RPostgres::dbGetQuery(conn, query) %>%
  st_as_sf(wkt = "geom_wkt", crs = 4326)

# Nota spatial join til að tengja punkta við polygons
joined_data <- st_join(location_data, kingdom_data, join = st_within)

# Telja fjölda punkta í hverju konungsríki
points_per_kingdom <- joined_data %>%
  group_by(name.y) %>%        # 'name.y' er nafnið á konungsríkinu
  summarize(count = n(), .groups = 'drop')  # Telja hve margar staðsetningar eru í hverju ríki

# Bæta við "Utan konungssvæðis" ef engir punktar eru í ríki
kingdom_names <- kingdom_data$name

points_per_kingdom <- points_per_kingdom %>%
  complete(name.y = kingdom_names, fill = list(count = 0)) %>%
  mutate(name.y = ifelse(is.na(name.y), "Utan konungssvæðis", name.y))

# Setja upp súluritið
ggplot(points_per_kingdom, aes(x = reorder(name.y, count), y = count, fill = name.y)) +
  geom_bar(stat = "identity", color = "black", alpha = 0.7) +  # Svartur jaðar
  geom_label(aes(label = count), vjust = 0.5, hjust = 0.5, size = 5, fontface = "plain", 
             label.size = 0, fill = NA, color = "black") +  # Bæta tölunum inn á súlurnar, ófeitletrað
  labs(title = "Staðsetningar í hverju ríki",
       x = "Konungsríki",
       y = "Fjöldi staðsetninga") +
  scale_fill_manual(values = c(  # Handvirkt skilgreina liti fyrir hvert konungsríki
    "The Riverlands" = "lightgreen",
    "Iron Islands" = "hotpink",
    "Gift" = "green",
    "The North" = "darkorange",
    "Dorne" = "lightblue",
    "The Stormlands" = "purple",
    "The Vale" = "orange",
    "The Westerlands" = "yellow",
    "The Crownsland" = "pink",
    "The Reach" = "steelblue",
    "Utan konungssvæðis" = "gray"  # Litur fyrir Utan konungssvæðis
  )) +
  theme_minimal(base_size = 15) +  # Breyta grunnstærð skrifa
  coord_flip() +  # Snúa myndinni
  theme(panel.grid.major.y = element_blank(),  # Fjarlægja láréttar línur
        panel.grid.minor.y = element_blank(),
        panel.border = element_blank(),  # Fjarlægja jaðarlínur
        legend.position = "none")  # Fela legend

# Loka tengingunni við gagnagrunninn
dbDisconnect(conn)