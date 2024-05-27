DROP TABLE IF EXISTS dw_time CASCADE;
DROP TABLE IF EXISTS dw_taxi CASCADE;
DROP TABLE IF EXISTS dw_stops CASCADE;
DROP TABLE IF EXISTS dw_facts CASCADE;
DROP TABLE IF EXISTS dw_routes   CASCADE;


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


-- Add proj_stop_location column if it does not exist
ALTER TABLE dw_stops
ADD COLUMN IF NOT EXISTS proj_stop_location geometry(Point, 4326);

-- Create the dw_routes table
CREATE TABLE dw_routes 
(
    seq INTEGER,
    node INTEGER,
    edge INTEGER,
    cost DOUBLE PRECISION,
    initial_stop TEXT REFERENCES dw_stops(stop_id),
    final_stop TEXT REFERENCES dw_stops(stop_id),
    PRIMARY KEY (seq, initial_stop, final_stop)
);

-- Insert data into dw_routes
INSERT INTO dw_routes(seq, node, edge, cost , initial_stop, final_stop)
SELECT DISTINCT 
    dijk.seq,
    dijk.node,
    dijk.edge,
    dijk.cost,
    p.stop_id,
    q.stop_id
FROM 
    dw_stops as p ,
    dw_stops as q , 
    LATERAL 
    (
        SELECT * 
        FROM pgr_dijkstra(
            'SELECT id, source, target, cost, reverse_cost FROM pg_routes',
            (
                SELECT id 
                FROM pg_routes_vertices_pgr 
                ORDER BY ST_Distance(the_geom, p.proj_stop_location) ASC 
                LIMIT 1
            ),
            (
                SELECT id 
                FROM pg_routes_vertices_pgr 
                ORDER BY ST_Distance(the_geom, q.proj_stop_location) ASC 
                LIMIT 1
            ),
            directed := true
        )
    ) AS dijk;



CREATE TABLE dw_facts (
    time_id INTEGER REFERENCES dw_time(time_id),
    taxi_id INTEGER REFERENCES dw_taxi(taxi_id),
    initial_stop TEXT REFERENCES dw_stops(stop_id),
    final_stop TEXT REFERENCES dw_stops(stop_id),
    number_of_trips INTEGER,
    number_of_routes INTEGER,
    PRIMARY KEY (time_id, taxi_id, initial_stop, final_stop)
);


INSERT INTO dw_facts(time_id, taxi_id, initial_stop, final_stop, number_of_trips, number_of_routes)
SELECT 
    (
        SELECT 
            time_id 
        FROM 
            dw_time t
        WHERE 
            t.date = date(to_timestamp(ts.initial_ts)) AND
            t.hour = extract(hour from to_timestamp(ts.initial_ts)) AND
            t.month = extract(month from to_timestamp(ts.initial_ts))
        LIMIT 1
    ),
    ts.taxi_id,
    first_stop.stop_id,
    last_stop.stop_id,
    count(*),
    (
        SELECT 
            seq 
        FROM 
            dw_routes rt
        WHERE 
            rt.initial_stop = first_stop.stop_id AND
            rt.final_stop = last_stop.stop_id
        ORDER BY 
            seq DESC 
        LIMIT 1
    )
FROM 
    taxi_services ts,
    LATERAL (
        SELECT 
            stop_id 
        FROM 
            dw_stops st 
        ORDER BY 
            st_distance(location, ST_Transform(ts.initial_point::geometry, 3763)) ASC
        LIMIT 
            1
    ) as first_stop,
    LATERAL (
        SELECT 
            stop_id 
        FROM 
            dw_stops st 
        ORDER BY 
            st_distance(location, ST_Transform(ts.final_point::geometry, 3763)) ASC
        LIMIT 
            1
    ) as last_stop 
GROUP BY 
    ts.taxi_id, first_stop.stop_id, last_stop.stop_id, ts.initial_ts;

