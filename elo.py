# Import required libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
from sklearn.cluster import KMeans
from sklearn.metrics import log_loss
import glob
# Load and combine data with explicit data type handling for 'tourney_date'
def load_data(file):
    return pd.read_csv(file, dtype={'tourney_date': 'str'})

path = 'C:/Users/biand/Downloads/tennis_atp/project/tennis_atp/'
files = glob.glob(path + 'atp_matches_*.csv')
raw_matches = pd.concat((load_data(file) for file in files), ignore_index=True)

# Now 'tourney_date' is read as string and can be converted to datetime without floating point issues
raw_matches['tourney_date'] = pd.to_datetime(raw_matches['tourney_date'], format='%Y%m%d')

# Assuming raw_matches is already loaded with data

# Selecting columns
matches_df = raw_matches[['tourney_date', 'tourney_name', 'surface', 'draw_size', 
                          'tourney_level', 'match_num', 'winner_id', 'loser_id', 
                          'best_of', 'winner_rank', 'winner_rank_points', 
                          'loser_rank', 'loser_rank_points']].copy()

# Converting to appropriate types
matches_df['tourney_name'] = matches_df['tourney_name'].astype('category')
matches_df['surface'] = matches_df['surface'].astype('category')
matches_df['best_of'] = matches_df['best_of'].astype('category')
# Find entries that are not of expected length for format '%Y%m%d' which should be 8 characters long
invalid_dates = matches_df[matches_df['tourney_date'].apply(lambda x: len(str(x)) != 8)]
print(invalid_dates)
#####invalid_dates.to_csv('C:/Users/biand/Downloads/tennis_atp/project/invalid_dates.csv', index=False)
matches_df['tourney_date'] = pd.to_datetime(matches_df['tourney_date'], format='%Y%m%d', errors='coerce')
# Check how many NaT values were created
print(matches_df['tourney_date'].isna().sum())

#drop these rows or fill them with a placeholder date
matches_df.dropna(subset=['tourney_date'], inplace=True) 


# Replace infinite values and drop rows with NaN values in specific columns
matches_df.replace([np.inf, -np.inf], np.nan, inplace=True)
matches_df.dropna(subset=['winner_rank', 'winner_rank_points', 'loser_rank', 'loser_rank_points'], inplace=True)

# Convert IDs and ranks to integers, handling any non-finite numbers beforehand
matches_df['winner_id'] = matches_df['winner_id'].astype(int)
matches_df['loser_id'] = matches_df['loser_id'].astype(int)

# Assuming winner_rank and loser_rank should be integers
matches_df['winner_rank'] = matches_df['winner_rank'].fillna(-1).astype(int)  # Fill NaNs with -1 or another placeholder
matches_df['loser_rank'] = matches_df['loser_rank'].fillna(-1).astype(int)

# If the rank points can be floats and need rounding or other handling, adjust as necessary:
matches_df['winner_rank_points'] = matches_df['winner_rank_points'].fillna(0).astype(int)
matches_df['loser_rank_points'] = matches_df['loser_rank_points'].fillna(0).astype(int)
# Define higher_rank_won based on rank comparison
matches_df['higher_rank_won'] = matches_df['winner_rank'] < matches_df['loser_rank']
# Print the DataFrame to verify changes
print(matches_df.head())


# Initialize Elo scores
initial_elo = 1500
unique_ids = pd.concat([matches_df['winner_id'], matches_df['loser_id']]).unique()
elo_scores = pd.DataFrame({
    'player_id': unique_ids,
    'elo': np.full(len(unique_ids), initial_elo)
})

# Elo update functions
def k_factor_model_update(k, winner_elo, loser_elo, outcome):
    elo_change = k * (outcome - 1 / (1 + 10 ** ((loser_elo - winner_elo) / 400)))
    return elo_change

def fivethirtyeight_model_update(games_played, delta, nu, sigma, winner_elo, loser_elo, outcome):
    k_i = delta / (games_played + nu) / sigma
    elo_change = k_i * (outcome - 1 / (1 + 10 ** ((loser_elo - winner_elo) / 400)))
    return elo_change

# Split data
split_time = datetime.strptime("2019-01-01", "%Y-%m-%d")
matches_train_df = matches_df[matches_df['tourney_date'] < split_time]
matches_test_df = matches_df[matches_df['tourney_date'] >= split_time]

# Update Elo scores for training data
k = 25
delta = 100
nu = 5
sigma = 0.1

for index, match in matches_train_df.iterrows():
    winner_id = match['winner_id']
    loser_id = match['loser_id']
    winner_elo = elo_scores.loc[elo_scores['player_id'] == winner_id, 'elo'].values[0]
    loser_elo = elo_scores.loc[elo_scores['player_id'] == loser_id, 'elo'].values[0]
    outcome = match['higher_rank_won']
    
    # K-factor model update
    elo_change_k = k_factor_model_update(k, winner_elo, loser_elo, outcome)
    elo_scores.loc[elo_scores['player_id'] == winner_id, 'elo'] += elo_change_k
    elo_scores.loc[elo_scores['player_id'] == loser_id, 'elo'] -= elo_change_k
    
    # FiveThirtyEight model update
    games_played = match['match_num']
    elo_change_538 = fivethirtyeight_model_update(games_played, delta, nu, sigma, winner_elo, loser_elo, outcome)
    elo_scores.loc[elo_scores['player_id'] == winner_id, 'elo'] += elo_change_538
    elo_scores.loc[elo_scores['player_id'] == loser_id, 'elo'] -= elo_change_538


# Calculate statistics for the naive model on the training set
N_train = len(matches_train_df)
naive_accuracy_train = matches_train_df['higher_rank_won'].mean()
w_train = matches_train_df['higher_rank_won']
pi_naive_train = naive_accuracy_train
log_loss_naive_train = -1 / N_train * np.sum(w_train * np.log(pi_naive_train) + (1 - w_train) * np.log(1 - pi_naive_train))
calibration_naive_train = pi_naive_train * N_train / np.sum(w_train)

# Calculate statistics for the naive model on the testing set
N_test = len(matches_test_df)
naive_accuracy_test = matches_test_df['higher_rank_won'].mean()
w_test = matches_test_df['higher_rank_won']
pi_naive_test = naive_accuracy_test
log_loss_naive_test = -1 / N_test * np.sum(w_test * np.log(pi_naive_test) + (1 - w_test) * np.log(1 - pi_naive_test))
calibration_naive_test = pi_naive_test * N_test / np.sum(w_test)




