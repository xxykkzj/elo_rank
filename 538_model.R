update_elo_scores_538 <- function(matches, elo_scores, delta, nu, sigma) {
  for (i in 1:nrow(matches)) {
    match <- matches[i, ]
    winner_id <- match$winner_id
    loser_id <- match$loser_id

    winner_elo <- elo_scores$elo[elo_scores$player_id == winner_id]
    loser_elo <- elo_scores$elo[elo_scores$player_id == loser_id]
    
    # Calculate the number of games played by the winner and loser before this match
    games_played_winner <- sum(matches$winner_id[1:(i-1)] == winner_id | matches$loser_id[1:(i-1)] == winner_id)
    games_played_loser <- sum(matches$winner_id[1:(i-1)] == loser_id | matches$loser_id[1:(i-1)] == loser_id)
    
    # Calculate the Expected Outcome
    expected_outcome <- 1 / (1 + 10^((loser_elo - winner_elo) / 400))
    
    # Calculate the dynamic K factor using the number of games played up to this point
    k_i_winner <- delta / (games_played_winner + nu) / sigma
    k_i_loser <- delta / (games_played_loser + nu) / sigma
    
    # Update Elo scores based on the outcome
    elo_scores$elo[elo_scores$player_id == winner_id] <- winner_elo + k_i_winner * (1 - expected_outcome)
    elo_scores$elo[elo_scores$player_id == loser_id] <- loser_elo - k_i_loser * (1-expected_outcome)
  }

  return(elo_scores)
}
