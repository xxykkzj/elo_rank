initialize_elo_scores <- function(matches_df, initial_elo) {
  elo_scores <- data.frame(player_id = unique(c(matches_df$winner_id, matches_df$loser_id)),
                           elo = rep(initial_elo, n_distinct(c(matches_df$winner_id, matches_df$loser_id))))
  return(elo_scores)
}

k_factor_model_update <- function(k, winner_elo, loser_elo, outcome) {
  return(k * (outcome - 1 / (1 + 10^((loser_elo - winner_elo) / 400))))
}

update_elo_scores_elo <- function(matches, elo_scores, k) {
  matches <- matches %>%
    mutate(winner_elo = elo_scores$elo[match(winner_id, elo_scores$player_id)],
           loser_elo = elo_scores$elo[match(loser_id, elo_scores$player_id)])

  matches <- matches %>%
    mutate(elo_change = k_factor_model_update(k, winner_elo, loser_elo, higher_rank_won),
           new_winner_elo = winner_elo + elo_change,
           new_loser_elo = loser_elo - elo_change)

  elo_scores <- bind_rows(
    elo_scores,
    matches %>% select(player_id = winner_id, elo = new_winner_elo),
    matches %>% select(player_id = loser_id, elo = new_loser_elo)
  ) %>%
    group_by(player_id) %>%
    summarize(elo = mean(elo))

  return(elo_scores)
}
