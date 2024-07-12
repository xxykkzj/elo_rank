prepare_data <- function() {
  # Create a vector of file names to read
  setwd("C:/Users/biand/Downloads/tennis_atp/")
  files <- str_glue("atp_matches_{2010:2019}.csv")

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
