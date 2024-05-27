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
    geom GEOMETRY(LineString, 3763)
);

INSERT INTO pg_routes (route_id, direction, geom)
SELECT 
    split_part(shape_id, '_', 1) AS route_id,
    CAST(split_part(shape_id, '_', 2) AS INTEGER) AS direction,
    proj_linestring
FROM shapes;
-- THE GEOMETRY OF THE SAME ROUTE GOING FORWARDS AND BACKWARDS IS DIFFERENT DO I JUST DO ONE ?
SELECT pgr_createTopology('pg_routes', 0.001, 'geom', clean := TRUE);
UPDATE pg_routes
SET cost = ST_Length(geom),
    reverse_cost = ST_Length(geom);


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


