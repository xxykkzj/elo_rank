import pandas as pd
import glob

def prepare_data(data_path):
    files = glob.glob(data_path + "atp_matches_*.csv")
    raw_matches = pd.concat((pd.read_csv(file) for file in files), ignore_index=True)

    raw_matches['tourney_date'] = pd.to_datetime(raw_matches['tourney_date'], format='%Y%m%d', errors='coerce')
    raw_matches.dropna(subset=['tourney_date'], inplace=True)

    matches_df = raw_matches[
        ['tourney_date', 'tourney_name', 'surface', 'draw_size', 
         'tourney_level', 'match_num', 'winner_id', 'loser_id', 
         'best_of', 'winner_rank', 'winner_rank_points', 
         'loser_rank', 'loser_rank_points']
    ]

    matches_df['tourney_name'] = matches_df['tourney_name'].astype('category')
    matches_df['surface'] = matches_df['surface'].astype('category')
    matches_df['best_of'] = matches_df['best_of'].astype('category')

    matches_df[['winner_rank', 'loser_rank', 'winner_rank_points', 'loser_rank_points']] = \
        matches_df[['winner_rank', 'loser_rank', 'winner_rank_points', 'loser_rank_points']].apply(pd.to_numeric, errors='coerce')

    matches_df.dropna(subset=['winner_rank', 'loser_rank', 'winner_rank_points', 'loser_rank_points'], inplace=True)

    matches_df[['winner_id', 'loser_id']] = matches_df[['winner_id', 'loser_id']].astype(int)
    matches_df['diff'] = matches_df['winner_rank_points'] - matches_df['loser_rank_points']
    matches_df['higher_rank_won'] = matches_df['winner_rank'] < matches_df['loser_rank']

    return matches_df

def split_data(df, split_date="2019-01-01"):
    split_time = pd.to_datetime(split_date)
    train_df = df[df['tourney_date'] < split_time]
    test_df = df[df['tourney_date'] >= split_time]
    return train_df, test_df
