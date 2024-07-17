import matplotlib.pyplot as plt
import seaborn as sns

def generate_plots(elo_scores, elo_scores_538):
    # Sample code to plot Elo ratings
    plt.figure(figsize=(10, 6))
    sns.lineplot(data=elo_scores.reset_index(), x='player_id', y='elo', label='Elo')
    sns.lineplot(data=elo_scores_538.reset_index(), x='player_id', y='elo', label='538 Elo')
    plt.title('Elo Ratings')
    plt.xlabel('Player ID')
    plt.ylabel('Elo Score')
    plt.legend()
    plt.savefig('elo_ratings_comparison.png')
    plt.show()
