import pandas as pd
import data_preparation as dp
import elo_model as elo
import fivethirtyeight_model as fte
import validation as val
import plots as pl
import tunning as tn

# Load and prepare data
matches_df = dp.prepare_data(r"filtered_ds.csv")

# Split data into training and testing sets
matches_train_df, matches_test_df = dp.split_data(matches_df)

# Tune models
# best_params_elo, best_params_fte = tn.tune_models(matches_train_df, matches_test_df, matches_df)

# print(f"Best parameters for Elo model: {best_params_elo}")
# print(f"Best parameters for FiveThirtyEight model: {best_params_fte}")

# Train final models with best parameters
elo_scores = elo.initialize_elo_scores(matches_df, initial_elo=1500)
elo_scores = elo.update_elo_scores_elo(matches_train_df, elo_scores, k=37)
fte_scores = fte.initialize_elo_scores(matches_df, initial_elo=1500)
fte_scores = fte.update_elo_scores_538(matches_train_df, fte_scores, delta=10, nu=5, sigma=0.1)

# Calculate metrics
metrics_elo = val.calculate_metrics(matches_train_df, matches_test_df, matches_df, elo_scores, "Elo")
metrics_fte = val.calculate_metrics(matches_train_df, matches_test_df, matches_df, fte_scores, "538")

print(metrics_elo)
print(metrics_fte)

# Plot results
#pl.plot_results(matches_train_df, matches_test_df, matches_df, elo_scores, fte_scores)
