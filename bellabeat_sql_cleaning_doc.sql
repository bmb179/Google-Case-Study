--SQL CLEANING DOCUMENTATION
--BRIAN BUONAURO
--GOOGLE DATA ANALYTICS CAPSTONE TRACK 1 CASE 2 - BELLABEAT
--Code will execute without error if the entire script is ran at once
--Fill in correct destination directory of all COPY statements before running

-----------------------------------------DAILY ACTIVITY MERGED TABLE

--Unable to assign a primary key since values in ID column are not unique (data is long not wide)
--NOT NULL constraint added to test for NULLs automatically upon import.
CREATE TABLE IF NOT EXISTS daily_activity_merged(
    id numeric NOT NULL,
    activity_date date NOT NULL,
    total_steps numeric NOT NULL,
    total_distance numeric NOT NULL,
    tracker_distance numeric NOT NULL,
    logged_activities_dist numeric NOT NULL,
    very_active_dist numeric NOT NULL,
    mod_active_dist numeric NOT NULL,
    light_active_dist numeric NOT NULL,
    sedentary_active_dist numeric NOT NULL,
    very_active_mins numeric NOT NULL,
    fairly_active_mins numeric NOT NULL,
    lightly_active_mins numeric NOT NULL,
    sedentary_mins numeric NOT NULL,
    calories numeric NOT NULL);
    
COPY daily_activity_merged
FROM 'C:\DIRECTORY\dailyActivity_merged.csv'
HEADER CSV DELIMITER ',';

SELECT * FROM daily_activity_merged;--full view of data
SELECT count(DISTINCT id) FROM daily_activity_merged;--33 users provided data
SELECT id, activity_date, count(*)
FROM daily_activity_merged
GROUP BY activity_date, id
HAVING count(*)>1;--no duplicates found

-----------------------------------------DAILY CALORIES TABLE

CREATE TABLE IF NOT EXISTS daily_calories_merged(
    id numeric NOT NULL,
    activity_date date NOT NULL,
    calories numeric NOT NULL);
    
COPY daily_calories_merged
FROM 'C:\DIRECTORY\dailyCalories_merged.csv'
HEADER CSV DELIMITER ',';

SELECT * FROM daily_calories_merged;--full view of data
SELECT count(DISTINCT id) FROM daily_calories_merged;--33 users provided data
SELECT id, activity_date, count(*)
FROM daily_calories_merged
GROUP BY activity_date, id
HAVING count(*)>1;--no duplicates found

--Checking for continuity between 2 tables containing the same data
SELECT calories.id, calories.activity_date,
      calories.calories, activity.calories
FROM daily_calories_merged AS calories JOIN daily_activity_merged AS activity
    ON calories.id = activity.id 
    AND calories.activity_date = activity.activity_date
WHERE calories.calories != activity.calories;
--no rows where calories don't contain the same values in each table

-----------------------------------------HOURLY CALORIES TABLE

CREATE TABLE IF NOT EXISTS hourly_calories(
    id numeric NOT NULL,
    activity_hour timestamp NOT NULL,
    calories numeric NOT NULL);
    
COPY hourly_calories
FROM 'C:\DIRECTORY\hourlyCalories_merged.csv'
HEADER CSV DELIMITER ',';

SELECT * FROM hourly_calories;--full view of data
SELECT count(DISTINCT id) FROM hourly_calories;--33 users provided data
SELECT id, activity_hour, count(*)
FROM hourly_calories
GROUP BY activity_hour, id
HAVING count(*)>1;--no duplicates found

SELECT dailycals.id, dailycals.activity_date, dailycals.calories AS daily_cals_from_daily_results, 
       hourlycals.calories AS daily_cals_from_hourly_results
FROM daily_calories_merged AS dailycals
JOIN (SELECT id, date_trunc('day', activity_hour) AS date, sum(calories) AS calories
      FROM hourly_calories
      GROUP BY date, id
      ORDER BY date, id) AS hourlycals
    ON dailycals.id = hourlycals.id
    AND dailycals.activity_date = hourlycals.date
WHERE dailycals.calories != hourlycals.calories
ORDER BY dailycals.activity_date, dailycals.id;
--802 rows do not match between the hourly and daily calories datasets
--Will compare hourly and minute calories datasets to further investigate

-----------------------------------------MINUTE CALORIES TABLE

CREATE TABLE IF NOT EXISTS minute_calories(
    id numeric NOT NULL,
    activity_minute timestamp NOT NULL,
    calories numeric NOT NULL);
    
COPY minute_calories
FROM 'C:\DIRECTORY\minuteCaloriesNarrow_merged.csv'
HEADER CSV DELIMITER ',';

SELECT * FROM minute_calories;--full view of data
SELECT count(DISTINCT id) FROM minute_calories;--33 users provided data
SELECT id, activity_minute, count(*)
FROM minute_calories
GROUP BY activity_minute, id
HAVING count(*)>1;--no duplicates found

SELECT mincals.id, mincals.date, mincals.calories AS daily_cals_from_min_results, 
       hourlycals.calories AS daily_cals_from_hourly_results
FROM (SELECT id, date_trunc('day', activity_minute) AS date, round(sum(calories), 0) AS calories
      FROM minute_calories
      GROUP BY date, id
      ORDER BY date, id) AS mincals
JOIN (SELECT id, date_trunc('day', activity_hour) AS date, sum(calories) AS calories
      FROM hourly_calories
      GROUP BY date, id
      ORDER BY date, id) AS hourlycals
    ON mincals.id = hourlycals.id
    AND mincals.date = hourlycals.date
WHERE mincals.calories != hourlycals.calories
ORDER BY mincals.date, mincals.id;
--934 rows do not match. When rounding to the nearest calorie was included, 
----only 769 rows did not match between the daily and hourly calorie datasets.
--The issues appear to stem from rounding errors, will defer to the minute dataset as being the most precise.
--The issues occur on every day of the dataset and every user at least once.

-----------------------------------------DAILY STEPS TABLE

CREATE TABLE IF NOT EXISTS daily_steps_merged(
    id numeric NOT NULL,
    activity_date date NOT NULL,
    step_total numeric NOT NULL);
    
COPY daily_steps_merged
FROM 'C:\DIRECTORY\dailySteps_merged.csv'
HEADER CSV DELIMITER ',';

SELECT * FROM daily_steps_merged;--full view of data
SELECT count(DISTINCT id) FROM daily_steps_merged;--33 users provided data
SELECT id, activity_date, count(*)
FROM daily_steps_merged
GROUP BY activity_date, id
HAVING count(*)>1;--no duplicates found

--Checking for continuity between 2 tables containing the same data
SELECT steps.id, steps.activity_date,
       steps.step_total, activity.total_steps
FROM daily_steps_merged AS steps JOIN daily_activity_merged AS activity
    ON steps.id = activity.id 
    AND steps.activity_date = activity.activity_date
WHERE steps.step_total != activity.total_steps;
--no rows where step_totals don't contain the same values in each table

-----------------------------------------HOURLY STEPS TABLE

CREATE TABLE IF NOT EXISTS hourly_steps(
    id numeric NOT NULL,
    activity_hour timestamp NOT NULL,
    step_total numeric NOT NULL);
    
COPY hourly_steps
FROM 'C:\DIRECTORY\hourlySteps_merged.csv'
HEADER CSV DELIMITER ',';

SELECT * FROM hourly_steps;--full view of data
SELECT count(DISTINCT id) FROM hourly_steps;--33 users provided data
SELECT id, activity_hour, count(*)
FROM hourly_steps
GROUP BY activity_hour, id
HAVING count(*)>1;--no duplicates found

SELECT daily_steps.id, daily_steps.activity_date, 
       daily_steps.step_total AS daily_step_total, hourly_steps.step_total AS hourly_step_total
FROM daily_steps_merged AS daily_steps 
JOIN (SELECT id, date_trunc('day', activity_hour) AS date, sum(step_total) AS step_total
      FROM hourly_steps
      GROUP BY date, id
      ORDER BY date, id) AS hourly_steps
    ON daily_steps.id = hourly_steps.id
    AND daily_steps.activity_date = hourly_steps.date
WHERE daily_steps.step_total != hourly_steps.step_total
ORDER BY daily_steps.activity_date, daily_steps.id;
--159 records are different between the daily and hourly steps dataset.
--Will compare the minute and hourly datasets to confirm.

-----------------------------------------MINUTE STEPS TABLE

CREATE TABLE IF NOT EXISTS minute_steps(
    id numeric NOT NULL,
    activity_minute timestamp NOT NULL,
    step_total numeric NOT NULL);
    
COPY minute_steps
FROM 'C:\DIRECTORY\minuteStepsNarrow_merged.csv'
HEADER CSV DELIMITER ',';

SELECT * FROM minute_steps ORDER BY activity_minute DESC;--full view of data
SELECT count(DISTINCT id) FROM minute_steps;--33 users provided data
SELECT id, activity_minute, count(*)
FROM minute_steps
GROUP BY activity_minute, id
HAVING count(*)>1;--no duplicates found

SELECT min_steps.id, min_steps.date, 
       min_steps.step_total AS minute_step_total, hourly_steps.step_total AS hourly_step_total
FROM (SELECT id, date_trunc('day', activity_minute) AS date, sum(step_total) AS step_total
      FROM minute_steps
      GROUP BY date, id
      ORDER BY date, id) AS min_steps 
JOIN (SELECT id, date_trunc('day', activity_hour) AS date, sum(step_total) AS step_total
      FROM hourly_steps
      GROUP BY date, id
      ORDER BY date, id) AS hourly_steps
    ON min_steps.id = hourly_steps.id
    AND min_steps.date = hourly_steps.date
WHERE min_steps.step_total != hourly_steps.step_total
ORDER BY min_steps.date, min_steps.id;
--4 entries are different between the minute and daily steps tables.
--They are all from Thursday, May 12th, 2016
--Seems to be due to rounding error since 2016-05-12 was the last day in this dataset
--Minute-to-minute data will be more precise in this situation

-----------------------------------------HEARTRATE TABLE

CREATE TABLE IF NOT EXISTS heartrate_seconds(
    id numeric NOT NULL,
    activity_datetime timestamp NOT NULL,
    heartrate numeric NOT NULL);
    
COPY heartrate_seconds
FROM 'C:\DIRECTORY\heartrate_seconds_merged.csv'
HEADER CSV DELIMITER ',';

CREATE INDEX ON heartrate_seconds (id);
--This table has a large number of entries.
--Creating an index on the search column can improve query speed

SELECT * FROM heartrate_seconds;--full view of data
SELECT count(DISTINCT id) FROM heartrate_seconds;--14 users provided data
SELECT id, activity_datetime, count(*)
FROM heartrate_seconds
GROUP BY activity_datetime, id
HAVING count(*)>1;--no duplicates found

-----------------------------------------DAILY SLEEP TABLE

CREATE TABLE IF NOT EXISTS sleep_day(
    id numeric NOT NULL,
    activity_hour timestamp NOT NULL,
    sleep_records numeric NOT NULL,
    minutes_asleep numeric NOT NULL,
    minutes_in_bed numeric NOT NULL);
    
COPY sleep_day
FROM 'C:\DIRECTORY\sleepDay_merged.csv'
HEADER CSV DELIMITER ',';

SELECT * FROM sleep_day;--full view of data
SELECT count(DISTINCT id) FROM sleep_day;--24 users provided data

SELECT id, activity_hour, count(*)
FROM sleep_day
GROUP BY activity_hour, id
HAVING count(*) > 1;
--3 values found having duplicates
   
CREATE TABLE IF NOT EXISTS sleep_day_cleaned(
    id numeric NOT NULL,
    activity_hour timestamp NOT NULL,
    sleep_records numeric NOT NULL,
    minutes_asleep numeric NOT NULL,
    minutes_in_bed numeric NOT NULL);
--creating a new table for cleaned data

INSERT INTO sleep_day_cleaned
SELECT DISTINCT * FROM sleep_day;--inserting into new table only distinct datapoints

SELECT * FROM sleep_day;--413 rows
SELECT * FROM sleep_day_cleaned;--410 rows, 3 dupes removed
DROP TABLE sleep_day;--deleting old table


-----------------------------------------DAILY WEIGHT TABLE

CREATE TABLE IF NOT EXISTS weight_log(
    id numeric NOT NULL,
    activity_datetime timestamp NOT NULL,
    weight_kg numeric NOT NULL,
    weight_lbs numeric NOT NULL,
    fat numeric NOT NULL,
    bmi numeric NOT NULL,
    manually_reported boolean NOT NULL,
    log_id numeric NOT NULL);
    
COPY weight_log
FROM 'C:\DIRECTORY\weightLogInfo_merged.csv'
HEADER CSV DELIMITER ',';
--Import failed on the first attempt due to NULLs. 
--The target table only has 68 rows, so it will be opened in a spreadsheet
----and all NULLs will be filled in with -1 to signify that there was no entry.

SELECT * FROM weight_log;
SELECT count(DISTINCT id) FROM weight_log;--8 users provided data
SELECT id, activity_datetime, count(*)
FROM weight_log
GROUP BY activity_datetime, id
HAVING count(*)>1;--no duplicates found

-----------------------------------------CREATING A CLEANED MERGED ACTIVITIES TABLE

--Creating new table
CREATE TABLE IF NOT EXISTS clean_daily_activity_merged(
    id numeric NOT NULL,
    activity_date date NOT NULL,
    total_steps numeric NOT NULL,
    total_distance numeric NOT NULL,
    tracker_distance numeric NOT NULL,
    logged_activities_dist numeric NOT NULL,
    very_active_dist numeric NOT NULL,
    mod_active_dist numeric NOT NULL,
    light_active_dist numeric NOT NULL,
    sedentary_active_dist numeric NOT NULL,
    very_active_mins numeric NOT NULL,
    fairly_active_mins numeric NOT NULL,
    lightly_active_mins numeric NOT NULL,
    sedentary_mins numeric NOT NULL,
    calories numeric NOT NULL);   

--Updating new table
INSERT INTO clean_daily_activity_merged
SELECT original.id, original.activity_date, min_steps.step_total, original.total_distance,
       original.tracker_distance, original.logged_activities_dist, original.very_active_dist,
       original.mod_active_dist, original.light_active_dist, original.sedentary_active_dist,
       original.very_active_mins, original.fairly_active_mins, original.lightly_active_mins,
       original.sedentary_mins, mincals.calories  
FROM daily_activity_merged AS original
JOIN (SELECT id, date_trunc('day', activity_minute) AS date, round(sum(calories), 0) AS calories
      FROM minute_calories
      GROUP BY date, id
      ORDER BY date, id) AS mincals
    ON original.id = mincals.id
    AND original.activity_date = mincals.date
JOIN (SELECT id, date_trunc('day', activity_minute) AS date, sum(step_total) AS step_total
      FROM minute_steps
      GROUP BY date, id
      ORDER BY date, id) AS min_steps 
    ON original.id = min_steps.id
    AND original.activity_date = min_steps.date;

--Checking result
SELECT clean.id, clean.activity_date, clean.total_steps AS clean_steps,
       dirty.total_steps AS dirty_steps, clean.calories AS clean_cals, dirty.calories AS dirty_cals
FROM clean_daily_activity_merged AS clean
JOIN daily_activity_merged AS dirty
    ON clean.id = dirty.id
    AND clean.activity_date = dirty.activity_date
WHERE clean.calories != dirty.calories OR clean.total_steps != dirty.total_steps;

--Deleting old table
DROP TABLE daily_activity_merged;

