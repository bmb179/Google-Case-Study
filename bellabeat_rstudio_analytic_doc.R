##RSTUIDO ANALYTICAL DOCUMENTATION
##BRIAN BUONAURO
##GOOGLE DATA ANALYTICS CAPSTONE TRACK 1 CASE 2 - BELLABEAT

#Loading the required packages
library(tidyverse)
library(readr)
library(ggplot2)
library(dplyr)

#Designing theme for the visualizations to match Tableau graphs and blog theme
blog_theme <- theme(
  plot.background = element_rect(fill = "#14101b", color = "#14101b"),
  panel.background = element_rect(fill = "#14101b", color = "#14101b"),
  legend.background = element_rect(fill = "#14101b", color = "#14101b"),
  legend.title = element_text(family = "serif", color = "White", face = "bold"),
  legend.text = element_text(family = "serif", color = "White"),
  axis.title = element_text(family = "serif", color = "White", face = "bold"),
  axis.text = element_text(family = "serif", color = "White"),
  plot.title= element_text(family = "serif", color = "White", face = "bold"),
  plot.subtitle= element_text(family = "serif", color = "White")
)

##Heartrate Dataset
#Loading the dataset
heart_bpm_by_user <- read_csv("C:/DIRECTORY/heart_bpm_by_user.csv",
  col_names = TRUE,
  col_types = NULL,
  col_select = NULL,
  trim_ws = TRUE)

#Inspecting dataset
view(heart_bpm_by_user)

#Plotting dataset
heart_bpm_by_user %>% ggplot() +
  geom_point(mapping = aes(x = datetime_by_minute, y = heartrate_bpm, color = id)) +
  labs(x = "Date-Time of Record",
    y = "Heartrate in BPM",
    color = "User ID",
    title = "Heartrate Beats Per Minute (BPM) of 33 Select FitBit Users",
    subtitle = "April 12th - May 12th, 2016"
  ) + blog_theme

#Table statistics for the heartrate dataset
n_distinct(heart_bpm_by_user$id) #Counting users-14
mean(heart_bpm_by_user$heartrate_bpm) #mean 73.61981
sqrt(var(heart_bpm_by_user$heartrate_bpm)) #stddev 16.73585
heart_bpm_by_user %>% filter(heartrate_bpm >= 100) %>% group_by(id) %>% summarise() #Counting users-14
heart_bpm_by_user %>% filter(heartrate_bpm >= 150) %>% group_by(id) %>% summarise() #Counting users-11

##Participation by User Dataset
#Loading the dataset
participation_by_user <- read_csv("C:/DIRECTORY/participation_by_user.csv",
                              col_names = TRUE,
                              col_types = NULL,
                              col_select = NULL,
                              trim_ws = TRUE)

#Inspecting dataset
view(participation_by_user)

#Generating correlations to identify relationships between user decisions
participation_by_user %>% cor(y = NULL, use = "everything")
#Strong Correlations: (>.75)
#intensity feature & step counter feature: 0.79
#calorie counter feature & step counter feature: 0.79
#calorie counter feature & intensity feature: 1.00

#Plotting the three strongest correlations
#1 Activity-Intensity and Step-Counting Features
participation_by_user %>% 
  ggplot(mapping = aes(x = intensity_participation_rate, y = steps_participation_rate)) +
  geom_point(color = "light blue") + geom_smooth(method=lm) + 
  labs(x = "Activity-Intensity Feature Participation Rate (%)",
       y = "Step-Counting Feature Participation Rate (%)",
       title = "Relationship Between User Utilization of the Activity-Intensity and Step-Counting Features",
       subtitle = "April 12th - May 12th, 2016") + blog_theme
#2 Activity-Intensity and Calorie-Counting Features - no spread, perfect correlation
participation_by_user %>% 
  ggplot(mapping = aes(x = intensity_participation_rate, y = calorie_participation_rate)) +
  geom_point(color = "light blue") + geom_smooth(method=lm) + 
  labs(x = "Activity-Intensity Feature Participation Rate (%)",
       y = "Calorie-Counting Feature Participation Rate (%)",
       title = "Relationship Between User Utilization of the Activity-Intensity and Calorie-Counting Features",
       subtitle = "April 12th - May 12th, 2016") + blog_theme
#3 Calorie-Counting and Step-Counting Features
participation_by_user %>% 
  ggplot(mapping = aes(x = calorie_participation_rate, y = steps_participation_rate)) +
  geom_point(color = "light blue") + geom_smooth(method=lm) + 
  labs(x = "Calorie-Counting Feature Participation Rate (%)",
       y = "Step-Counting Feature Participation Rate (%)",
       title = "Relationship Between User Utilization of the Calorie-Counting and Step-Counting Features",
       subtitle = "April 12th - May 12th, 2016") + blog_theme

##Merged User Info Dataset
#Loading the dataset
total_daily_merged <- read_csv("C:/DIRECTORY/total_daily_merged.csv",
                               col_names = TRUE,
                               col_types = NULL,
                               col_select = NULL,
                               trim_ws = TRUE)

#Inspecting dataset
view(total_daily_merged)

#Generating correlations to identify relationships between activities to compare to prev findings
#Selecting all columns besides the date column
total_daily_merged %>% select(1,3,4,5,6,7,8,9,10,11) %>% cor(y = NULL, use = "everything")
#Strong Correlations: (>.75)
#Sedentary Minutes and Minutes of Sleep: -0.85
#Plotting
total_daily_merged %>% 
  ggplot(mapping = aes(x = corrected_minutes_asleep, y = sedentary_mins)) +
  geom_point(color = "light blue") + geom_smooth(method=lm) + 
  labs(x = "Minutes of Sleep",
       y = "Minutes of Sedentary Activity",
       title = "Relationship Between Minutes of Sleep and Minutes of Sedentary Activity",
       subtitle = "April 12th - May 12th, 2016") + blog_theme
