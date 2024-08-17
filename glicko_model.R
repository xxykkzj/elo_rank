initialize_glicko_scores <-function(matches_df, initial_rating =1500, initial_rd =350){
  glicko_scores <- data.frame(
    player_id = unique(c(matches_df$winner_id, matches_df$loser_id)),
    rating =rep(initial_rating, n_distinct(c(matches_df$winner_id, matches_df$loser_id))),
    rd =rep(initial_rd, n_distinct(c(matches_df$winner_id, matches_df$loser_id))))
    return(glicko_scores)}



calculate_expected_outcome_glicko <-function(winner_rating, loser_rating, loser_rd){
  q <-log(10)/400
  g_rd <- 1 /sqrt(1+(3* q^2* loser_rd^2)/pi^2)
  expected_outcome <- 1 /(1+10^(-g_rd *(winner_rating - loser_rating)/400))
  return(expected_outcome)}

update_glicko <-function(matches_df, glicko_scores,c=63.2){
  q <-log(10)/400
  for(i in 1:nrow(matches_df)){
    match <- matches_df[i,]
    winner_id <- match$winner_id
    loser_id <- match$loser_id
    
    # Update RD for inactivity before calculating new ratings
    glicko_scores$rd <- pmin(sqrt(glicko_scores$rd^2+c^2),350)
    
    winner <- glicko_scores[glicko_scores$player_id == winner_id,]
    loser <- glicko_scores[glicko_scores$player_id == loser_id,]
    
    expected_outcome_winner <- calculate_expected_outcome_glicko(winner$rating, loser$rating, loser$rd)
    
    g_rd_winner <- 1 /sqrt(1+(3* q^2* loser$rd^2)/pi^2)
    g_rd_loser <- 1 /sqrt(1+(3* q^2* winner$rd^2)/pi^2)
    
    d2_winner <-(q^2* g_rd_winner^2* expected_outcome_winner *(1- expected_outcome_winner))^(-1)
    d2_loser <-(q^2* g_rd_loser^2* expected_outcome_winner *(1- expected_outcome_winner))^(-1)
    
    winner$rating <- winner$rating + q /(1/ winner$rd^2+1/ d2_winner)* g_rd_winner *(1- expected_outcome_winner)
    loser$rating <- loser$rating + q /(1/ loser$rd^2+1/ d2_loser)* g_rd_loser *(0-(1- expected_outcome_winner))
    
    winner$rd <-sqrt((1/ winner$rd^2+1/ d2_winner)^(-1))
    loser$rd <-sqrt((1/ loser$rd^2+1/ d2_loser)^(-1))
    glicko_scores[glicko_scores$player_id == winner_id,]<- winner
    glicko_scores[glicko_scores$player_id == loser_id,]<- loser
    }

    return(glicko_scores)
}