CREATE TABLE dw_teste_ (
    initial_time_id INTEGER REFERENCES dw_time_(time_id),
    final_time_id INTEGER REFERENCES dw_time_(time_id),
    taxi_id INTEGER REFERENCES dw_taxi_(taxi_id),
    initial_stop TEXT REFERENCES dw_stops_(stop_id),
    final_stop TEXT REFERENCES dw_stops_(stop_id),
    number_of_trips INTEGER,
    distance FLOAT,
    first_to_last_stop_distance FLOAT,
    number_of_routes INTEGER,
    time_between_initial_and_final INTERVAL, 
    PRIMARY KEY (initial_time_id, final_time_id, taxi_id, initial_stop, final_stop)
);


INSERT INTO dw_teste_(initial_time_id, final_time_id, taxi_id, initial_stop, final_stop, number_of_trips, first_to_last_stop_distance, time_between_initial_and_final) 
WITH stop_matches AS 
(
    SELECT 
        ts.taxi_id,
        ts.initial_ts,
        ts.final_ts,
        (SELECT stop_id 
         FROM dw_stops_ st 
         ORDER BY ST_Distance(st.location, ST_Transform(ts.initial_point::geometry, 3763)) ASC
         LIMIT 1) AS initial_stop,
        (SELECT stop_id 
         FROM dw_stops_ st 
         ORDER BY ST_Distance(st.location, ST_Transform(ts.final_point::geometry, 3763)) ASC
         LIMIT 1) AS final_stop
    FROM 
        taxi_services as ts
        where ts.taxi_id > 0 AND ts.taxi_id <=100 and ts.taxi_id !=3
)
SELECT
    (SELECT time_id 
     FROM dw_time_ t
     WHERE t.date = date(to_timestamp(sm.initial_ts))
       AND t.hour = extract(hour FROM to_timestamp(sm.initial_ts))
       AND t.month = extract(month FROM to_timestamp(sm.initial_ts))
     LIMIT 1) AS initial_time_id,
    (SELECT time_id 
     FROM dw_time_ t
     WHERE t.date = date(to_timestamp(sm.final_ts))
       AND t.hour = extract(hour FROM to_timestamp(sm.final_ts))
       AND t.month = extract(month FROM to_timestamp(sm.final_ts))
     LIMIT 1) AS final_time_id,
    sm.taxi_id,
    sm.initial_stop,
    sm.final_stop,
    COUNT(*) AS number_of_trips,
    ST_Distance(
        (SELECT location FROM dw_stops_ as s WHERE s.stop_id = sm.initial_stop),
        (SELECT location FROM dw_stops_ as s WHERE s.stop_id = sm.final_stop)
    ) AS first_to_last_stop_distance,
    MAX(to_timestamp(sm.final_ts) - to_timestamp(sm.initial_ts)) AS time_between_initial_and_final 
FROM 
    stop_matches as sm
GROUP BY 
    initial_time_id, final_time_id, sm.taxi_id, sm.initial_stop, sm.final_stop;
