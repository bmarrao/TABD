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
    initial_stop INTEGER REFERENCES dw_stops(stop_id),
    final_stop INTEGER REFERENCES dw_stops(stop_id),
    route_id INTEGER REFERENCES dw_route(route_id)
    number_of_trips INTEGER,
    PRIMARY KEY (time_id, taxi_id, initial_stop,final_stop)
);

INSERT INTO dw_facts(time_id, taxi_id, initial_stop, final_stop)
SELECT DISTINCT 
    (SELECT time_id from dw_time WHERE hour =extract(hour from to_timestamp(initial_ts), date =date(to_timestamp(initial_ts)), month =extract(month from to_timestamp(initial_ts)) )),
    taxi_id,
    (select stop_id
    from dw_stops as s
    ORDER BY st_distance(initial_point, s.location) asc
    LIMIT 1),
    (select stop_id
    from dw_stops as s
    ORDER BY st_distance(final_point, s.location) asc
    LIMIT 1),
FROM taxi_services;