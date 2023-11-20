## Modeling Car Insurance Claim Outcomes - 

# Import required libraries
library(readr)
library(dplyr)
library(glue)
library(yardstick)
library(ggplot2)

# Read in dataset
cars = read_csv('car_insurance.csv')

# View data types
str(cars)

# Missing values per column
colSums(is.na(cars))

# Distribution of credit_score
summary(cars$credit_score)

# Distribution of annual_mileage
summary(cars$annual_mileage)

# Fill missing values with the mean
cars$credit_score[is.na(cars$credit_score)] <- mean(cars$credit_score, na.rm = TRUE)
cars$annual_mileage[is.na(cars$annual_mileage)] <- mean(cars$annual_mileage, na.rm = TRUE)


# Visualize relationship between credit_score and outcome
ggplot(cars, aes(x = credit_score, fill = factor(outcome))) +
  geom_density(alpha = 0.6) +
  labs(title = "Credit Score vs Outcome", x = "Credit Score", y = "Density", fill = "Outcome") +
  scale_fill_manual(values = c("red", "green")) +
  theme_minimal()


# Visualize relationship between annual_mileage and age
ggplot(cars, aes(x = annual_mileage, fill = factor(outcome))) +
  geom_density(alpha = 0.6) +
  labs(title = "Annual Mileage vs Age (Colored by Outcome)", x = "Annual Mileage", y = "Density", fill = "Outcome") +
  scale_fill_manual(values = c("red", "green")) +
  theme_minimal()


# Create a dataframe to store features  
# Exclude columns not required in regression testing
features_df <- data.frame(features = c(names(subset(cars, select = -c(id, outcome)))))
features_df

# Empty vector to store accuracies
accuracies <- c()

# Loop through features

for (col in features_df$features) {
  model <- glm(glue('outcome ~ {col}'), data = cars, family = 'binomial')
  predictions <- round(fitted(model))
  accuracy <- length(which(predictions == cars$outcome)) / length(cars$outcome)
  features_df[which(features_df$features == col), "accuracy"] = accuracy
}

# Find the feature with the largest accuracy
best_feature <- features_df$features[which.max(features_df$accuracy)]
best_accuracy <- max(features_df$accuracy)

# Create best_feature_df
best_feature_df <- data.frame(best_feature, best_accuracy)
best_feature_df


# Line plot to visualize other feature accuracies
ggplot(features_df, aes(x = reorder(features, accuracy), y = accuracy, group = 1)) +
  geom_line(color = "skyblue") +
  geom_point(color = "blue", size = 2) +
  labs(title = "Feature Accuracies", x = "Features", y = "Accuracy") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
