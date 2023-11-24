## Analyzing Crime Data - 

# Load required packages
library(tidyverse)
library(lubridate)

# Read datasets and assign to variables
incidents <- read_csv("incidents.csv")
calls <- read_csv("calls-for-service.csv")
print('Done!')

str(incidents)
str(calls)


# Glimpse the structure of both datasets
glimpse(incidents)
glimpse(calls)

# Aggregate the number of reported incidents by date
daily_incidents <- incidents %>% 
  count(Date, sort = TRUE) %>% 
  rename(n_incidents = n)

# Aggregate the number of calls for police service by date
daily_calls <- calls %>% 
  count(Date, sort = TRUE) %>% 
  rename(n_calls = n)


# Join data frames to create a new "mutated" set of information
shared_dates <- inner_join(daily_incidents, daily_calls, by = c("Date" = "Date"))

# Take a glimpse of this new data frame
glimpse(shared_dates)


# Gather into long format using the "Date" column to define observations
plot_shared_dates <- shared_dates %>%
  gather(key = report, value = count, -Date)

# Plot points and regression trend lines
ggplot(plot_shared_dates, aes(x = Date, y = count, color = report)) +
  geom_point() +
  geom_smooth(method = "lm", formula = y ~ x)


# Filter calls to police by shared_dates
calls_shared_dates <- calls %>%
  semi_join(shared_dates, by = c("Date" = "Date"))

# Check the filtering join function 
identical(sort(unique(shared_dates$Date)), sort(unique(calls_shared_dates$Date)))

# Filter recorded incidents by shared_dates
incidents_shared_dates <- incidents %>% 
  semi_join(shared_dates, by = c("Date" = "Date"))


# Create a bar chart of the number of calls for each crime
plot_calls_freq <- calls_shared_dates %>% 
  count(Descript) %>% 
  top_n(15, n) %>% 
  ggplot(aes(x = reorder(Descript, n), y = n)) +
  geom_bar(stat = 'identity') +
  ylab("Count") +
  xlab("Crime Description") +
  ggtitle("Calls Reported Crimes") +
  coord_flip()

# Create a bar chart of the number of reported incidents for each crime
plot_incidents_freq <- incidents_shared_dates %>% 
  count(Descript) %>% 
  top_n(15, n)  %>% 
  ggplot(aes(x = reorder(Descript, n), y = n)) +
  geom_bar(stat = 'identity') +
  ylab("Count") +
  xlab("Crime Description") +
  ggtitle("Incidents Reported Crimes") +
  coord_flip()

# Output the plots
plot_calls_freq
plot_incidents_freq


# Arrange the top 10 locations of called in crimes in a new variable
location_calls <- calls_shared_dates %>%
  filter(Descript == "Auto Boost / Strip") %>% 
  count(Address) %>% 
  arrange(desc(n))%>% 
  top_n(10, n)

# Arrange the top 10 locations of reported incidents in a new variable
location_incidents <- incidents_shared_dates %>%
  filter(Descript == "GRAND THEFT FROM LOCKED AUTO") %>% 
  count(Address) %>% 
  arrange(desc(n))%>% 
  top_n(10, n)

# Output the top locations of each dataset for comparison
location_calls
location_incidents

