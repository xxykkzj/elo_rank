import pandas as pd
import numpy as np

def calculate_elo_metrics(matches_subset, elo_scores):
    matches_subset = matches_subset.copy()
    matches_subset['winner_elo'] = elo_scores.loc[matches_subset['winner_id'], 'elo'].values
    matches_subset['loser_elo'] = elo_scores.loc[matches_subset['loser_id'], 'elo'].values
    matches_subset['elo_probs'] = 1 / (1 + 10 ** ((matches_subset['loser_elo'] - matches_subset['winner_elo']) / 400))
    matches_subset['elo_predictions'] = matches_subset['winner_elo'] > matches_subset['loser_elo']

    accuracy = np.mean(matches_subset['elo_predictions'] == matches_subset['higher_rank_won'])
    log_loss = -np.mean(matches_subset['higher_rank_won'] * np.log(matches_subset['elo_probs']) + 
                        (1 - matches_subset['higher_rank_won']) * np.log(1 - matches_subset['elo_probs']))
    calibration = np.sum(matches_subset['elo_probs']) / np.sum(matches_subset['higher_rank_won'])

    return {'accuracy': accuracy, 'log_loss': log_loss, 'calibration': calibration}

def calculate_metrics(train_df, test_df, full_df, elo_scores, model_name):
    train_metrics = calculate_elo_metrics(train_df, elo_scores)
    test_metrics = calculate_elo_metrics(test_df, elo_scores)
    full_metrics = calculate_elo_metrics(full_df, elo_scores)

    validation_stats = pd.DataFrame({
        'model': [model_name] * 3,
        'pred_acc': [train_metrics['accuracy'], test_metrics['accuracy'], full_metrics['accuracy']],
        'log_loss': [train_metrics['log_loss'], test_metrics['log_loss'], full_metrics['log_loss']],
        'calibration': [train_metrics['calibration'], test_metrics['calibration'], full_metrics['calibration']],
        'dataset': ['Training', 'Testing', 'Full Set']
    })

    return validation_stats
