DROP TABLE IF EXISTS pg_routes CASCADE;

-- pg routing if doesnt work take out direction and leave the same way as before
CREATE TABLE pg_routes 
(
    id SERIAL PRIMARY KEY,
    route_id TEXT REFERENCES routes(route_id),
    direction INTEGER NOT NULL,
    source INTEGER,
    target INTEGER,
    cost DOUBLE PRECISION,
    reverse_cost DOUBLE PRECISION,
    geom GEOMETRY(LineString, 4326)
);

INSERT INTO pg_routes (route_id, direction, geom)
SELECT 
    split_part(shape_id, '_', 1) AS route_id,
    CAST(split_part(shape_id, '_', 2) AS INTEGER) AS direction,
    shape_linestring
FROM shapes;

DROP TABLE IF EXISTS pg_routes_vertices_pgr CASCADE;
DROP TABLE IF EXISTS pg_routes_edges_pgr CASCADE;
SELECT pgr_createTopology('pg_routes', 0.000000001, 'geom', clean := TRUE);
UPDATE pg_routes
SET cost = ST_Length(geom),
    reverse_cost = ST_Length(geom);


WITH servico AS (
    SELECT
        (SELECT id 
         FROM pg_routes_vertices_pgr 
         ORDER BY ST_Distance(the_geom, ST_Transform(ts.initial_point::geometry, 3763)) ASC 
         LIMIT 1) AS first,
        (SELECT id 
         FROM pg_routes_vertices_pgr 
         ORDER BY ST_Distance(the_geom, ST_Transform(ts.final_point::geometry, 3763)) ASC 
         LIMIT 1) AS snd
    FROM taxi_services AS ts 
    WHERE ts.id = 7269
)
SELECT * 
FROM pgr_dijkstra(
    'SELECT id, source, target, cost, reverse_cost FROM pg_routes',
    (SELECT first FROM servico),
    (SELECT snd FROM servico),
    directed := true
);


SELECT * 
FROM pgr_dijkstra(
    'SELECT id, source, target, cost, reverse_cost FROM pg_routes',
    12,
    176,
    directed := true
);

SELECT 
    dijk.seq, dijk.node, dijk.edge, dijk.cost
FROM 
    taxi_services AS ts,
    LATERAL 
    (
        SELECT * 
        FROM pgr_dijkstra(
            'SELECT id, source, target, cost, reverse_cost FROM pg_routes',
            (
                SELECT id 
                FROM pg_routes_vertices_pgr 
                ORDER BY ST_Distance(the_geom, ST_Transform(ts.initial_point::geometry, 3763)) ASC 
                LIMIT 1
            ),
            (
                SELECT id 
                FROM pg_routes_vertices_pgr 
                ORDER BY ST_Distance(the_geom, ST_Transform(ts.final_point::geometry, 3763)) ASC 
                LIMIT 1
            ),
            directed := true
        )
    ) AS dijk;
WHERE ts.id = 1;

INSERT INTO dw_routes(seq, node, edge, cost , initial_stop, final_stop)
SELECT DISTINCT 
    dijk.seq,
    dijk.node,
    dijk.edge,
    dijk.cost,
    p.stop_id,
    q.stop_id
FROM 
    (SELECT proj_stop_location, stop_id FROM dw_stops as pq where pq.stop_id = 'BV2') as p,
    (SELECT proj_stop_location, stop_id FROM dw_stops as qp where qp.stop_id = 'BV2')as q,
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



