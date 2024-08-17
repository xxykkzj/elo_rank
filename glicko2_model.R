update_glicko2 <- function(matches_df, glicko2_scores, tau = 0.5) {
  q <- log(10) / 400
  
  for (i in 1:nrow(matches_df)) {
    match <- matches_df[i, ]
    winner_id <- match$winner_id
    loser_id <- match$loser_id
    
    # Get player statistics
    winner <- glicko2_scores[glicko2_scores$player_id == winner_id, ]
    loser <- glicko2_scores[glicko2_scores$player_id == loser_id, ]
    
    # Calculate g_rd for both players
    g_rd_winner <- 1 / sqrt(1 + 3 * (q^2) * (loser$rd^2) / pi^2)
    g_rd_loser <- 1 / sqrt(1 + 3 * (q^2) * (winner$rd^2) / pi^2)
    
    # Calculate expected outcomes
    expected_outcome_winner <- calculate_expected_outcome_glicko(winner$rating, loser$rating, loser$rd)
    expected_outcome_loser <- calculate_expected_outcome_glicko(loser$rating, winner$rating, winner$rd)
    
    # Track opponents faced
    winner_opponents <- list()
    loser_opponents <- list()
    
    # Accumulate opponents for the current match
    winner_opponents[[length(winner_opponents) + 1]] <- list(rating = loser$rating, rd = loser$rd)
    loser_opponents[[length(loser_opponents) + 1]] <- list(rating = winner$rating, rd = winner$rd)
    
    # Now calculate v using all opponents faced
    v_winner <- calculate_variance(winner_opponents, winner$rating)
    v_loser <- calculate_variance(loser_opponents, loser$rating)
    
    # Calculate the delta values
    delta_winner <- calculate_delta(v_winner, g_rd_winner, 1, expected_outcome_winner)
    delta_loser <- calculate_delta(v_loser, g_rd_loser, 0, expected_outcome_loser)
    
    # Update volatility
    winner$volatility <- update_volatility(winner$volatility, winner$rd, delta_winner, v_winner, tau)
    loser$volatility <- update_volatility(loser$volatility, loser$rd, delta_loser, v_loser, tau)
    
    # Update RD
    winner$rd <- update_rd(winner$rd, winner$volatility)
    loser$rd <- update_rd(loser$rd, loser$volatility)
    
    # Update ratings
    winner$rating <- update_mu(winner$rating, winner$rd, v_winner, g_rd_winner, 1, expected_outcome_winner)
    loser$rating <- update_mu(loser$rating, loser$rd, v_loser, g_rd_loser, 0, expected_outcome_loser)
    
    # Save updated values back into glicko2_scores
    glicko2_scores[glicko2_scores$player_id == winner_id, ] <- winner
    glicko2_scores[glicko2_scores$player_id == loser_id, ] <- loser
  }
  
  return(glicko2_scores)
}
