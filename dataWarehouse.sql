DROP TABLE IF EXISTS dw_time CASCADE;
DROP TABLE IF EXISTS dw_taxi CASCADE;
DROP TABLE IF EXISTS dw_stops CASCADE;
DROP TABLE IF EXISTS dw_facts CASCADE;

CREATE TABLE dw_taxi 
(
    taxi_id INTEGER PRIMARY KEY
);


INSERT INTO dw_taxi(taxi_id)
SELECT DISTINCT taxi_id
FROM taxi_services 
ORDER BY 1 DESC;

CREATE TABLE dw_time 
(
    time_id SERIAL PRIMARY KEY,
    hour INTEGER,
    date DATE,
    month INTEGER
);

INSERT INTO dw_time(hour, date, month)
SELECT DISTINCT 
    extract(hour from to_timestamp(initial_ts)),
    date(to_timestamp(initial_ts)),
    extract(month from to_timestamp(initial_ts))
FROM taxi_services 
ORDER BY 1 DESC;


CREATE TABLE dw_stops
(
    stop_id TEXT PRIMARY KEY,
    stop_name         TEXT NOT NULL,
    location     geometry(Point),
    freguesia character varying(255),
    concelho character varying(255)
);

INSERT INTO dw_stops(stop_id, stop_name, location, freguesia , concelho)
SELECT DISTINCT 
    stop_id,
    stop_name,
    proj_stop_location,
    (select freguesia 
    from cont_aad_caop2018 as p
    where distrito = 'PORTO' 
    ORDER BY st_distance(proj_stop_location, p.proj_boundary) asc
    LIMIT 1),
    (select concelho 
    from cont_aad_caop2018 as p
    where distrito = 'PORTO' 
    ORDER BY st_distance(proj_stop_location, p.proj_boundary) asc
    LIMIT 1)
FROM stops;
CREATE TABLE dw_facts (
    time_id INTEGER REFERENCES dw_time(time_id),
    taxi_id INTEGER REFERENCES dw_taxi(taxi_id),
    initial_stop INTEGER REFERENCES dw_location(initial_stop),
    final_stop INTEGER REFERENCES dw_location(final_stop),
    number_of_trips INTEGER,
    PRIMARY KEY (time_id, taxi_id, location_id)
);
