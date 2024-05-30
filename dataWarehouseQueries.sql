-- Busies stops
SELECT 
    initial_stop,
    final_stop,
    SUM(number_of_trips) AS total_trips
FROM dw_facts_
GROUP BY CUBE (initial_stop, final_stop)
ORDER BY SUM(number_of_trips) DESC NULLS LAST
LIMIT 10;


-- Busiest days
SELECT 
    date,
    month,
    SUM(number_of_trips) AS total_trips
FROM dw_time_
JOIN dw_facts_ ON dw_time_.time_id = dw_facts_.initial_time_id
GROUP BY ROLLUP (date, month)
ORDER BY total_trips DESC
LIMIT 10;

-- Busiest days of the week

SELECT 
    EXTRACT(DOW FROM date) AS day_of_week,  -- Extract day of week (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
    SUM(number_of_trips) AS total_trips
FROM dw_time_
JOIN dw_facts_ ON dw_time_.time_id = dw_facts_.initial_time_id
GROUP BY ROLLUP (EXTRACT(DOW FROM date))
ORDER BY total_trips DESC
LIMIT 10;

-- Busiest Months 
SELECT 
    month,
    SUM(number_of_trips) AS total_trips
FROM dw_time_
JOIN dw_facts_ ON dw_time_.time_id = dw_facts_.time_id
GROUP BY ROLLUP (month)
ORDER BY total_trips DESC
LIMIT 10;

-- Distance from initial to final stop
SELECT 
    initial_stop,
    final_stop,
    taxi_id,
    SUM(first_to_last_stop_distance) AS total_distance
FROM dw_facts_
GROUP BY CUBE (initial_stop, final_stop, taxi_id)
ORDER BY total_distance DESC NULLS LAST
LIMIT 10;

-- Average time between stops
SELECT 
    initial_stop,
    final_stop,
    taxi_id,
    AVG(time_between_initial_and_final) AS avg_time
FROM dw_facts_
GROUP BY CUBE (initial_stop, final_stop, taxi_id)
ORDER BY avg_time DESC NULLS LAST
LIMIT 10;

