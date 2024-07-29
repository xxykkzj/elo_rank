import numpy as np
from sklearn.model_selection import GridSearchCV
import validation as val
import elo_model as elo
import fivethirtyeight_model as fte

# Custom scoring function
def custom_scorer(estimator, X, y):
    elo_scores_temp = estimator.fit(X, y)
    metrics = val.calculate_elo_metrics(X, elo_scores_temp)
    score = metrics['accuracy'] - metrics['log_loss']
    return score

# Function to perform grid search for Elo model
def tune_elo_model(X, param_grid):
    elo_model = elo.EloModel()
    grid_search = GridSearchCV(estimator=elo_model, param_grid=param_grid, scoring=custom_scorer, cv=5)
    grid_search.fit(X)
    return grid_search.best_params_

# Function to perform grid search for FiveThirtyEight model
def tune_fte_model(X, param_grid):
    fte_model = fte.FivethirtyeightModel()
    grid_search = GridSearchCV(estimator=fte_model, param_grid=param_grid, scoring=custom_scorer, cv=5)
    grid_search.fit(X)
    return grid_search.best_params_

# Define the parameter grid
param_grid_elo = {
    'k': np.arange(10, 31, 1)  # Smaller intervals for k
}

param_grid_fte = {
    'delta': np.arange(20, 101, 5)  # Smaller intervals for delta
}

def tune_models(X):
    best_params_elo = tune_elo_model(X, param_grid_elo)
    best_params_fte = tune_fte_model(X, param_grid_fte)
    return best_params_elo, best_params_fte

# Custom scoring function
def custom_scorer(estimator, X, y):
    elo_scores_temp = estimator.fit(X, y)
    metrics = val.calculate_elo_metrics(X, elo_scores_temp)
    score = metrics['accuracy'] - metrics['log_loss']
    return score

# Function to perform grid search for Elo model
def tune_elo_model(X, param_grid):
    elo_model = elo.EloModel()
    grid_search = GridSearchCV(estimator=elo_model, param_grid=param_grid, scoring=custom_scorer, cv=5)
    grid_search.fit(X)
    return grid_search.best_params_

# Function to perform grid search for FiveThirtyEight model
def tune_fte_model(X, param_grid):
    fte_model = fte.FivethirtyeightModel()
    grid_search = GridSearchCV(estimator=fte_model, param_grid=param_grid, scoring=custom_scorer, cv=5)
    grid_search.fit(X)
    return grid_search.best_params_

# Define the parameter grid
param_grid_elo = {
    'k': np.arange(10, 31, 1)  # Smaller intervals for k
}

param_grid_fte = {
    'delta': np.arange(20, 101, 5)  # Smaller intervals for delta
}

def tune_models(X):
    best_params_elo = tune_elo_model(X, param_grid_elo)
    best_params_fte = tune_fte_model(X, param_grid_fte)
    return best_params_elo, best_params_fte