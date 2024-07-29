def initialize_elo_scores(matches_df, initial_elo):
    unique_ids = pd.concat([matches_df['winner_id'], matches_df['loser_id']]).unique()
    elo_scores = pd.DataFrame({'player_id': unique_ids, 'elo': np.full(len(unique_ids), initial_elo, dtype=float)})
    elo_scores = elo_scores.drop_duplicates().set_index('player_id')
    return elo_scores

def fivethirtyeight_model_update(games_played, delta, nu, sigma, winner_elo, loser_elo, outcome):
    k_i = delta / (games_played + nu) / sigma
    return k_i * (outcome - 1 / (1 + 10 ** ((loser_elo - winner_elo) / 400)))

def update_elo_scores_538(df, elo_scores, delta, nu, sigma):
    for _, row in df.iterrows():
        winner_id, loser_id = row['winner_id'], row['loser_id']
        winner_elo, loser_elo = elo_scores.loc[winner_id], elo_scores.loc[loser_id]
        outcome = row['higher_rank_won']
        games_played = row['match_num']

        elo_change = fivethirtyeight_model_update(games_played, delta, nu, sigma, winner_elo, loser_elo, outcome)
        elo_scores.loc[winner_id] += elo_change
        elo_scores.loc[loser_id] -= elo_change

    return elo_scores

class FivethirtyeightModel:
    def __init__(self, delta=100, nu=5, sigma=0.1):
        self.delta = delta
        self.nu = nu
        self.sigma = sigma

    def fit(self, X, y=None):
        self.elo_scores = initialize_elo_scores(X, 1500)
        self.elo_scores = update_elo_scores_538(X, self.elo_scores, self.delta, self.nu, self.sigma)
        return self.elo_scores

    def set_params(self, **params):
        self.delta = params.get('delta', self.delta)
        self.nu = params.get('nu', self.nu)
        self.sigma = params.get('sigma', self.sigma)
        return self

    def get_params(self, deep=True):
        return {'delta': self.delta, 'nu': self.nu, 'sigma': self.sigma}