# Import required libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
from sklearn.cluster import KMeans
from sklearn.metrics import log_loss

# Load and combine data
path = 'C:/Users/biand/Downloads/tennis_atp/'
files = glob.glob(path + 'atp_matches_*.csv')
raw_matches = pd.concat((pd.read_csv(file) for file in files), ignore_index=True)

# Select and manipulate columns
matches_df = raw_matches[['tourney_date', 'tourney_name', 'surface', 'draw_size', 'tourney_level', 'match_num', 'winner_id', 'loser_id', 'best_of', 'winner_rank', 'winner_rank_points', 'loser_rank', 'loser_rank_points']]
matches_df['tourney_name'] = matches_df['tourney_name'].astype('category')
matches_df['surface'] = matches_df['surface'].astype('category')
matches_df['best_of'] = matches_df['best_of'].astype('category')
matches_df['winner_id'] = matches_df['winner_id'].astype(int)
matches_df['loser_id'] = matches_df['loser_id'].astype(int)
matches_df['tourney_date'] = pd.to_datetime(matches_df['tourney_date'], format='%Y%m%d')

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

# Save dataset
filtered_df = matches_df[matches_df['winner_id'].isin([105554, 103852]) | matches_df['loser_id'].isin([105554, 103852])]
filtered_df.to_csv('C:/Users/biand/Downloads/tennis_atp/project/filtered_ds.csv', index=False)
