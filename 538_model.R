fivethirtyeight_model_update <- function(games_played, delta, nu, sigma, winner_elo, loser_elo, outcome) {
  k_i <- delta / (games_played + nu) / sigma
  return(k_i * (outcome - 1 / (1 + 10^((loser_elo - winner_elo) / 400))))
}

update_elo_scores_538 <- function(matches, elo_scores, delta, nu, sigma) {
  matches <- matches %>%
    mutate(winner_elo = elo_scores$elo[match(winner_id, elo_scores$player_id)],
           loser_elo = elo_scores$elo[match(loser_id, elo_scores$player_id)])

  matches <- matches %>%
    mutate(elo_change = fivethirtyeight_model_update(match_num, delta, nu, sigma, winner_elo, loser_elo, higher_rank_won),
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
