import os
os.chdir(r"C:\Users\biand\Downloads\tennis_atp\project\python")
print("Current directory:", os.getcwd())

import data_preparation as dp
import elo_model as elo
import fivethirtyeight_model as fte
import validation as val
import plots as pl
import pandas as pd
import importlib
# Load and prepare data
matches_df = pd.read_csv(r"C:\Users\biand\Downloads\tennis_atp\project\filtered_ds.csv")
importlib.reload(dp)
# Split data into training and testing sets
matches_df.describe()
matches_df['tourney_date'].to_string()
matches_df['tourney_date'] = pd.to_datetime(matches_df['tourney_date'], format='%Y%m%d', errors='coerce')
matches_train_df, matches_test_df = dp.split_data(matches_df)

# Initialize Elo scores
initial_elo = 1500
elo_scores = elo.initialize_elo_scores(matches_df, initial_elo)
elo_scores_538 = fte.initialize_elo_scores(matches_df, initial_elo)

# Update Elo scores
elo_scores = elo.update_elo_scores_elo(matches_train_df, elo_scores, k=25)
elo_scores_538 = fte.update_elo_scores_538(matches_train_df, elo_scores_538, delta=100, nu=5, sigma=0.1)

# Calculate performance metrics
metrics_elo = val.calculate_metrics(matches_train_df, matches_test_df, matches_df, elo_scores, "Elo")
metrics_538 = val.calculate_metrics(matches_train_df, matches_test_df, matches_df, elo_scores_538, "538")

# Generate and save plots
pl.generate_plots(elo_scores, elo_scores_538)

# Print metrics
print(metrics_elo)
print(metrics_538)


