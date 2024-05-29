DROP TABLE IF EXISTS pg_routes_vertices_pgr CASCADE;
DROP TABLE IF EXISTS pg_routes_edges_pgr CASCADE;

alter table pg_routes add proj_geom geometry(LineString,3763);

update pg_routes set proj_geom = st_transform(geom::geometry,3763);
SELECT pgr_createTopology('pg_routes', 0.00001, 'proj_geom', clean := TRUE);

UPDATE pg_routes
SET cost = ST_Length(proj_geom),
    reverse_cost = ST_Length(proj_geom);
SELECT 
stop_id,
(SELECT id FROM pg_routes_vertices_pgr ORDER BY ST_Distance(the_geom, location) ASC LIMIT 1)
FROM dw_stops 

WITH dijkstra_result AS (
    SELECT * FROM pgr_dijkstra(
        'SELECT id, source, target, cost, reverse_cost FROM pg_routes',
        12450,
        9408,
        directed := true
    )
)
SELECT 
    dijkstra_result.seq,
    dijkstra_result.id1 AS node,
    dijkstra_result.id2 AS edge,
    dijkstra_result.cost,
    r.route_id,
    r.direction
FROM 
    dijkstra_result
JOIN 
    pg_routes r ON dijkstra_result.id2 = r.id
ORDER BY 
    dijkstra_result.seq;


