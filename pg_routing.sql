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
SET cost = ST_Length(geom::geography),
    reverse_cost = ST_Length(geom::geography);


SELECT pgr_createTopology('pg_routes', 0.00001, 'geom', 'id');
