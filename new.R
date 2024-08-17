tune_glicko <- function(matches_train_df, matches_test_df, glicko_scores, initial_rating = 1500, initial_rd = 350) {
  # Initialize an empty data frame to store c values and performance metrics
  results_df <- data.frame(c_value = numeric(), performance_metric = numeric())
  
  best_c <- 1
  best_metric <- -Inf

  for (c in seq(50, 70, by = 5)) {
    # Initialize Glicko scores for the Glicko model
    glicko_scores_c <- initialize_glicko_scores(matches_train_df, initial_rating, initial_rd)
    print("1")
    # Update Glicko scores with the current c value
    glicko_scores_c <- update_glicko(matches_train_df, glicko_scores_c, c = c)
    print("2")
    # Calculate metrics (accuracy and log loss)
    metrics_c <- calculate_glicko_performance(matches_train_df, matches_test_df, glicko_scores_c, "Glicko")  
    print("3")
    # Extract the accuracy and log_loss for the training set
    accuracy <- metrics_c$pred_acc[metrics_c$dataset == "Training"]
    log_loss <- metrics_c$log_loss[metrics_c$dataset == "Training"]
    
    # Debug: Print out the metrics
    print(paste("c:", c, "Accuracy:", accuracy, "Log Loss:", log_loss))
    
    # Check if metrics are valid
    if (!is.null(accuracy) && !is.null(log_loss)) {
      # Calculate the performance metric: accuracy - log_loss/10
      performance_metric_c <- accuracy - log_loss / 10
      
      # Store the c value and performance metric in the data frame
      results_df <- rbind(results_df, data.frame(c_value = c, performance_metric = performance_metric_c))
      
      # Update the best metric and corresponding c value if the current metric is better
      if (performance_metric_c > best_metric) {
        best_metric <- performance_metric_c
        best_c <- c
      }
    } else {
      # Debug: Print a message if metrics are not valid
      print(paste("Metrics are invalid for c =", c))
    }
  }
  
  # Plot performance metrics vs c values
  plot <- ggplot(results_df, aes(x = c_value, y = performance_metric)) +
    geom_line(color = "blue", size = 1.5) +
    geom_vline(xintercept = best_c, linetype = "dashed", color = "red") +
    labs(
      title = "Glicko Model Tuning",
      x = "c Value",
      y = "Performance Metric (Accuracy - 0.1 Log Loss)"
    ) +
    theme_minimal(base_size = 16) +  # Increased base font size for better readability
    theme(
      plot.title = element_text(size = 20, face = "bold"),
      axis.title.x = element_text(size = 18),
      axis.title.y = element_text(size = 18),
      axis.text.x = element_text(size = 14),
      axis.text.y = element_text(size = 14)
    )
  
  # Save the plot as a PNG file
  ggsave("tune_glicko_plot.png", plot = plot, width = 8, height = 6)
  
  return(list(best_c = best_c, best_metric = best_metric, results_df = results_df))
}
