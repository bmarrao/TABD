import psycopg2
import geopandas as gpd
import matplotlib.pyplot as plt

conn = psycopg2.connect("dbname=postgres user=brenin")
cursor_psql = conn.cursor()

sql_boundary = """
    SELECT ST_Union(ST_Simplify(proj_boundary, 0.5)) AS geom 
    FROM cont_aad_caop2018 
    WHERE distrito='PORTO';
"""

gdf_boundary = gpd.GeoDataFrame.from_postgis(sql_boundary, conn, geom_col='geom')

sql_stops = """
    SELECT ST_AsText(ST_Transform(ST_SetSRID(stop_location::geometry, 4326), 3763)) FROM stops
"""
cursor_psql.execute(sql_stops)
results = cursor_psql.fetchall()
xs = []
ys = []

for row in results:
    point_string = row[0]
    point_string = point_string[6:-1]  
    (x, y) = point_string.split()
    xs.append(float(x))
    ys.append(float(y))  

conn.close()

fig, ax = plt.subplots(figsize=(10, 8))

# Plot boundary
gdf_boundary.plot(ax=ax, color='blue', alpha=0.5)

# Plot transformed points
ax.scatter(xs, ys, color='red', s=5, label='Stop Locations')

ax.set_title('Boundary of Municipality of Porto with Stop Locations')
ax.set_xlabel('Longitude')
ax.set_ylabel('Latitude')
ax.legend()

plt.show()
