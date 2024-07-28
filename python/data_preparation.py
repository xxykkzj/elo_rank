import pandas as pd


def split_data(df, split_date='2019-01-01'):
    # Convert tourney_date to datetime and handle errors
    df['tourney_date'] = pd.to_datetime(df['tourney_date'], format='%Y%m%d', errors='coerce')
    
    # Debug statement to check the data types and any potential issues with date conversion
    print("Data types after conversion:\n", df.dtypes)
    print("Summary of tourney_date column:\n", df['tourney_date'].describe())
    
    # Drop rows where tourney_date could not be converted
    df = df.dropna(subset=['tourney_date'])
    
    # Split the data into training and testing sets
    split_date = pd.to_datetime(split_date)
    train_df = df[df['tourney_date'] < split_date]
    test_df = df[df['tourney_date'] >= split_date]
    return train_df, test_df
