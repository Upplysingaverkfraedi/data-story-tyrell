# Hlaða inn nauðsynlegum pökkum
library(tidyverse)   # Fyrir gagnavinnslu
library(sf)          # Fyrir landfræðileg gögn (Simple Features)
library(leaflet)     # Fyrir gagnvirk kort
library(DBI)         # Fyrir gagnagrunnstengingar
library(RPostgres)   # Fyrir PostgreSQL tengingar
library(config)      # Fyrir að lesa úr config.yml

# Lesa upplýsingar úr config.yml skránni
db_config <- config::get("db")

# Tengjast PostgreSQL gagnagrunninum með upplýsingunum úr config.yml
con <- dbConnect(RPostgres::Postgres(),
                 dbname = db_config$name,
                 host = db_config$host,
                 port = db_config$port,
                 user = db_config$user,
                 password = db_config$password)

# Sækja gögn um staðsetningar í Westeros
query <- "SELECT gid, name, ST_AsText(geog) as geom_wkt FROM atlas.locations"
location_data <- RPostgres::dbGetQuery(con, query) %>%
  st_as_sf(wkt = "geom_wkt", crs = 4326)

# Sækja gögn um landamæri ríkja í Westeros
query <- "SELECT gid, name, ST_AsText(geog) as geom_wkt FROM atlas.kingdoms"
kingdom_data <- RPostgres::dbGetQuery(con, query) %>%
  st_as_sf(wkt = "geom_wkt", crs = 4326) %>%
  mutate(color = colorRampPalette(colors = rainbow(n()))(n()))

# Búa til Leaflet kort með gagnvirkum eiginleikum
leaflet() %>%
  # Við byrjum á því að hlaða inn bakgrunnsmynd af heiminum
  addTiles(urlTemplate = 'https://cartocdn-gusc.global.ssl.fastly.net/ramirocartodb/api/v1/map/named/tpl_756aec63_3adb_48b6_9d14_331c6cbc47cf/all/{z}/{x}/{y}.png') %>%
  # Bætum við punktum fyrir staðsetningar í Westeros, merkjum með nafni (popup)
  addCircleMarkers(data = location_data,
                   group = "Locations",
                   lng = ~st_coordinates(st_geometry(location_data))[, 1],
                   lat = ~st_coordinates(st_geometry(location_data))[, 2],
                   popup = ~name,
                   radius = 5,
                   color = "blue",
                   fillOpacity = 0.7,
                   clusterOptions = markerClusterOptions()) %>%
  # Teiknum konungsríkin með mismunandi litum
  addPolygons(data = kingdom_data,
              group = "Kingdoms",
              fillColor = ~color,
              weight = 2,
              opacity = 1,
              color = "black",
              fillOpacity = 0.5,
              popup = ~name) %>%
  # Bætum við möguleika að slökkva/kveikja á hópum
  addLayersControl(overlayGroups = c("Locations", "Kingdoms"),
                   options = layersControlOptions(collapsed = FALSE))

# Loka tengingunni við gagnagrunninn þegar unnið er með hana
dbDisconnect(con)

