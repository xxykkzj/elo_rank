import numpy as np
import validation as val
import elo_model as elo
import fivethirtyeight_model as fte

def custom_scorer(metrics):
    # Only consider the test set metrics for scoring
    test_metrics = metrics[metrics['dataset'] == 'Testing']
    return 3* test_metrics['pred_acc'].values[0] - test_metrics['log_loss'].values[0]

def manual_grid_search_elo(X_train, X_test, X_full, param_grid):
    best_score = -np.inf
    best_params = None
    
    for k in param_grid['k']:
        elo_scores = elo.initialize_elo_scores(X_full, initial_elo=1500)
        elo_scores = elo.update_elo_scores_elo(X_train, elo_scores, k=k)
        metrics = val.calculate_metrics(X_train, X_test, X_full, elo_scores, "Elo")
        score = custom_scorer(metrics)
        
        if score > best_score:
            best_score = score
            best_params = {'k': k}
    
    return best_params

def manual_grid_search_fte(X_train, X_test, X_full, param_grid):
    best_score = -np.inf
    best_params = None
    
    for delta in param_grid['delta']:
        fte_scores = fte.initialize_elo_scores(X_full, initial_elo=1500)
        fte_scores = fte.update_elo_scores_538(X_train, fte_scores, delta=delta, nu=5, sigma=0.1)
        metrics = val.calculate_metrics(X_train, X_test, X_full, fte_scores, "538")
        score = custom_scorer(metrics)
        
        if score > best_score:
            best_score = score
            best_params = {'delta': delta}
    
    return best_params

# Define the parameter grid
param_grid_elo = {
    'k': np.arange(25,37, 1)
}

param_grid_fte = {
    'delta': np.arange(1, 23, 2)
}

def tune_models(X_train, X_test, X_full):
    best_params_elo = manual_grid_search_elo(X_train, X_test, X_full, param_grid_elo)
    best_params_fte = manual_grid_search_fte(X_train, X_test, X_full, param_grid_fte)
    return best_params_elo, best_params_fte
