prepare_data <- function() {
  # Create a vector of file names to read
  files <- str_glue("tennis_atp/atp_matches_{2010:2019}.csv")

  # Read each file and combine them into one data frame
  raw_matches <- map_dfr(files, ~read_csv(.x, show_col_types = FALSE))

  # Process the data frame
  matches_df <- raw_matches %>%
    select(tourney_date, tourney_name, surface, draw_size, tourney_level, match_num, winner_id, loser_id, best_of, winner_rank, winner_rank_points, loser_rank, loser_rank_points) %>%
    mutate_at(vars(tourney_name, surface, best_of), as.factor) %>%
    mutate_at(vars(winner_id, loser_id), as.integer) %>%
    mutate(tourney_date = ymd(tourney_date)) %>%
    mutate(loser_rank = replace_na(loser_rank, 100000),
           winner_rank = replace_na(winner_rank, 100000),
           higher_rank_won = winner_rank < loser_rank,
           higher_rank_points = winner_rank_points * (higher_rank_won) + loser_rank_points * (1 - higher_rank_won),
           lower_rank_points = winner_rank_points * (1 - higher_rank_won) + loser_rank_points * (higher_rank_won),
           diff = higher_rank_points - lower_rank_points)

  return(matches_df)
}

split_data <- function(matches_df) {
  split_time <- ymd("2019-01-01")
  matches_train_df <- filter(matches_df, tourney_date < split_time)
  matches_test_df <- filter(matches_df, tourney_date >= split_time)

  return(list(train = matches_train_df, test = matches_test_df))
}
library(dplyr)

# Function to prepare data and filter top N players based on average rank
prepare_top_players <- function(matches_df, top_n = 100) {
  # Combine winner and loser data
  combined_df <- matches_df %>%
    select(winner_id, loser_id, winner_rank, winner_rank_points, loser_rank, loser_rank_points) %>%
    gather(key = "result", value = "player_id", winner_id, loser_id) %>%
    gather(key = "result_rank", value = "rank", winner_rank, loser_rank) %>%
    gather(key = "result_points", value = "rank_points", winner_rank_points, loser_rank_points)
  
  # Average rank points for each player
  player_avg_rank <- combined_df %>%
    group_by(player_id) %>%
    summarize(avg_rank = mean(rank, na.rm = TRUE)) %>%
    arrange(avg_rank) %>%
    slice(1:top_n)
  
  # Filter matches to only include top players
  top_players_df <- matches_df %>%
    filter(winner_id %in% player_avg_rank$player_id | loser_id %in% player_avg_rank$player_id)
  
  return(top_players_df)
}

library(dplyr)

prepare_top_and_bottom_players <- function(matches_df, top_n, bottom_m) {
  # Gather the relevant columns into a long format
  player_ranks <- matches_df %>%
    gather(key = "type", value = "player_id", winner_id, loser_id) %>%
    gather(key = "rank_type", value = "rank", winner_rank, loser_rank) %>%
    filter(type == sub("_id", "", rank_type)) %>%
    select(player_id, rank)

  # Calculate the average rank for each player
  player_avg_rank <- player_ranks %>%
    group_by(player_id) %>%
    summarise(avg_rank = mean(rank, na.rm = TRUE))

  # Identify the top_n and bottom_m players
  top_players <- player_avg_rank %>%
    arrange(avg_rank) %>%
    head(top_n) %>%
    pull(player_id)

  bottom_players <- player_avg_rank %>%
    arrange(desc(avg_rank)) %>%
    head(bottom_m) %>%
    pull(player_id)

  # Combine top and bottom players
  selected_players <- c(top_players, bottom_players)

  # Filter the original matches to include only the selected players
  filtered_matches_df <- matches_df %>%
    filter(winner_id %in% selected_players | loser_id %in% selected_players)

  return(filtered_matches_df)
}

# Example usage:
# filtered_df <- prepare_top_and_bottom_players(matches_df, top_n = 50, bottom_m = 50)
