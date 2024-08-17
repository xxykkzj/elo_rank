tune_traditional_elo <- function(matches_train_df, matches_test_df, elo_scores, initial_elo = 1500) {
  
  # Initialize an empty data frame to store k values and performance metrics
  results_df <- data.frame(k_factor = numeric(), performance_metric = numeric())
  
  best_k <- 1
  best_metric <- -Inf
  
  for (k in seq(10,20, by = 2)) {
    # Initialize Elo scores for the Elo model
    elo_scores_k <- initialize_elo_scores(matches_train_df, initial_elo)
    
    # Update Elo scores with the current k
    elo_scores_k <- update_elo_scores_elo(matches_train_df, elo_scores_k, k = k)
    
    # Calculate metrics (accuracy and log loss)
    metrics_k <- calculate_metrics(matches_train_df, matches_test_df, matches_df, elo_scores_k, "Elo")
    
    # Extract the accuracy and log_loss for the training set
    accuracy <- metrics_k$pred_acc[metrics_k$dataset == "Training"]
    log_loss <- metrics_k$log_loss[metrics_k$dataset == "Training"]
    
    # Debug: Print out the metrics
    print(paste("k:", k, "Accuracy:", accuracy, "Log Loss:", log_loss))
    
    # Check if metrics are valid
    if (!is.null(accuracy) && !is.null(log_loss)) {
      # Calculate the performance metric: accuracy - log_loss
      performance_metric_k <- accuracy - log_loss/10
      
      # Store the k value and performance metric in the data frame
      results_df <- rbind(results_df, data.frame(k_factor = k, performance_metric = performance_metric_k))
      
      # Update the best metric and corresponding k value if the current metric is better
      if (performance_metric_k > best_metric) {
        best_metric <- performance_metric_k
        best_k <- k
      }
    } else {
      # Debug: Print a message if metrics are not valid
      print(paste("Metrics are invalid for k =", k))
    }
  }
  
  # Plot performance metrics vs k values
  plot <- ggplot(results_df, aes(x = k_factor, y = performance_metric)) +
    geom_line(color = "blue", size = 1.5) +
    geom_vline(xintercept = best_k, linetype = "dashed", color = "red") +
    labs(
      title = "Traditional Elo Model Tuning",
      x = "k Factor",
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
  ggsave("tune_traditional_elo_plot.png", plot = plot, width = 8, height = 6)
  
  return(list(best_k = best_k, best_metric = best_metric, results_df = results_df))
}

tune_538_model <- function(matches_train_df, matches_test_df, elo_scores, initial_elo = 1500, sigma = 0.1) {
  
  # Initialize an empty data frame to store delta, nu, and performance metrics
  results_df <- data.frame(delta = numeric(), nu = numeric(), performance_metric = numeric())
  
  best_delta <- 100
  best_nu <- 5
  best_metric <- -Inf
  
  for (delta in seq(148, 154, by = 1)) {
    for (nu in seq(1, 5, by = 1)) {
      
      # Initialize Elo scores for the FiveThirtyEight model
      elo_scores_538 <- initialize_elo_scores(matches_train_df, initial_elo)
      
      # Update Elo scores with the current delta and nu
      elo_scores_538 <- update_elo_scores_538(matches_train_df, elo_scores_538, delta = delta, nu = nu, sigma = sigma)
      
      # Calculate metrics (accuracy and log loss)
      metrics_538 <- calculate_metrics(matches_train_df, matches_test_df, matches_df, elo_scores_538, "538")
      
      # Extract the accuracy and log_loss for the training set
      accuracy <- metrics_538$pred_acc[metrics_538$dataset == "Training"]
      log_loss <- metrics_538$log_loss[metrics_538$dataset == "Training"]
      
      # Calculate the performance metric: accuracy - log_loss
      performance_metric_538 <- accuracy - log_loss/10
      
      # Debug: Print out the delta, nu, and performance metric values
      print(paste("delta:", delta, "nu:", nu, "Accuracy:", accuracy, "Log Loss:", log_loss, "Performance Metric:", performance_metric_538))
      
      # Store the delta, nu values and performance metrics in the data frame
      results_df <- rbind(results_df, data.frame(delta = delta, nu = nu, performance_metric = performance_metric_538))
      
      # Update the best metric and corresponding delta, nu values if the current metric is better
      if (performance_metric_538 > best_metric) {
        best_metric <- performance_metric_538
        best_delta <- delta
        best_nu <- nu
      }
    }
  }
  print(best_metric)
  
  # Create the heatmap using ggplot2
  heatmap_plot <- ggplot(results_df, aes(x = delta, y = nu, fill = performance_metric)) +
    geom_tile() +
    scale_fill_viridis_c() +
    labs(title = "FiveThirtyEight Model Tuning", x = "Delta", y = "Nu", fill = "Performance Metric") +
    theme_minimal()
  
  # Save the heatmap as a PNG file
  ggsave("tune_538_model_heatmap.png", plot = heatmap_plot, width = 8, height = 6)
  
  return(list(best_delta = best_delta, best_nu = best_nu, best_metric = best_metric, results_df = results_df))
}

tune_glicko <- function(matches_train_df, matches_test_df, glicko_scores, initial_rating = 1500, initial_rd = 350) {
  # Initialize an empty data frame to store c values and performance metrics
  results_df <- data.frame(c_value = numeric(), performance_metric = numeric())
  
  best_c <- 1
  best_metric <- -Inf  
  for (c in seq(50, 70, by = 5)) {
    # Initialize Glicko scores for the Glicko model
    glicko_scores_c <- initialize_glicko_scores(matches_train_df, initial_rating, initial_rd)
    
    # Update Glicko scores with the current c value
    glicko_scores_c <- update_glicko(matches_train_df, glicko_scores_c, c = c)
    
    # Calculate metrics (accuracy and log loss)
    metrics_c <- calculate_glicko_performance(matches_train_df, matches_test_df, glicko_scores_c, "Glicko")  
    
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
