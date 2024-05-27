DROP TABLE IF EXISTS dw_time CASCADE;
DROP TABLE IF EXISTS dw_taxi CASCADE;
DROP TABLE IF EXISTS dw_stops CASCADE;
DROP TABLE IF EXISTS dw_facts CASCADE;
DROP TABLE IF EXISTS pg_routes CASCADE;


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
    initial_stop TEXT REFERENCES dw_stops(stop_id),
    final_stop TEXT REFERENCES dw_stops(stop_id),
    number_of_trips INTEGER,
    PRIMARY KEY (time_id, taxi_id, initial_stop, final_stop)
);
-- pg routing if doesnt work take out direction and leave the same way as before
CREATE TABLE pg_routes (
    route_id TEXT NOT NULL,
    direction integer NOT NULL,
    source integer,
    target integer,
    cost double precision,
    reverse_cost double precision,
    geom geometry(LineString, 3763),
    PRIMARY KEY (route_id, direction)
);

INSERT INTO pg_routes (route_id, direction, geom)
SELECT 
    split_part(shape_id, '_', 1),
    split_part(shape_id, '_', 2)direction,
    proj_linestring
FROM shapes;
-- THE GEOMETRY OF THE SAME ROUTE GOING FORWARDS AND BACKWARDS IS DIFFERENT DO I JUST DO ONE ?
SELECT pgr_nodeNetwork('pg_routes', 0.00001, 'geom', 'route_id');

UPDATE pg_routes
SET cost = ST_Length(geom::geography),
    reverse_cost = ST_Length(geom::geography);

SELECT pgr_createTopology('pg_routes', 0.00001, 'geom', 'route_id');
'''
INSERT INTO dw_facts(time_id, taxi_id, initial_stop, final_stop)
SELECT DISTINCT 
    (SELECT time_id 
     FROM dw_time 
     WHERE hour = extract(hour FROM to_timestamp(ts.initial_ts)) 
       AND date = date(to_timestamp(ts.initial_ts)) 
       AND month = extract(month FROM to_timestamp(ts.initial_ts))),
    ts.taxi_id,
    (SELECT stop_id 
     FROM dw_stops AS s 
     ORDER BY st_distance(st_transform(initial_point :: geometry,3763), s.location) ASC 
     LIMIT 1),
    (SELECT stop_id 
     FROM dw_stops AS s 
     ORDER BY st_distance(st_transform(initial_point :: geometry,3763), s.location) ASC 
     LIMIT 1)
FROM taxi_services ts;
'''