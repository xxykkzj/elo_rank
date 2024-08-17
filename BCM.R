# Create a vector of file names to read
setwd("C:/Users/biand/Documents/project/elo_rank")
# files <- str_glue("tennis_bet_csv/{2010:2019}.csv")
  
# # Read each file and combine them into one data frame
# raw_matches <- map_dfr(files, ~read_csv(.x, show_col_types = FALSE))%>%drop_na()

pacman::p_load(dplyr, readr)
# # Export to CSV
# write_csv(raw_matches, "C:/Users/biand/Documents/project/elo_rank/2010-2019.csv")
bets_df <- read_csv("2010-2019.csv")

# Step 2: Calculate Implied Probabilities
bets_df <- bets_df %>%
  mutate(
    Implied_Prob_B365W = 1 / B365W,
    Implied_Prob_B365L = 1 / B365L,
    Implied_Prob_PSW = 1 / PSW,
    Implied_Prob_PSL = 1 / PSL,
    Implied_Prob_LBW = 1 / LBW,
    Implied_Prob_LBL = 1 / LBL,
    Implied_Prob_MaxW = 1 / MaxW,
    Implied_Prob_MaxL = 1 / MaxL,
    Implied_Prob_AvgW = 1 / AvgW,
    Implied_Prob_AvgL = 1 / AvgL,
    Implied_Prob_SJW = 1 / SJW,
    Implied_Prob_SJL = 1 / SJL
  )

# Step 3: Calculate Consensus Winning Probabilities
bets_df <- bets_df %>%
  mutate(
    Consensus_Prob_Winner = rowMeans(select(., starts_with("Implied_Prob_"))[ , c(1, 3, 5, 7, 9, 11)], na.rm = TRUE),
    Consensus_Prob_Loser = rowMeans(select(., starts_with("Implied_Prob_"))[ , c(2, 4, 6, 8, 10, 12)], na.rm = TRUE)
  )

# Step 4: Manual Bradley-Terry Model

# Step 4.1: Initialize player abilities
players <- unique(c(bets_df$Winner, bets_df$Loser))
abilities <- rep(1, length(players))
names(abilities) <- players

# Step 4.2: Define the log-likelihood function
log_likelihood <- function(abilities, bets_df) {
  log_likelihood_value <- 0
  for (i in 1:nrow(bets_df)) {
    winner <- bets_df$Winner[i]
    loser <- bets_df$Loser[i]
    log_likelihood_value <- log_likelihood_value + 
      log(abilities[winner]) - log(abilities[winner] + abilities[loser])
  }
  return(-log_likelihood_value)  # We return the negative for minimization
}

# Step 4.3: Optimize the log-likelihood function
optimized <- optim(par = abilities, fn = log_likelihood, bets_df = bets_df, 
                   method = "BFGS", control = list(fnscale = -1))

# Step 4.4: Extract the optimized abilities
optimized_abilities <- optimized$par

# Step 4.5: Calculate the predicted probabilities based on the optimized abilities
bets_df <- bets_df %>%
  rowwise() %>%
  mutate(
    Predicted_Winner_Prob = optimized_abilities[Winner] / 
                            (optimized_abilities[Winner] + optimized_abilities[Loser])
  )

write_csv(bets_df, "C:/Users/biand/Documents/project/elo_rank/full_manual_bradley_terry_predictions.csv")