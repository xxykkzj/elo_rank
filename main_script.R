
setwd("C:/Users/biand/Documents/project/elo_rank")
source("data_preparation.R")
source("elo_model.R")
source("538_model.R")
source("validation.R")
source("plots.R")
source("tunning.R")
source("glicko_model.R")
# Load and prepare data
pacman::p_load(tidyverse, lubridate, patchwork, knitr, welo,ggplot2,caret)
matches_df <- prepare_data()
# Split data into training and testing sets
splits <- split_data(matches_df)
matches_train_df <- splits$train
matches_test_df <- splits$test

# Initialize Elo scores
initial_elo <- 1500
elo_scores <- initialize_elo_scores(matches_df, initial_elo)
elo_scores_538 <- initialize_elo_scores(matches_df, initial_elo)
glicko_scores <- initialize_glicko_scores(matches_df, initial_rating =1500, initial_rd =350)
#Tune the Traditional Elo model
# tuned_elo <- tune_traditional_elo(matches_train_df, matches_test_df, elo_scores, initial_elo)
# best_k_elo <- tuned_elo$best_k
# print(paste("Best k for Traditional Elo Model:", best_k_elo))

# Tune the FiveThirtyEight model
# tuned_538 <- tune_538_model(matches_train_df, matches_test_df, elo_scores, initial_elo)
# Update Elo scores

tuned_glicko <- tune_glicko(matches_train_df, matches_test_df, glicko_scores)
print(tuned_glicko$best_c)

elo_scores <- update_elo_scores_elo(matches_train_df, elo_scores, k = 14)
elo_scores_538 <- update_elo_scores_538(matches_train_df, elo_scores_538, delta = 154, nu = 1, sigma = 0.1)
glicko_scores <- update_glicko(matches_train_df, glicko_scores,c=63.2)

# Calculate performance metrics
metrics_elo <- calculate_metrics(matches_train_df, matches_test_df, matches_df, elo_scores, "Elo")
metrics_538 <- calculate_metrics(matches_train_df, matches_test_df, matches_df, elo_scores_538, "538")
glicko_metrics <- calculate_glicko_metrics(matches_train_df, matches_test_df, matches_df, glicko_scores, "Glicko")


# Print metrics
print(metrics_elo)
print(metrics_538)
print(glicko_metrics)

