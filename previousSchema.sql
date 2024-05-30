DROP TABLE IF EXISTS dw_taxi CASCADE;
DROP TABLE IF EXISTS dw_stops CASCADE;
DROP TABLE IF EXISTS dw_facts CASCADE;
DROP TABLE IF EXISTS dw_routes CASCADE;

CREATE TABLE dw_taxi (
    taxi_id INTEGER PRIMARY KEY
);

INSERT INTO dw_taxi(taxi_id)
SELECT DISTINCT taxi_id
FROM taxi_services 
ORDER BY 1 DESC;

CREATE TABLE dw_time (
    time_id SERIAL PRIMARY KEY,
    hour INTEGER,
    date DATE,
    month INTEGER
);

INSERT INTO dw_time(hour, date, month)
SELECT DISTINCT 
    extract(hour FROM to_timestamp(initial_ts)),
    date(to_timestamp(initial_ts)),
    extract(month FROM to_timestamp(initial_ts))
FROM taxi_services 
ORDER BY 1 DESC;

CREATE TABLE dw_stops (
    stop_id TEXT PRIMARY KEY,
    stop_name TEXT NOT NULL,
    location GEOMETRY(Point, 3763),
    freguesia VARCHAR(255),
    concelho VARCHAR(255)
);

INSERT INTO dw_stops(stop_id, stop_name, location, freguesia, concelho)
SELECT DISTINCT 
    stop_id,
    stop_name,
    proj_stop_location,
    (SELECT freguesia 
     FROM cont_aad_caop2018 AS p
     WHERE distrito = 'PORTO' 
     ORDER BY ST_Distance(proj_stop_location, p.proj_boundary) ASC
     LIMIT 1),
    (SELECT concelho 
     FROM cont_aad_caop2018 AS p
     WHERE distrito = 'PORTO' 
     ORDER BY ST_Distance(proj_stop_location, p.proj_boundary) ASC
     LIMIT 1)
FROM stops;

    CREATE TABLE dw_facts (
        time_id INTEGER REFERENCES dw_time(time_id),
        taxi_id INTEGER REFERENCES dw_taxi(taxi_id),
        initial_stop TEXT REFERENCES dw_stops(stop_id),
        final_stop TEXT REFERENCES dw_stops(stop_id),
        number_of_trips INTEGER,
        PRIMARY KEY (time_id, taxi_id, initial_stop, final_stop)
    );

INSERT INTO dw_facts(time_id, taxi_id, initial_stop, final_stop, number_of_trips)
WITH stop_matches AS 
(
    SELECT 
        ts.taxi_id,
        ts.initial_ts,
        (SELECT stop_id 
         FROM dw_stops st 
         ORDER BY ST_Distance(st.location, ST_Transform(ts.initial_point::geometry, 3763)) ASC
         LIMIT 1) AS initial_stop,
        (SELECT stop_id 
         FROM dw_stops st 
         ORDER BY ST_Distance(st.location, ST_Transform(ts.final_point::geometry, 3763)) ASC
         LIMIT 1) AS final_stop
    FROM 
        taxi_services ts
)
SELECT
    (SELECT time_id 
     FROM dw_time t
     WHERE t.date = date(to_timestamp(sm.initial_ts))
       AND t.hour = extract(hour FROM to_timestamp(sm.initial_ts))
       AND t.month = extract(month FROM to_timestamp(sm.initial_ts))
     LIMIT 1) AS time_id,
    sm.taxi_id,
    sm.initial_stop,
    sm.final_stop,
    COUNT(*) AS number_of_trips
FROM 
    stop_matches sm
GROUP BY 
    time_id, sm.taxi_id, sm.initial_stop, sm.final_stop;


SELECT 
initial_stop,
final_stop,
SUM(number_of_trips) AS total_trips
FROM dw_facts
GROUP BY CUBE (initial_stop, final_stop)
ORDER BY SUM(number_of_trips) DESC NULLS LAST
LIMIT 10;
