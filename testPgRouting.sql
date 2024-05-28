SELECT * FROM pgr_dijkstra(
        'SELECT id, source, target, cost, reverse_cost FROM pg_routes',
        1, 10,
        directed := true
    )