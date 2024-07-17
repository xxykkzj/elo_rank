import pandas as pd
import numpy as np

def initialize_elo_scores(matches_df, initial_elo):
    unique_ids = pd.concat([matches_df['winner_id'], matches_df['loser_id']]).unique()
    elo_scores = pd.DataFrame({'player_id': unique_ids, 'elo': np.full(len(unique_ids), initial_elo, dtype=float)})
    elo_scores = elo_scores.drop_duplicates().set_index('player_id')
    return elo_scores

def k_factor_model_update(k, winner_elo, loser_elo, outcome):
    return k * (outcome - 1 / (1 + 10 ** ((loser_elo - winner_elo) / 400)))

def update_elo_scores_elo(df, elo_scores, k):
    for _, row in df.iterrows():
        winner_id, loser_id = row['winner_id'], row['loser_id']
        winner_elo, loser_elo = elo_scores.loc[winner_id], elo_scores.loc[loser_id]
        outcome = row['higher_rank_won']

        elo_change = k_factor_model_update(k, winner_elo, loser_elo, outcome)
        elo_scores.loc[winner_id] += elo_change
        elo_scores.loc[loser_id] -= elo_change

    return elo_scores
