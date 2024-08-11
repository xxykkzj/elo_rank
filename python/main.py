import pandas as pd
import data_preparation as dp
import elo_model as elo
import fivethirtyeight_model as fte
import bayes_point_model as bpm
import validation as val
import plots as pl
import tunning as tn

# Load and prepare the data
matches_df = dp.prepare_data('path_to_your_csv_file')
matches_train_df, matches_test_df = dp.split_data(matches_df)

# Initialize the models
elo_scores = elo.initialize_elo_scores(matches_df)
elo_scores_538 = fte.initialize_elo_scores(matches_df)
start_date = pd.to_datetime(matches_df['tourney_date'].min())
bayes_model = bpm.BayesPointModel(start_date=start_date, dataset=matches_df)

# Tune the models
best_params_elo, best_params_fte = tn.tune_models(matches_train_df, matches_test_df, matches_df)

# Update the Elo scores with the best parameters
elo_scores = elo.update_elo_scores_elo(matches_train_df, elo_scores, best_params_elo['k'])
elo_scores_538 = fte.update_elo_scores_538(matches_train_df, elo_scores_538, best_params_fte['delta'])

# Fit the Bayesian model
bayes_model.fit_model(bayes_model.calculate_period(start_date))

# Calculate metrics
metrics_elo = val.calculate_metrics(matches_train_df, matches_test_df, matches_df, elo_scores, 'Elo')
metrics_538 = val.calculate_metrics(matches_train_df, matches_test_df, matches_df, elo_scores_538, '538')
metrics_bayes = bpm.calculate_metrics(bayes_model, matches_train_df, matches_test_df)

# Print metrics
print(metrics_elo)
print(metrics_538)
print(metrics_bayes)

# Plot results
pl.plot_elo_ratings_over_time(elo_scores, elo_scores_538, matches_df)
pl.plot_model_comparison(metrics_elo, metrics_538, metrics_bayes)
