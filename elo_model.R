
initialize_elo_scores <- function(matches_df, initial_elo) {
  elo_scores <- data.frame(player_id = unique(c(matches_df$winner_id, matches_df$loser_id)),
                           elo = rep(initial_elo, n_distinct(c(matches_df$winner_id, matches_df$loser_id))))
  return(elo_scores)
}


update_elo_scores_elo <- function(matches, elo_scores, k) {
  for (i in 1:nrow(matches)) {
    match <- matches[i, ]
    winner_id <- match$winner_id
    loser_id <- match$loser_id

    winner_elo <- elo_scores$elo[elo_scores$player_id == winner_id]
    loser_elo <- elo_scores$elo[elo_scores$player_id == loser_id]

    # Correct Expected Outcome calculation: winner_elo - loser_elo
    expected_outcome <- 1 / (1 + 10^((loser_elo - winner_elo) / 400))
    # Update Elo scores
    elo_scores$elo[elo_scores$player_id == winner_id] <- winner_elo + k * (1- expected_outcome)
    elo_scores$elo[elo_scores$player_id == loser_id] <- loser_elo - k*(1-expected_outcome)
  }

  return(elo_scores)
}


