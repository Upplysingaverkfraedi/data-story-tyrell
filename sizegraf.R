 # Hlaða inn nauðsynlegum pökkum
library(DBI)
library(RPostgres)
library(ggplot2)
library(config)

# Lesa upplýsingar úr config.yml
db_config <- config::get("db")

# Tengjast PostgreSQL gagnagrunninum
con <- dbConnect(
  RPostgres::Postgres(),
  dbname = db_config$name,
  host = db_config$host,
  port = db_config$port,
  user = db_config$user,
  password = db_config$password,
  sslmode = db_config$sslmode
)

# Búa til dataframe fyrir konungsríkin
kingdom_sizes <- data.frame(kingdom_id = integer(), size = integer())  # Búa til dataframe sem inniheldur gefin gögn

# Lykkja sem leitar í gegnum kingdom_sizes
for (id in 1:11) {  
  if (id != 4) {  # ekkert konungsríki númer 4
    size <- dbGetQuery(con, paste0("SELECT get_kingdom_size(", id, ") AS size"))
    kingdom_sizes <- rbind(kingdom_sizes, data.frame(kingdom_id = id, size = size$size))
  }
}

# Búa til nýja breytu fyrir nöfn konungsríkja
kingdom_names <- c(
  "1" = "The Riverlands",
  "2" = "Iron Islands",
  "3" = "Gift",
  "5" = "The North",
  "6" = "Dorne",
  "7" = "The Stormlands",
  "8" = "The Vale",
  "9" = "The Westerlands",
  "10" = "The Crownsland",
  "11" = "The Reach"
)

kingdom_sizes$kingdom_name <- kingdom_names[as.character(kingdom_sizes$kingdom_id)] # Setja nýja breytu í dataframe

# Búa til graf
ggplot(kingdom_sizes, aes(x = kingdom_name, y = size, fill = kingdom_name)) + # gera graf út frá nýju breytu og size
  geom_bar(stat = "identity", color = "black") +
  labs(title = "Stærð konungsríkja í Westeros", x = "Konungsríki", y = "Stærð konungsríkja í ferkílómetrum") +
  scale_y_continuous(labels = scales::comma) +
  scale_fill_manual(values = c(
    "The Riverlands" = "lightgreen", 
    "Iron Islands" = "hotpink", 
    "Gift" = "green", 
    "The North" = "darkorange", 
    "Dorne" = "lightblue", 
    "The Stormlands" = "purple", 
    "The Vale" = "orange", 
    "The Westerlands" = "yellow", 
    "The Crownsland" = "pink", 
    "The Reach" = "steelblue")) + 
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  guides(fill = FALSE) 

# Loka tengingunni við gagnagrunninn
dbDisconnect(con)