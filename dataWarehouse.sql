--DROP TABLE IF EXISTS dw_time_ CASCADE;
--DROP TABLE IF EXISTS dw_taxi_ CASCADE;
--DROP TABLE IF EXISTS dw_stops_ CASCADE;
--DROP TABLE IF EXISTS dw_facts_ CASCADE;


CREATE TABLE dw_taxi_ (
    taxi_id INTEGER PRIMARY KEY
);

INSERT INTO dw_taxi_(taxi_id)        
SELECT DISTINCT taxi_id
FROM taxi_services 
ORDER BY 1 DESC;

CREATE TABLE dw_time_ (
    time_id SERIAL PRIMARY KEY,
    hour INTEGER,
    date DATE,
    month INTEGER
);

INSERT INTO dw_time_(hour, date, month)
SELECT DISTINCT 
    extract(hour FROM to_timestamp(initial_ts)),
    date(to_timestamp(initial_ts)),
    extract(month FROM to_timestamp(initial_ts))
FROM taxi_services 
ORDER BY 1 DESC;

INSERT INTO dw_time_(hour, date, month)
SELECT DISTINCT 
    extract(hour FROM to_timestamp(final_ts)),
    date(to_timestamp(final_ts)),
    extract(month FROM to_timestamp(final_ts))
FROM taxi_services 
ORDER BY 1 DESC;

CREATE TABLE dw_stops_ (
    stop_id VARCHAR(8) PRIMARY KEY,
    stop_name TEXT NOT NULL,
    location GEOMETRY(Point, 3763),
    freguesia VARCHAR(255),
    concelho VARCHAR(255)
);

INSERT INTO dw_stops_(stop_id, stop_name, location, freguesia, concelho)
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



CREATE TABLE dw_facts_ (
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

CREATE INDEX idx_dw_facts__initial_time_id ON dw_facts_ (initial_time_id);
CREATE INDEX idx_dw_facts__final_time_id ON dw_facts_ (final_time_id);
CREATE INDEX idx_dw_facts__taxi_id ON dw_facts_ (taxi_id);
CREATE INDEX idx_dw_facts__initial_stop ON dw_facts_ (initial_stop);
CREATE INDEX idx_dw_facts__final_stop ON dw_facts_ (final_stop);

CREATE INDEX idx_dw_stops__stop_id ON dw_stops_ (stop_id);
INSERT INTO dw_facts_(initial_time_id, final_time_id, taxi_id, initial_stop, final_stop, number_of_trips, first_to_last_stop_distance, time_between_initial_and_final) 
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
        taxi_services ts
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
