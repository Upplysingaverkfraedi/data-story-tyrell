
# install.packages("ggplot2")
# install.packages("dplyr")

# hér er con skilgreint, con tengir gögn frá postgreSQL í RStudio (í config.yml skrá)

library(dplyr)
kingdom_sizes <- data.frame(kingdom_id = integer(), size = integer())  # Búa til dataframe sem inniheldu gefinn gögn

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

#loada inn ggplot til að gera graf
library(ggplot2)
ggplot(kingdom_sizes, aes(x = kingdom_name, y = size, fill = kingdom_name)) + # gera graf út frá nýju breytu og size
  geom_bar(stat = "identity", color = "black") +
  labs(title = "Stærð konungsríkja í Westeros", x = "Konungsríki", y = "Stærð konunsríkja í ferkílómetrum") +
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

# 5,The North
# 8,The Vale
# 3,Gift
# 1,The Riverlands
# 9,The Westerlands
# 6,Dorne
# 11,The Reach
# 7,The Stormlands
# 2,Iron Islands
# 10,The Crownsland

