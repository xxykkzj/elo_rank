tune_elo_model <- function(matches_train_df, matches_test_df, elo_scores, initial_elo = 1500) {
  
  # Initialize an empty data frame to store k values and performance metrics
  results_df <- data.frame(k_factor = numeric(), performance_metric = numeric())
  
  best_k <- 10
  best_metric <- -Inf
  
  for (k in 10:100) {
    # Initialize Elo scores
    elo_scores <- initialize_elo_scores(matches_train_df, initial_elo)
    
    # Update Elo scores with the current k
    elo_scores <- update_elo_scores_elo(matches_train_df, elo_scores, k = k)
    
    # Calculate metrics (accuracy and log loss)
    metrics <- calculate_metrics(matches_train_df, matches_test_df, matches_df, elo_scores, "Elo")
    
    # Calculate the performance metric: accuracy - log_loss
    performance_metric <- metrics$accuracy - metrics$log_loss
    
    # Store the k value and performance metric in the data frame
    results_df <- rbind(results_df, data.frame(k_factor = k, performance_metric = performance_metric))
    
    # Update the best metric and corresponding k value if the current metric is better
    if (performance_metric > best_metric) {
      best_metric <- performance_metric
      best_k <- k
    }
  }
  
  # Plot performance metrics vs k values using the data frame
  plot(results_df$k_factor, results_df$performance_metric, type = "l", col = "blue", lwd = 2,
       xlab = "k Factor", ylab = "Performance Metric",
       main = "Elo Model Tuning")
  abline(v = best_k, col = "red", lty = 2)  # Mark the best k
  
  return(list(best_k = best_k, best_metric = best_metric, results_df = results_df))
}
