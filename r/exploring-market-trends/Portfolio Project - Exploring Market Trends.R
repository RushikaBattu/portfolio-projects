## Exploring Market Trends - 

#importing libraries
suppressMessages(library(dplyr)) 
options(readr.show_types = FALSE)
library(readr)
library(readxl)
library(stringr)
library(ggplot2)

# Load the datasets
airbnb_price <- read_csv('airbnb_price.csv', show_col_types=FALSE)
airbnb_room_type <- read_excel('airbnb_room_type.xlsx')
airbnb_last_review <- read_tsv('airbnb_last_review.tsv', show_col_types=FALSE)


# Merge the three data frames together into one
listings <- airbnb_price %>%
  inner_join(airbnb_room_type, by = "listing_id") %>%
  inner_join(airbnb_last_review, by = "listing_id")

listings


#dates of the earliest and most recent reviews
review_dates <- listings %>%
  # Convert to date using the format 'Month DD YYYY'
  mutate(last_review_date = as.Date(last_review, format = "%B %d %Y")) %>%
  summarize(first_reviewed = min(last_review_date),
            last_reviewed = max(last_review_date))

review_dates

# Time series plot of listing counts over time
# Convert 'last_review_date' to Date format
listings <- listings %>%
  mutate(last_review_date = as.Date(last_review, format = "%B %d %Y"))

# Count listings by review date
listing_counts <- listings %>%
  group_by(last_review_date) %>%
  summarize(count = n())

# Time series plot of listing counts over time
ggplot(listing_counts, aes(x = last_review_date, y = count)) +
  geom_line(color = "blue") +
  labs(title = "Listing Counts Over Time", x = "Last Review Date", y = "Number of Listings") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


#count of listings tagged as private rooms

private_room_count <- listings %>%
  # Making capitalization consistent
  mutate(room_type = str_to_lower(room_type)) %>%
  count(room_type) %>%
  filter(room_type == "private room") 

# Extract number of rooms
nb_private_rooms <- private_room_count$n
nb_private_rooms


#average listing price

avg_price <- listings %>%
  mutate(price_clean = str_remove(price, " dollars") %>%
           as.numeric()) %>%
  # Take the mean of price_clean
  summarize(avg_price = mean(price_clean)) %>%
  # Convert from a tibble to a single number
  as.numeric()

avg_price


#consolidating the key findings into 1 tibble

review_dates$nb_private_rooms = nb_private_rooms
review_dates$avg_price = round(avg_price, 2)

print(review_dates)