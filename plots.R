source("data_preparation.R")
source("elo_model.R")
source("538_model.R")
source("validation.R")
source("plots.R")

# Load and prepare data
matches_df <- prepare_data()

# Split data into training and testing sets
splits <- split_data(matches_df)
matches_train_df <- splits$train
matches_test_df <- splits$test

# Initialize Elo scores
initial_elo <- 1500
elo_scores <- initialize_elo_scores(matches_df, initial_elo)
elo_scores_538 <- initialize_elo_scores(matches_df, initial_elo)

# Update Elo scores
elo_scores <- update_elo_scores_elo(matches_train_df, elo_scores, k = 25)
elo_scores_538 <- update_elo_scores_538(matches_train_df, elo_scores_538, delta = 100, nu = 5, sigma = 0.1)

# Calculate performance metrics
metrics_elo <- calculate_metrics(matches_train_df, matches_test_df, matches_df, elo_scores, "Elo")
metrics_538 <- calculate_metrics(matches_train_df, matches_test_df, matches_df, elo_scores_538, "538")

# Generate and save plots
generate_plots(elo_scores, elo_scores_538)

# Print metrics
print(metrics_elo)
print(metrics_538)
