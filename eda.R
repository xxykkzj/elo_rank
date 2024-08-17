
# Load the dataset
files <- str_glue("tennis_atp/atp_matches_{2010:2019}.csv")

  # Read each file and combine them into one data frame
matches_df <- map_dfr(files, ~read_csv(.x, show_col_types = FALSE))

surface_summary <- matches_df %>%
  group_by(surface) %>%
  summarise(
    Matches = n(),
    Unique_Players = n_distinct(c(winner_id, loser_id)),
    Avg_Serve_Points_Played = mean(w_svpt + l_svpt, na.rm = TRUE),
    Fraction_Serve_Points_Won = mean((w_1stWon + l_1stWon) / (w_svpt + l_svpt), na.rm = TRUE)
  )

# Summarize by tournament level
tournament_summary <- matches_df %>%
  group_by(tourney_level) %>%
  summarise(
    Matches = n(),
    Unique_Players = n_distinct(c(winner_id, loser_id)),
    Avg_Serve_Points_Played = mean(w_svpt + l_svpt, na.rm = TRUE),
    Fraction_Serve_Points_Won = mean((w_1stWon + l_1stWon) / (w_svpt + l_svpt), na.rm = TRUE)
  )

# Output summary statistics for surface
summary(surface_summary)

# Output summary statistics for tournament level
summary(tournament_summary)

p1_surface <- ggplot(surface_summary, aes(x = surface, y = Matches)) +
  geom_bar(stat = "identity", fill = "white", color = "black") +
  theme_minimal() +
  labs(title = "Matches by Surface", x = "Surface", y = "Number of Matches") +
  coord_cartesian(ylim = c(0, 18000))  # Adjust ylim to slightly above the max value (Max: 16907)

ggsave("surface_matches.png", plot = p1_surface)


# Plot 2: Unique Players by Surface
p2_surface <- ggplot(surface_summary, aes(x = surface, y = Unique_Players)) +
  geom_bar(stat = "identity", fill = "gray", color = "black") +
  theme_minimal() +
  labs(title = "Unique Players by Surface", x = "Surface", y = "Number of Unique Players") +
  coord_cartesian(ylim = c(0, 1100))  # Adjust ylim to slightly above the max value (Max: 1060)

ggsave("surface_unique_players.png", plot = p2_surface)


# Plot 3: Avg Serve Points Played by Surface
p3_surface <- ggplot(surface_summary, aes(x = surface, y = Avg_Serve_Points_Played)) +
  geom_bar(stat = "identity", fill = "darkgray", color = "black") +
  theme_minimal() +
  labs(title = "Avg Serve Points Played by Surface", x = "Surface", y = "Avg Serve Points Played") +
  coord_cartesian(ylim = c(140, 200))  # Adjust ylim based on the range (Min: 156.2, Max: 194.5)

ggsave("surface_avg_serve_points_played.png", plot = p3_surface)


# Plot 4: Fraction of Serve Points Won by Surface
p4_surface <- ggplot(surface_summary, aes(x = surface, y = Fraction_Serve_Points_Won)) +
  geom_bar(stat = "identity", fill = "black", color = "black") +
  theme_minimal() +
  labs(title = "Fraction of Serve Points Won by Surface", x = "Surface", y = "Fraction of Serve Points Won") +
  coord_cartesian(ylim = c(0.39, 0.45))  # Adjust ylim based on the range (Min: 0.3928, Max: 0.4294)

ggsave("surface_fraction_serve_points_won.png", plot = p4_surface)


# Repeat similar steps for the tournament level plots

# Plot 5: Matches by Tournament Level
p5_tournament <- ggplot(tournament_summary, aes(x = tourney_level, y = Matches)) +
  geom_bar(stat = "identity", fill = "white", color = "black") +
  theme_minimal() +
  labs(title = "Matches by Tournament Level", x = "Tournament Level", y = "Number of Matches") +
  coord_cartesian(ylim = c(0, 16000))  # Adjust ylim to slightly above the max value (Max: 15668)

ggsave("tourney_matches.png", plot = p5_tournament)


# Plot 6: Unique Players by Tournament Level
p6_tournament <- ggplot(tournament_summary, aes(x = tourney_level, y = Unique_Players)) +
  geom_bar(stat = "identity", fill = "gray", color = "black") +
  theme_minimal() +
  labs(title = "Unique Players by Tournament Level", x = "Tournament Level", y = "Number of Unique Players") +
  coord_cartesian(ylim = c(0, 950))  # Adjust ylim to slightly above the max value (Max: 901)

ggsave("tourney_unique_players.png", plot = p6_tournament)


# Plot 7: Avg Serve Points Played by Tournament Level
p7_tournament <- ggplot(tournament_summary, aes(x = tourney_level, y = Avg_Serve_Points_Played)) +
  geom_bar(stat = "identity", fill = "darkgray", color = "black") +
  theme_minimal() +
  labs(title = "Avg Serve Points Played by Tournament Level", x = "Tournament Level", y = "Avg Serve Points Played") +
  coord_cartesian(ylim = c(140, 230))  # Adjust ylim based on the range (Min: 141.1, Max: 222.5)

ggsave("tourney_avg_serve_points_played.png", plot = p7_tournament)


# Plot 8: Fraction of Serve Points Won by Tournament Level
p8_tournament <- ggplot(tournament_summary, aes(x = tourney_level, y = Fraction_Serve_Points_Won)) +
  geom_bar(stat = "identity", fill = "black", color = "black") +
  theme_minimal() +
  labs(title = "Fraction of Serve Points Won by Tournament Level", x = "Tournament Level", y = "Fraction of Serve Points Won") +
  coord_cartesian(ylim = c(0.43, 0.45))  # Adjust ylim based on the range (Min: 0.4312, Max: 0.4402)

ggsave("tourney_fraction_serve_points_won.png", plot = p8_tournament)


# Calculate the number of matches by surface and tournament level
proportion_df <- matches_df %>%
  group_by(tourney_level, surface) %>%
  summarise(Matches = n()) %>%
  ungroup() %>%
  group_by(tourney_level) %>%
  mutate(Proportion = Matches / sum(Matches))  # Calculate proportions

summary(proportion_df)

# Plot the proportional bar chart
p_surface_proportion <- ggplot(proportion_df, aes(x = tourney_level, y = Proportion, fill = surface)) +
  geom_bar(stat = "identity") +
  scale_y_continuous(labels = scales::percent_format()) +  # Format y-axis as percentage
  theme_minimal() +
  labs(title = "Proportion of Surfaces by Tournament Level",
       x = "Tournament Level",
       y = "Proportion of Matches",
       fill = "Surface") +
  scale_fill_manual(values = c(
    "Hard" = "#A9CCE3",   # Grayish Blue for Hard
    "Clay" = "#D98880",   # Terracotta for Clay
    "Grass" = "#A9DFBF",  # Greenish Gray for Grass
    "Carpet" = "#D5DBDB"  # Light Gray for Carpet
  ))

ggsave("surface_proportion_by_level.png", plot = p_surface_proportion)


match_counts <- matches_df %>%
  group_by(tourney_level, surface) %>%
  summarise(Matches = n()) %>%
  ungroup()

# Step 2: Calculate Proportions within each Tournament Level
match_proportions <- match_counts %>%
  group_by(tourney_level) %>%
  mutate(Proportion = Matches / sum(Matches) * 100) %>%
  ungroup()

# Print the proportions to check
print(match_proportions)

# Step 3: Summarize the Data by Tournament Level
tournament_level_summary <- match_proportions %>%
  group_by(tourney_level) %>%
  summarise(
    Hard_Proportion = sum(Proportion[surface == "Hard"], na.rm = TRUE),
    Clay_Proportion = sum(Proportion[surface == "Clay"], na.rm = TRUE),
    Grass_Proportion = sum(Proportion[surface == "Grass"], na.rm = TRUE),
    Carpet_Proportion = sum(Proportion[surface == "Carpet"], na.rm = TRUE)
  )

# Print the summary statistics
print(tournament_level_summary)


