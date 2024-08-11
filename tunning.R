tune_elo_model <- function(matches_train_df, matches_test_df, elo_scores, initial_elo = 1500) {
  
  best_k <- 10
  best_accuracy <- -Inf
  accuracy_metrics <- c()
  
  for (k in 10:100) {
    # Initialize Elo scores
    elo_scores <- initialize_elo_scores(matches_train_df, initial_elo)
    
    # Update Elo scores with the current k
    elo_scores <- update_elo_scores_elo(matches_train_df, elo_scores, k = k)
    
    # Calculate accuracy
    metrics <- calculate_metrics(matches_train_df, matches_test_df, matches_df, elo_scores, "Elo")
    accuracy <- metrics$accuracy
    
    # Store the accuracy metric
    accuracy_metrics <- c(accuracy_metrics, accuracy)
    
    # Update the best accuracy and corresponding k value if the current accuracy is better
    if (accuracy > best_accuracy) {
      best_accuracy <- accuracy
      best_k <- k
    }
  }
  
  # Plot accuracy vs k values
  plot(10:100, accuracy_metrics, type = "l", col = "blue", lwd = 2,
       xlab = "k Factor", ylab = "Accuracy",
       main = "Elo Model Tuning - Accuracy vs k Factor")
  abline(v = best_k, col = "red", lty = 2)  # Mark the best k
  
  return(list(best_k = best_k, best_accuracy = best_accuracy, accuracy_metrics = accuracy_metrics))
}
