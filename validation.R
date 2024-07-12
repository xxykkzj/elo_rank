calculate_metrics <- function(train_df, test_df, full_df, elo_scores, model_name) {
  train_metrics <- calculate_elo_metrics(train_df, elo_scores)
  test_metrics <- calculate_elo_metrics(test_df, elo_scores)
  full_metrics <- calculate_elo_metrics(full_df, elo_scores)

  validation_stats <- tibble(
    model = rep(model_name, 3),
    pred_acc = c(train_metrics$accuracy, test_metrics$accuracy, full_metrics$accuracy),
    log_loss = c(train_metrics$log_loss, test_metrics$log_loss, full_metrics$log_loss),
    calibration = c(train_metrics$calibration, test_metrics$calibration, full_metrics$calibration),
    dataset = c("Training", "Testing", "Full Set")
  )

  return(validation_stats)
}

calculate_elo_metrics <- function(matches_subset, elo_scores) {
  matches_subset <- matches_subset %>%
    mutate(winner_elo = elo_scores$elo[match(winner_id, elo_scores$player_id)],
           loser_elo = elo_scores$elo[match(loser_id, elo_scores$player_id)],
           elo_probs = 1 / (1 + 10^((loser_elo - winner_elo) / 400)),
           elo_predictions = as.integer(winner_elo > loser_elo))

  accuracy <- mean(matches_subset$elo_predictions == matches_subset$higher_rank_won)
  log_loss <- -mean(matches_subset$higher_rank_won * log(matches_subset$elo_probs) + 
                    (1 - matches_subset$higher_rank_won) * log(1 - matches_subset$elo_probs))
  calibration <- sum(matches_subset$elo_probs) / sum(matches_subset$higher_rank_won)

  return(list(accuracy = accuracy, log_loss = log_loss, calibration = calibration))
}
