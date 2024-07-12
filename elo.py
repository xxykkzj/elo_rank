
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import log_loss
import glob

# Load and combine data with explicit data type handling for 'tourney_date'
def load_data(file):
    return pd.read_csv(file, dtype={'tourney_date': 'str'})

path = 'C:/Users/biand/Downloads/tennis_atp/project/tennis_atp/'
files = glob.glob(path + 'atp_matches_*.csv')
raw_matches = pd.concat((load_data(file) for file in files), ignore_index=True)

# Convert 'tourney_date' to datetime
raw_matches['tourney_date'] = pd.to_datetime(raw_matches['tourney_date'], format='%Y%m%d', errors='coerce')
raw_matches.dropna(subset=['tourney_date'], inplace=True)

# Selecting and cleaning columns
matches_df = raw_matches[
    [
        'tourney_date', 'tourney_name', 'surface', 'draw_size', 
        'tourney_level', 'match_num', 'winner_id', 'loser_id', 
        'best_of', 'winner_rank', 'winner_rank_points', 
        'loser_rank', 'loser_rank_points'
    ]
]

matches_df['tourney_name'] = matches_df['tourney_name'].astype('category')
matches_df['surface'] = matches_df['surface'].astype('category')
matches_df['best_of'] = matches_df['best_of'].astype('category')

# Clean numeric columns
matches_df[['winner_rank', 'loser_rank', 'winner_rank_points', 'loser_rank_points']] = \
    matches_df[['winner_rank', 'loser_rank', 'winner_rank_points', 'loser_rank_points']].apply(pd.to_numeric, errors='coerce')

matches_df.dropna(subset=['winner_rank', 'loser_rank', 'winner_rank_points', 'loser_rank_points'], inplace=True)

matches_df[['winner_id', 'loser_id']] = matches_df[['winner_id', 'loser_id']].astype(int)
matches_df['diff'] = matches_df['winner_rank_points'] - matches_df['loser_rank_points']

# Define match outcome based on rank comparison
matches_df['higher_rank_won'] = matches_df['winner_rank'] < matches_df['loser_rank']

# Initialize Elo scores
initial_elo = 1500
unique_ids = pd.concat([matches_df['winner_id'], matches_df['loser_id']]).unique()
elo_scores = pd.DataFrame({
    'player_id': unique_ids,
    'elo': np.full(len(unique_ids), initial_elo, dtype=float)
}).drop_duplicates().set_index('player_id')

# Elo update functions
def k_factor_model_update(k, winner_elo, loser_elo, outcome):
    return k * (outcome - 1 / (1 + 10 ** ((loser_elo - winner_elo) / 400)))

def fivethirtyeight_model_update(games_played, delta, nu, sigma, winner_elo, loser_elo, outcome):
    k_i = delta / (games_played + nu) / sigma
    return k_i * (outcome - 1 / (1 + 10 ** ((loser_elo - winner_elo) / 400)))

# Update Elo scores
def update_elo_scores(df, elo_scores, k, delta, nu, sigma):
    for _, row in df.iterrows():
        winner_id, loser_id = row['winner_id'], row['loser_id']
        winner_elo, loser_elo = elo_scores.loc[winner_id], elo_scores.loc[loser_id]
        outcome = row['higher_rank_won']

        # Update Elo scores based on both models
        elo_change_k = k_factor_model_update(k, winner_elo, loser_elo, outcome)
        elo_change_538 = fivethirtyeight_model_update(row['match_num'], delta, nu, sigma, winner_elo, loser_elo, outcome)
        
        elo_scores.loc[winner_id] += (elo_change_k + elo_change_538)
        elo_scores.loc[loser_id] -= (elo_change_k + elo_change_538)

    return elo_scores

# Split data into training and testing based on date
split_time = datetime.strptime("2019-01-01", "%Y-%m-%d")
train_df = matches_df[matches_df['tourney_date'] < split_time]
test_df = matches_df[matches_df['tourney_date'] >= split_time]

# Update Elo scores for training data
elo_scores_updated = update_elo_scores(train_df, elo_scores.copy(), 25, 100, 5, 0.1)

# Logistic Regression Model
logistic_model = LogisticRegression()
logistic_model.fit(train_df[['diff']], train_df['higher_rank_won'])

# Predict probabilities of winning for the training set
train_probs = logistic_model.predict_proba(train_df[['diff']])[:, 1]
train_preds = (train_probs > 0.5).astype(int)

# Calculate metrics
train_accuracy = np.mean(train_preds == train_df['higher_rank_won'])
train_log_loss = log_loss(train_df['higher_rank_won'], train_probs)

# Plot logistic regression probability curve
x_values = np.linspace(train_df['diff'].min(), train_df['diff'].max(), 300)
y_probs = logistic_model.predict_proba(x_values.reshape(-1, 1))[:, 1]

plt.figure(figsize=(10, 6))
plt.plot(x_values, y_probs, label='Prob. of Higher Rank Winning')
plt.xlabel("Difference in Rank Points")
plt.ylabel("Probability")
plt.title("Logistic Regression Predicted Probabilities")
plt.legend()
plt.show()
