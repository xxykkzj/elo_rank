import pandas as pd

def prepare_data(file_path):
    # Load the data
    matches_df = pd.read_csv(file_path)

    #Extract strings
    matches_df['tourney_date'] = matches_df['tourney_date'].astype(str).str.extract(r'(\d{4}\d{2}\d{2})')[0]
    matches_df['tourney_date'] = pd.to_datetime(matches_df['tourney_date'], format='%Y%m%d', errors='coerce')

    # Determine higher-ranked player and whether they won
    matches_df['higher_rank'] = matches_df[['winner_rank', 'loser_rank']].min(axis=1)
    matches_df['higher_rank_won'] = matches_df.apply(
        lambda row: row['winner_rank'] < row['loser_rank'], axis=1).astype(int)

    return matches_df

def split_data(matches_df, split_ratio=0.8):
    matches_df = matches_df.sort_values(by='tourney_date').reset_index(drop=True)
    split_index = int(len(matches_df) * split_ratio)
    matches_train_df = matches_df.iloc[:split_index]
    matches_test_df = matches_df.iloc[split_index:]
    return matches_train_df, matches_test_df
