generate_plots <- function(elo_scores, elo_scores_538) {
  # Example plot function to show Elo ratings over time for each model and each player
  ggplot(elo_history_filtered, aes(x = tourney_date)) +
    geom_line(aes(y = elo_k, color = player_name, linetype = "K-factor")) +
    geom_line(aes(y = elo_538, color = player_name, linetype = "538 model")) +
    scale_color_manual(values = c('blue', 'orange')) +
    scale_linetype_manual(values = c('solid', 'dashed')) +
    labs(title = "Elo Ratings Over Time",
         x = "Year",
         y = "Elo Rating",
         color = "Player",
         linetype = "Model") +
    theme_minimal()
  
  # Save the plot
  ggsave("elo_ratings_over_time.png")
}

