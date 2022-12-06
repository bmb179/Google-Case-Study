--SQL ANALYTICAL DOCUMENTATION
--BRIAN BUONAURO
--GOOGLE DATA ANALYTICS CAPSTONE TRACK 1 CASE 2 - BELLABEAT
--Activity statistics for step counter based on days of the week
SELECT to_char(activity_date, 'dy'), count(id) AS total_records, 
       sum(total_steps) AS total_steps, round(sum(total_steps)/count(id), 0) AS steps_per_person
FROM clean_daily_activity_merged
GROUP BY to_char(activity_date, 'dy')
ORDER BY CASE WHEN to_char(activity_date, 'dy') = 'mon' THEN 1
              WHEN to_char(activity_date, 'dy') = 'tue' THEN 2
              WHEN to_char(activity_date, 'dy') = 'wed' THEN 3
              WHEN to_char(activity_date, 'dy') = 'thu' THEN 4
              WHEN to_char(activity_date, 'dy') = 'fri' THEN 5
              WHEN to_char(activity_date, 'dy') = 'sat' THEN 6 ELSE 7 
END ASC;
--custom filter to sort the days of the week that are in text format in order
--Ready for export into Tableau
--Name: activity_day_of_week.csv

--List of users for heartrate feature.
CREATE OR REPLACE VIEW heartrate_unique_ids
AS SELECT DISTINCT id FROM heartrate_seconds;
--Saving as a view for easier access in the future.

--Generating beats per minute statistics from the heartrate_seconds data to be plotted easier
SELECT id, date_trunc('minute', activity_datetime) AS datetime_by_minute, round(avg(heartrate), 2) AS heartrate_bpm
FROM heartrate_seconds
GROUP BY datetime_by_minute, id
ORDER BY datetime_by_minute, id;
--Time was rounded to the previous minute rather than the nearest minute
-----since all seconds contained in a minute belong to the most recent minute to occur.
--Example: 01:33:00-01:33:59 all seconds in this interval belong to the 33rd minute of the 1st hour.
--Ready for export into R Studio
--Name: heart_bpm_by_user.csv

-----------------------------------------
--How many users are there total?

SELECT DISTINCT activity.id AS activity_id, 
       CASE WHEN sleep.id IS NULL THEN 0
            ELSE 1 END AS sleep_id, 
       CASE WHEN heartrate.id IS NULL THEN 0 
            ELSE 1 END AS heartrate_id, 
       CASE WHEN weight.id IS NULL THEN 0
            ELSE 1 END AS weight_id
FROM clean_daily_activity_merged AS activity
FULL OUTER JOIN heartrate_unique_ids AS heartrate ON heartrate.id = activity.id
FULL OUTER JOIN sleep_day_cleaned AS sleep ON sleep.id = activity.id
FULL OUTER JOIN weight_log AS weight ON weight.id = activity.id
ORDER BY activity_id;
--33 users total, all of them appear at least once in the daily_activity_merged dataset
--A value of 1 indicates participation at least once, a 0 indicates never used the feature
--Ready for export--not used in final analysis because the last script in this file represents this statistic better

SELECT count(*) AS total_participants, 
       round(count(activity_id)::numeric/count(*) , 4)*100 AS activity_participation_rate,
       round(count(sleep_id)::numeric/count(*)    , 4)*100 AS sleep_participation_rate,
       round(count(heartrate_id)::numeric/count(*), 4)*100 AS heartrate_participation_rate,
       round(count(weight_id)::numeric/count(*)   , 4)*100 AS weight_participation_rate
FROM (SELECT DISTINCT activity.id AS activity_id, sleep.id AS sleep_id, 
                      heartrate.id AS heartrate_id, weight.id AS weight_id
      FROM clean_daily_activity_merged AS activity
      FULL OUTER JOIN heartrate_unique_ids AS heartrate ON heartrate.id = activity.id
      FULL OUTER JOIN sleep_day_cleaned AS sleep ON sleep.id = activity.id
      FULL OUTER JOIN weight_log AS weight ON weight.id = activity.id) AS user_data;
--Generating participation statistics for export by category
--Ready for export into Tableau
--Name: participation_by_category.csv

-------------------------------------------------------------------
--Generating participation statistics for export by user and day

WITH table_stats AS (
        SELECT count(DISTINCT id) AS total_participants, --33 participants
               max(activity_date) AS end_date, --5/12/16
               min(activity_date) AS start_date, --4/12/16
               max(activity_date) - min(activity_date)+1 AS day_length_of_dataset --add one to make inclusive of the first day, 31 days
        FROM clean_daily_activity_merged)
SELECT activity.id,
       round(sum(CASE WHEN activity.total_steps > 0 THEN 1 ELSE 0 END)::numeric/day_length_of_dataset*100, 2) AS steps_participation_rate,
       round(sum(CASE WHEN (activity.very_active_mins + activity.fairly_active_mins + activity.lightly_active_mins + activity.sedentary_mins) > 0
           THEN 1 ELSE 0 END)::numeric/day_length_of_dataset*100, 2) AS intensity_participation_rate,
       round(sum(CASE WHEN activity.calories > 0 THEN 1 ELSE 0 END)::numeric/day_length_of_dataset*100, 2) AS calorie_participation_rate,
       round(sum(CASE WHEN heartrate_day.heartrate_avg > 0 THEN 1 ELSE 0 END)::numeric/day_length_of_dataset*100, 2) AS heartrate_participation_rate,
       round(sum(CASE WHEN sleep.sleep_records > 0 THEN 1 ELSE 0 END)::numeric/day_length_of_dataset*100, 2) AS sleep_participation_rate,
       round(sum(CASE WHEN weight.weight_avg_lbs > 0 THEN 1 ELSE 0 END)::numeric/day_length_of_dataset*100, 2) AS weightlog_participation_rate
FROM table_stats, clean_daily_activity_merged AS activity
FULL OUTER JOIN (SELECT id, date_trunc('day', activity_datetime) AS datetime_by_day, round(avg(heartrate), 2) AS heartrate_avg
                 FROM heartrate_seconds
                 GROUP BY datetime_by_day, id) AS heartrate_day ON activity.id = heartrate_day.id AND activity.activity_date = heartrate_day.datetime_by_day
FULL OUTER JOIN sleep_day_cleaned AS sleep ON activity.id = sleep.id AND activity.activity_date = sleep.activity_hour
FULL OUTER JOIN (SELECT id, date_trunc('day', activity_datetime) AS datetime_by_day, round(avg(weight_lbs), 2) AS weight_avg_lbs
                 FROM weight_log
                 GROUP BY id, datetime_by_day) AS weight ON activity.id = weight.id AND activity.activity_date = weight.datetime_by_day
GROUP BY activity.id, day_length_of_dataset;
--Ready for export into R Studio
--Name: participation_by_user.csv

SELECT activity.id, activity.activity_date, activity.total_steps, activity.very_active_mins, activity.fairly_active_mins, 
       activity.lightly_active_mins, activity.sedentary_mins, activity.calories, 
       CASE WHEN heartrate_day.heartrate_avg IS NULL THEN 0 ELSE heartrate_day.heartrate_avg END AS corrected_heartrate_avg, --getting rid of null rows
       CASE WHEN sleep.minutes_asleep        IS NULL THEN 0 ELSE sleep.minutes_asleep        END AS corrected_minutes_asleep, 
       CASE WHEN weight.weight_avg_lbs       IS NULL THEN 0 ELSE weight.weight_avg_lbs       END AS corrected_weight_avg_lbs
FROM clean_daily_activity_merged AS activity
FULL OUTER JOIN (SELECT id, date_trunc('day', activity_datetime) AS datetime_by_day, round(avg(heartrate), 2) AS heartrate_avg
                 FROM heartrate_seconds
                 GROUP BY datetime_by_day, id) AS heartrate_day ON activity.id = heartrate_day.id AND activity.activity_date = heartrate_day.datetime_by_day
FULL OUTER JOIN sleep_day_cleaned AS sleep ON activity.id = sleep.id AND activity.activity_date = sleep.activity_hour
FULL OUTER JOIN (SELECT id, date_trunc('day', activity_datetime) AS datetime_by_day, round(avg(weight_lbs), 2) AS weight_avg_lbs
                 FROM weight_log
                 GROUP BY id, datetime_by_day) AS weight ON activity.id = weight.id AND activity.activity_date = weight.datetime_by_day;
--Ready for export into R Studio
--Name: total_daily_merged.csv
