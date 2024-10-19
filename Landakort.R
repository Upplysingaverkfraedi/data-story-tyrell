# Nauðsynlegir pakkar
library(tidyverse)
library(sf)
library(leaflet)
library(DBI)
library(RPostgres)
library(config)
library(tidyr)

# Lesa upplýsingar úr config.yml skránni
db_config <- config::get("db")

# Tengjast PostgreSQL gagnagrunninum
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

# Sækja gögn um landamæri ríkja í Westeros (GoT löndin)
query <- "SELECT gid, name, ST_AsText(geog) as geom_wkt FROM atlas.kingdoms"
kingdom_data <- RPostgres::dbGetQuery(con, query) %>%
  st_as_sf(wkt = "geom_wkt", crs = 4326) %>%
  
  # Breyta hnitakerfi í metrakerfi til að reikna flatarmál
  st_transform(3857) %>%
  mutate(got_area_km2 = as.numeric(st_area(.) / 1e6))  # Reikna flatarmál í ferkílómetrum (m² í km²)

# Breyta aftur í longlat (EPSG:4326) fyrir Leaflet
kingdom_data <- kingdom_data %>%
  st_transform(4326) %>%
  mutate(color = colorRampPalette(colors = rainbow(n()))(n()))  # Búa til litadálk

# Flatarmál evrópuríkja
european_countries <- data.frame(
  country = c("Indland", "Suður Afríka", "Egyptaland", "Úkraína", "Frakkland", "Spánn", "Svíþjóð", "Þýskaland", 
              "Noregur", "Finnland", "Pólland", "Ítalía", "Bretland", "Írland", 
              "Ísland", "Sviss", "Belgía", "Portúgal", "Grikkland", "Tyrkland", 
              "Austurríki", "Holland", "Danmörk", "Tékkland", "Ungverjaland", 
              "Rúmenía", "Serbía", "Búlgaría", "Slóvakía", "Króatía", "Bosnía og Hersegóvína",
              "Albanía", "Litáen", "Lettland", "Eistland", "Slóvenía", "Makedónía", 
              "Montenegro", "Moldavía"),
  europe_area_km2 = as.numeric(c(3287263, 1219090, 1001450, 603500, 551695, 505992, 450295, 357386, 323802, 
                                 338424, 312679, 301340, 243610, 70273, 103000, 41290, 30528, 
                                 92212, 131957, 783562, 83871, 41543, 42933, 78865, 93030, 
                                 238397, 77474, 110994, 49035, 56594, 51197, 28748, 65300, 
                                 64589, 45227, 20273, 25713, 13812, 33843))
)

# Bæta við dálki með náttúrlegum logarithma flatarmála
european_countries <- european_countries %>%
  mutate(log_europe_area_km2 = log(europe_area_km2))

# Endurbætt fall til að finna land með svipað logarithma flatarmál
find_similar_country_log <- function(got_area_km2_single) {
  # Nota náttúrlegan logarithma flatarmálsins
  got_area_km2_log <- log(got_area_km2_single)
  
  # Finna land með minnsta mismun á logarithma flatarmálsins
  similar_country <- european_countries %>%
    mutate(diff = abs(got_area_km2_log - log_europe_area_km2)) %>%
    filter(diff == min(diff)) %>%
    select(country, europe_area_km2)
  
  return(similar_country)
}

# Bæta sambærilegu landi við 'kingdom_data' með logarithma
kingdom_comparison_log <- kingdom_data %>%
  rowwise() %>%
  mutate(similar_country = list(find_similar_country_log(got_area_km2))) %>%
  unnest_wider(similar_country) %>%
  ungroup() %>%
  st_as_sf()

# Búa til Leaflet kort með gagnvirkum eiginleikum og sýna flatarmál í popup
leaflet() %>%
  addTiles(urlTemplate = 'https://cartocdn-gusc.global.ssl.fastly.net/ramirocartodb/api/v1/map/named/tpl_756aec63_3adb_48b6_9d14_331c6cbc47cf/all/{z}/{x}/{y}.png') %>%
  
  # Bætum við punktum fyrir staðsetningar í Westeros, merkjum með nafni (popup)
  addCircleMarkers(data = location_data,
                   group = "Staðsetningar",
                   lng = ~st_coordinates(st_geometry(location_data))[, 1],
                   lat = ~st_coordinates(st_geometry(location_data))[, 2],
                   popup = ~name,
                   radius = 5,
                   color = "blue",
                   fillOpacity = 0.7,
                   clusterOptions = markerClusterOptions()) %>%
  
  # Teiknum konungsríkin með popup sem sýnir flatarmál og sambærilegt evrópuland
  addPolygons(data = kingdom_comparison_log,
              group = "Konungsríki",
              fillColor = ~color,  # Nota color dálkinn
              weight = 2,
              opacity = 1,
              color = "black",
              fillOpacity = 0.5,
              # Popup með nafni, flatarmáli og sambærilegu landi
              popup = ~{
                paste(name, "<br> Flatarmál: ", 
                      format(round(as.numeric(got_area_km2), 0), big.mark = ",", decimal.mark = ".", nsmall = 0),
                      " km²", "<br> Sambærilegt land: ", country, " (", 
                      format(round(as.numeric(europe_area_km2), 0), big.mark = ",", decimal.mark = ".", nsmall = 0), " km²)")
              }) %>%
  
  # Bætum við möguleika að slökkva/kveikja á hópum
  addLayersControl(overlayGroups = c("Staðsetningar", "Konungsríki"),
                   options = layersControlOptions(collapsed = FALSE))

# Loka tengingunni við gagnagrunninn
dbDisconnect(con)
