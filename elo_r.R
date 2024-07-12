## -----------------------------------------------------------------------------
pacman::p_load(tidyverse, lubridate, patchwork, knitr, welo)


## -----------------------------------------------------------------------------
# Create a vector of file names to read
setwd("C:/Users/biand/Downloads/tennis_atp/")
files <- str_glue("atp_matches_{2010:2019}.csv")

# Read each file and combine them into one data frame
raw_matches <- map_dfr(files, ~read_csv(.x, show_col_types = FALSE))

# Process the data frame
matches_df <- raw_matches %>%
  select(tourney_date,
         tourney_name,
         surface,
         draw_size,
         tourney_level,
         match_num,
         winner_id,
         loser_id,
         best_of,
         winner_rank,
         winner_rank_points,
         loser_rank,
         loser_rank_points) %>%
  mutate_at(vars(tourney_name, surface, best_of), as.factor) %>%
  mutate_at(vars(winner_id, loser_id), as.integer) %>%
  mutate(tourney_date = ymd(tourney_date))
tail(matches_df)


## -----------------------------------------------------------------------------
filtered_df <- matches_df %>% 
  filter(winner_id == '105554' | loser_id == '105554' | winner_id == '103852' | loser_id == '103852')

#filtered_df
         
filtered_df <- filtered_df %>%
  mutate(player_rank = ifelse(winner_id == '105554' | winner_id == '103852', winner_rank, loser_rank),
         player_id = ifelse(winner_id == '105554' | winner_id == '103852', winner_id, loser_id))

# Convert player_id to a factor with custom labels
filtered_df$player_id <- factor(filtered_df$player_id, 
                                levels = c('105554', '103852'), 
                                labels = c('Daniel Evans', 'Feliciano Lopez'))

# Now let's plot the rankings over time using ggplot
ggplot(filtered_df, aes(x = tourney_date, y = player_rank, group = player_id, color = player_id)) +
  geom_line() +
  scale_y_reverse() + # Reverse the scale to have the best rank at the top
  scale_color_discrete(name = "Player", labels = c('Daniel Evans', 'Feliciano Lopez')) + # Custom legend for player names
  labs(title = "Rankings of Two Players in 2010-2019",
       x = "Year",
       y = "Ranking") +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(size = 20),  # Adjust title font size
    axis.title.x = element_text(size = 15),  # Adjust x-axis label font size
    axis.title.y = element_text(size = 15),  # Adjust y-axis label font size
    axis.text.x = element_text(size = 12),   # Adjust x-axis tick label font size
    axis.text.y = element_text(size = 12),   # Adjust y-axis tick label font size
    legend.text = element_text(size = 12),   # Adjust legend text font size
    legend.title = element_text(size = 15)   # Adjust legend title font size
  )
ggsave("plot0.png")

## -----------------------------------------------------------------------------
matches_df <- matches_df %>%
  mutate(loser_rank = replace_na(loser_rank, 100000),
         winner_rank = replace_na(winner_rank, 100000))

matches_df <- na.omit(matches_df)


## -----------------------------------------------------------------------------
matches_df <- matches_df %>%
  mutate(higher_rank_won = winner_rank < loser_rank) %>%
  mutate(higher_rank_points = winner_rank_points * (higher_rank_won) +
           loser_rank_points * (1 - higher_rank_won)) %>%
  mutate(lower_rank_points = winner_rank_points * (1 - higher_rank_won) +
           loser_rank_points * (higher_rank_won)) %>%
  mutate(diff = higher_rank_points - lower_rank_points)


## -----------------------------------------------------------------------------
matches_df <- matches_df |>
mutate(diff = higher_rank_points - lower_rank_points)

## -----------------------------------------------------------------------------
# Split data into training and testing sets
split_time <- ymd("2019-01-01")#should be 2019 but set as 2017
matches_train_df <- filter(matches_df, tourney_date < split_time)
matches_test_df <- filter(matches_df, tourney_date >= split_time)


## -----------------------------------------------------------------------------
N_train <- nrow(matches_train_df)
naive_accuracy_train <- mean(matches_train_df$higher_rank_won)
w_train <- matches_train_df$higher_rank_won
pi_naive_train <- naive_accuracy_train
log_loss_naive_train <- -1 / N_train * sum(w_train * log(pi_naive_train) + (1 - w_train) * log(1 - pi_naive_train))
calibration_naive_train <- pi_naive_train * N_train / sum(w_train)


## -----------------------------------------------------------------------------
N_test <- nrow(matches_test_df)
naive_accuracy_test <- mean(matches_test_df$higher_rank_won)
w_test <- matches_test_df$higher_rank_won
pi_naive_test <- naive_accuracy_test
log_loss_naive_test <- -1 / N_test * sum(w_test * log(pi_naive_test) + (1 - w_test) * log(1 - pi_naive_test))
calibration_naive_test <- pi_naive_test * N_test / sum(w_test)


## -----------------------------------------------------------------------------
# Calculate the number of observations in the full dataset
N_full <- nrow(matches_df)

# Calculate accuracy for the naive model on the full dataset
naive_accuracy_full <- mean(mean(matches_df$higher_rank_won))

# Calculate log-loss for the naive model on the full dataset
# Here, the predicted probability is the naive_accuracy (assuming all predictions use the mode of the outcome)
w_full <- matches_df$higher_rank_won
pi_naive_full <- naive_accuracy_full
log_loss_naive_full <- -1 / N_full* sum(w_full * log(pi_naive_full) + (1 - w_full) * log(1 - pi_naive_full))

# Calculate calibration for the naive model on the full dataset
calibration_naive_full <- naive_accuracy_full * N_full / sum(matches_df$higher_rank_won)

# Add new row of naive model statistics to the validation_stats dataframe
validation_stats <- tibble(
    model = "naive",
    pred_acc = naive_accuracy_full,
    log_loss = log_loss_naive_full,
    calibration = calibration_naive_full,
    dataset = "Full Set"
  )

# Display the validation statistics as a table using knitr's kable
kable(validation_stats)



## -----------------------------------------------------------------------------
validation_stats_train <- tibble(
  model = "naive",
  pred_acc = naive_accuracy_train,
  log_loss = log_loss_naive_train,
  calibration = calibration_naive_train,
  dataset = "training"
)

validation_stats_test <- tibble(
  model = "naive",
  pred_acc = naive_accuracy_test,
  log_loss = log_loss_naive_test,
  calibration = calibration_naive_test,
  dataset = "testing"
)


## -----------------------------------------------------------------------------
validation_stats <- bind_rows(validation_stats_train, validation_stats_test)


## -----------------------------------------------------------------------------
print(knitr::kable(validation_stats))


## -----------------------------------------------------------------------------
fit_diff <- glm(
  higher_rank_won ~ diff + 0,
  data = matches_train_df,
  family = binomial(link = 'logit')
)
summary(fit_diff)

## -----------------------------------------------------------------------------
tmp_diff <- tibble(diff = c(0:10000))
prob_diff <- tibble(prob = predict(fit_diff, tmp_diff, type = 'response'))
tmp_df <- tibble(diff = tmp_diff$diff, prob = prob_diff$prob)
ggplot(aes(x = diff, y = prob), data = tmp_df)+
  geom_line() +
  xlab("player's difference in points") +
  ylab("probability of the higher ranked overcome") +
  theme_light()  +
  theme(
    axis.title.x = element_text(size = 18),  
    axis.title.y = element_text(size = 18)   
  )

ggsave("plot1.png", width = 5, height = 4)

## -----------------------------------------------------------------------------
probs_of_winning_train <- predict(fit_diff, matches_train_df, type = "response")


## -----------------------------------------------------------------------------
preds_logistic_train <- ifelse(probs_of_winning_train > 0.5, 1, 0)


## -----------------------------------------------------------------------------
accuracy_logistic_train <- mean(preds_logistic_train == matches_train_df$higher_rank_won)
w_train <- matches_train_df$higher_rank_won
log_loss_logistic_train <- -1 / nrow(matches_train_df) * sum(w_train * log(probs_of_winning_train) +
                                                               (1 - w_train) * log(1 - probs_of_winning_train), na.rm = TRUE)
calibration_logistic_train <- sum(probs_of_winning_train) / sum(w_train)


## -----------------------------------------------------------------------------
validation_stats_train <- tibble(
  model = "logistic",
  pred_acc = accuracy_logistic_train,
  log_loss = log_loss_logistic_train,
  calibration = calibration_logistic_train,
  dataset = "training"
)


## -----------------------------------------------------------------------------
probs_of_winning_test <- predict(fit_diff, matches_test_df, type = "response")


## -----------------------------------------------------------------------------
preds_logistic_test <- ifelse(probs_of_winning_test > 0.5, 1, 0)


## -----------------------------------------------------------------------------
accuracy_logistic_test <- mean(preds_logistic_test == matches_test_df$higher_rank_won)
w_test <- matches_test_df$higher_rank_won
log_loss_logistic_test <- -1 / nrow(matches_test_df) * sum(w_test * log(probs_of_winning_test) +
                                                             (1 - w_test) * log(1 - probs_of_winning_test), na.rm = TRUE)
calibration_logistic_test <- sum(probs_of_winning_test) / sum(w_test)


## -----------------------------------------------------------------------------
validation_stats_test <- tibble(
  model = "logistic",
  pred_acc = accuracy_logistic_test,
  log_loss = log_loss_logistic_test,
  calibration = calibration_logistic_test,
  dataset = "testing"
)


## -----------------------------------------------------------------------------
N <- nrow(matches_df)
naive_accuracy <- mean(matches_df$higher_rank_won)

# Predict the probabilities of winning
probs_of_winning <- predict(fit_diff, matches_df, type = "response")

# Convert probabilities to binary predictions using a threshold of 0.5
preds_logistic <- ifelse(probs_of_winning > 0.5, 1, 0)

# Calculate the accuracy of the logistic model
accuracy_logistic <- mean(preds_logistic == matches_df$higher_rank_won)

# Define 'w' as the binary outcome of higher rank winning
w <- matches_df$higher_rank_won

# Calculate the logistic model's log-loss
log_loss_logistic <- -1 / N * sum(w * log(probs_of_winning) + (1 - w) * log(1 - probs_of_winning), na.rm = TRUE)

# Calculate calibration of the logistic model
calibration_logistic <- sum(probs_of_winning) / sum(w)

# Add new row of logistic model statistics to the validation_stats dataframe
validation_stats <- validation_stats |>
  add_row(
    model = "logistic",
    pred_acc = accuracy_logistic,
    log_loss = log_loss_logistic,
    calibration = calibration_logistic
  )




## -----------------------------------------------------------------------------
validation_stats <- bind_rows(validation_stats_train, validation_stats_test)


## -----------------------------------------------------------------------------
print(knitr::kable(validation_stats))


## -----------------------------------------------------------------------------
initial_elo <- 1500
elo_scores <- data.frame(player_id = unique(c(matches_df$winner_id, matches_df$loser_id)),
                         elo = rep(initial_elo, n_distinct(c(matches_df$winner_id, matches_df$loser_id))))
print(head(elo_scores))


## -----------------------------------------------------------------------------
k_factor_model_update <- function(k, winner_elo, loser_elo, outcome) {
  elo_change <- k * (outcome - 1 / (1 + 10^((loser_elo - winner_elo) / 400)))
  return(elo_change)
}


## -----------------------------------------------------------------------------
fivethirtyeight_model_update <- function(games_played, delta, nu, sigma, winner_elo, loser_elo, outcome) {
  k_i <- delta / (games_played + nu) / sigma
  elo_change <- k_i * (outcome - 1 / (1 + 10^((loser_elo - winner_elo) / 400)))
  return(elo_change)
}



## -----------------------------------------------------------------------------
k <- 25
delta <- 100
nu <- 5
sigma <- 0.1


## -----------------------------------------------------------------------------
for (i in 1:nrow(matches_train_df)) {
  match <- matches_train_df[i, ]
  winner_id <- match$winner_id
  loser_id <- match$loser_id
  winner_elo <- elo_scores$elo[elo_scores$player_id == winner_id]
  loser_elo <- elo_scores$elo[elo_scores$player_id == loser_id]
  outcome <- ifelse(match$higher_rank_won == TRUE, 1, 0)
  
  # Update Elo scores based on the K-factor model
  elo_change_k <- k_factor_model_update(k, winner_elo, loser_elo, outcome)
  elo_scores$elo[elo_scores$player_id == winner_id] <- winner_elo + elo_change_k
  elo_scores$elo[elo_scores$player_id == loser_id] <- loser_elo - elo_change_k
  
  # Update Elo scores based on the FiveThirtyEight model
  games_played <- match$match_num
  elo_change_538 <- fivethirtyeight_model_update(games_played, delta, nu, sigma, winner_elo, loser_elo, outcome)
  elo_scores$elo[elo_scores$player_id == winner_id] <- winner_elo + elo_change_538
  elo_scores$elo[elo_scores$player_id == loser_id] <- loser_elo - elo_change_538
}


## -----------------------------------------------------------------------------
for (i in 1:nrow(matches_test_df)) {
  match <- matches_test_df[i, ]
  winner_id <- match$winner_id
  loser_id <- match$loser_id
  winner_elo <- elo_scores$elo[elo_scores$player_id == winner_id]
  loser_elo <- elo_scores$elo[elo_scores$player_id == loser_id]
  outcome <- ifelse(match$higher_rank_won == TRUE, 1, 0)
  
  # Update Elo scores based on the K-factor model
  elo_change_k <- k_factor_model_update(k, winner_elo, loser_elo, outcome)
  elo_scores$elo[elo_scores$player_id == winner_id] <- winner_elo + elo_change_k
  elo_scores$elo[elo_scores$player_id == loser_id] <- loser_elo - elo_change_k
  
  # Update Elo scores based on the FiveThirtyEight model
  games_played <- match$match_num
  elo_change_538 <- fivethirtyeight_model_update(games_played, delta, nu, sigma, winner_elo, loser_elo, outcome)
  elo_scores$elo[elo_scores$player_id == winner_id] <- winner_elo + elo_change_538
  elo_scores$elo[elo_scores$player_id == loser_id] <- loser_elo - elo_change_538
}


## -----------------------------------------------------------------------------
all_players <- unique(c(matches_df$winner_id, matches_df$loser_id))


## -----------------------------------------------------------------------------
elo_scores <- elo_scores[elo_scores$player_id %in% all_players, ]
head(elo_scores)


## -----------------------------------------------------------------------------
matches_train_df <- matches_train_df[matches_train_df$winner_id %in% elo_scores$player_id & matches_train_df$loser_id %in% elo_scores$player_id, ]
matches_test_df <- matches_test_df[matches_test_df$winner_id %in% elo_scores$player_id & matches_test_df$loser_id %in% elo_scores$player_id, ]


## -----------------------------------------------------------------------------
elo_predictions_train <- ifelse(elo_scores$elo[match$winner_id] > elo_scores$elo[match$loser_id], 1, 0)
elo_predictions_test <- ifelse(elo_scores$elo[match$winner_id] > elo_scores$elo[match$loser_id], 1, 0)


## -----------------------------------------------------------------------------
elo_probs_train <- 1 / (1 + 10^((elo_scores$elo[matches_train_df$loser_id] - elo_scores$elo[matches_train_df$winner_id]) / 400))
elo_probs_test <- 1 / (1 + 10^((elo_scores$elo[matches_test_df$loser_id] - elo_scores$elo[matches_test_df$winner_id]) / 400))



## -----------------------------------------------------------------------------
elo_accuracy_train <- mean(elo_predictions_train == matches_train_df$higher_rank_won)
log_loss_elo_train <- -1 / nrow(matches_train_df) * sum(matches_train_df$higher_rank_won * log(elo_probs_train) + (1 - matches_train_df$higher_rank_won) * log(1 - elo_probs_train))
elo_calibration_train <- mean(elo_probs_train)

elo_accuracy_test <- mean(elo_predictions_test == matches_test_df$higher_rank_won)
log_loss_elo_test <- -1 / nrow(matches_test_df) * sum(matches_test_df$higher_rank_won * log(elo_probs_test) + (1 - matches_test_df$higher_rank_won) * log(1 - elo_probs_test))
elo_calibration_test <- mean(elo_probs_test)


## -----------------------------------------------------------------------------
# Function to extract Elo scores for a given player_id
get_elo <- function(player_id, elo_scores) {
  return(elo_scores$elo[match(player_id, elo_scores$player_id)])
}

# Function to calculate Elo performance metrics for a given data subset
calculate_elo_metrics <- function(matches_subset, elo_scores) {
  # Get Elo scores for winners and losers
  winner_elos <- get_elo(matches_subset$winner_id, elo_scores)
  loser_elos <- get_elo(matches_subset$loser_id, elo_scores)

  # Calculate predicted outcomes using the Elo model
  elo_predictions <- ifelse(winner_elos > loser_elos, 1, 0)

  # Calculate probabilities of winning using the Elo scores
  elo_probs <- 1 / (1 + 10 ^ ((loser_elos - winner_elos) / 400))

  # Calculate metrics
  accuracy <- mean(elo_predictions == matches_subset$higher_rank_won)
  log_loss <- -mean(matches_subset$higher_rank_won * log(elo_probs) + 
                    (1 - matches_subset$higher_rank_won) * log(1 - elo_probs))
  ###################calibration <- mean(elo_probs)############
  calibration <- sum(elo_probs) / sum(matches_subset$higher_rank_won)
  # Return a list of metrics
  return(list(accuracy = accuracy, log_loss = log_loss, calibration = calibration))
}

# Calculate metrics for the training set
train_metrics <- calculate_elo_metrics(matches_train_df, elo_scores)

# Calculate metrics for the testing set
test_metrics <- calculate_elo_metrics(matches_test_df, elo_scores)

# Calculate metrics for the full dataset
full_metrics <- calculate_elo_metrics(matches_df, elo_scores)

# Create a tibble to hold all metrics
validation_stats <- tibble(
  model = rep("elo", 3),
  pred_acc = c(train_metrics$accuracy, test_metrics$accuracy, full_metrics$accuracy),
  log_loss = c(train_metrics$log_loss, test_metrics$log_loss, full_metrics$log_loss),
  calibration = c(train_metrics$calibration, test_metrics$calibration, full_metrics$calibration),
  dataset = c("Training", "Testing", "Full Set")
)

# Clear out old data
validation_stats <- validation_stats %>% filter(model == "elo")

# Display the validation statistics
kable(validation_stats)



## -----------------------------------------------------------------------------
# Assuming 'matches_df' is ordered chronologically

# Initialize Elo scores for all players for both models
elo_scores_k <- data.frame(player_id = unique(c(matches_df$winner_id, matches_df$loser_id)),
                           elo = rep(initial_elo, n_distinct(c(matches_df$winner_id, matches_df$loser_id))))

elo_scores_538 <- data.frame(player_id = unique(c(matches_df$winner_id, matches_df$loser_id)),
                             elo = rep(initial_elo, n_distinct(c(matches_df$winner_id, matches_df$loser_id))))

# Initialize a dataframe to store Elo history
elo_history <- data.frame(tourney_date = as.Date(character()), player_id = integer(), 
                          elo_k = numeric(), elo_538 = numeric())

# Parameters for the models
k <- 25
delta <- 100
nu <- 5
sigma <- 0.1

# Update functions defined here

# Iterate through matches and update Elo scores for each model
for (i in 1:nrow(matches_df)) {
  match <- matches_df[i, ]
  winner_id <- match$winner_id
  loser_id <- match$loser_id
  
  # Get current Elo scores
  winner_elo_k <- elo_scores_k$elo[elo_scores_k$player_id == winner_id]
  loser_elo_k <- elo_scores_k$elo[elo_scores_k$player_id == loser_id]
  winner_elo_538 <- elo_scores_538$elo[elo_scores_538$player_id == winner_id]
  loser_elo_538 <- elo_scores_538$elo[elo_scores_538$player_id == loser_id]
  
  # Determine the outcome
  outcome <- match$higher_rank_won
  
  # Update Elo scores using both models
  elo_change_k <- k_factor_model_update(k, winner_elo_k, loser_elo_k, outcome)
  elo_scores_k$elo[elo_scores_k$player_id == winner_id] <- winner_elo_k + elo_change_k
  elo_scores_k$elo[elo_scores_k$player_id == loser_id] <- loser_elo_k - elo_change_k
  
  elo_change_538 <- fivethirtyeight_model_update(match$match_num, delta, nu, sigma, winner_elo_538, loser_elo_538, outcome)
  elo_scores_538$elo[elo_scores_538$player_id == winner_id] <- winner_elo_538 + elo_change_538
  elo_scores_538$elo[elo_scores_538$player_id == loser_id] <- loser_elo_538 - elo_change_538
  
  # If the match involves one of the players of interest, record the Elo score in the history
  if (winner_id %in% c(105554, 103852) | loser_id %in% c(105554, 103852)) {
    elo_history <- rbind(elo_history, data.frame(tourney_date = match$tourney_date, 
                                                 player_id = winner_id, 
                                                 elo_k = winner_elo_k, 
                                                 elo_538 = winner_elo_538))
    elo_history <- rbind(elo_history, data.frame(tourney_date = match$tourney_date, 
                                                 player_id = loser_id, 
                                                 elo_k = loser_elo_k, 
                                                 elo_538 = loser_elo_538))
  }
}

# Filter the history for the two players of interest
elo_history_filtered <- elo_history %>% 
  filter(player_id %in% c(105554, 103852))

# Convert player_id to a factor with custom labels
elo_history_filtered$player_name <- factor(elo_history_filtered$player_id, 
                                           levels = c(105554, 103852), 
                                           labels = c('Daniel Evans', 'Feliciano Lopez'))

# Plot the Elo ratings over time for each model and each player
ggplot(elo_history_filtered, aes(x = tourney_date)) +
  geom_line(aes(y = elo_k, color = player_name, linetype = "K-factor")) +
  geom_line(aes(y = elo_538, color = player_name, linetype = "538 model")) +
  scale_color_manual(values = c('blue', 'orange')) +
  scale_linetype_manual(values = c('solid', 'dashed')) +
  labs(title = "Elo Ratings Over Time",
       x = "Year",
       y = "Elo Rating",
       color = "Player",
       linetype = "Model") +
  theme_minimal()

