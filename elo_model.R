initialize_elo_scores <- function(matches_df, initial_elo) {
  elo_scores <- data.frame(player_id = unique(c(matches_df$winner_id, matches_df$loser_id)),
                           elo = rep(initial_elo, n_distinct(c(matches_df$winner_id, matches_df$loser_id))))
  return(elo_scores)
}

k_factor_model_update <- function(k, winner_elo, loser_elo, outcome) {
  return(k * (outcome - 1 / (1 + 10^((loser_elo - winner_elo) / 400))))
}

update_elo_scores_elo <- function(matches, elo_scores, k) {
  for (i in 1:nrow(matches)) {
    match <- matches[i, ]
    winner_id <- match$winner_id
    loser_id <- match$loser_id

    winner_elo <- elo_scores$elo[elo_scores$player_id == winner_id]
    loser_elo <- elo_scores$elo[elo_scores$player_id == loser_id]

    elo_change <- k_factor_model_update(k, winner_elo, loser_elo, match$higher_rank_won)

    elo_scores$elo[elo_scores$player_id == winner_id] <- winner_elo + elo_change
    elo_scores$elo[elo_scores$player_id == loser_id] <- loser_elo - elo_change
  }

  return(elo_scores)
}
