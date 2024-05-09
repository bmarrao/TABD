import matplotlib.pyplot as plt 
import psycopg2
from matplotlib.colors import Normalize
from matplotlib.cm import get_cmap

conn = psycopg2.connect("dbname=postgres user=brenin")
cursor_psql = conn.cursor()

sql_freguesias = """
    SELECT ST_AsText(ST_Simplify(proj_boundary, 0.5)) AS geom 
    FROM cont_aad_caop2018 
    WHERE concelho='PORTO';
"""
cursor_psql.execute(sql_freguesias)
results_freguesias = cursor_psql.fetchall()

sql_routes = "SELECT ST_AsText(ST_Transform(shape_linestring, 3763)) FROM shapes"
cursor_psql.execute(sql_routes)
results_routes = cursor_psql.fetchall()

cursor_psql.close()
conn.close()

fig, ax = plt.subplots(figsize=(10, 10))

# Plot freguesias' boundaries
for freguesia, geom_wkt in results_freguesias:
    boundary_coords = []
    for part in geom_wkt.split('((')[1].split('))')[0].split(','):
        x, y = part.strip(')').split()
        boundary_coords.append((float(x), float(y)))
    x, y = zip(*boundary_coords)
    ax.plot(x, y, color='blue')

num_routes = len(results_routes)
cmap = plt.cm.hsv
norm = Normalize(vmin=0, vmax=num_routes-1)
for i, row in enumerate(results_routes):
    point_string = row[0]
    point_string = point_string[11:-1] 
    points = point_string.split(',')
    xs = []
    ys = []
    for point in points:
        x, y = point.strip().split()
        xs.append(float(x))
        ys.append(float(y))
    color = cmap(norm(i))
    ax.plot(xs, ys, color=color, marker='o', markersize=5)

ax.set_xlabel('Longitude')
ax.set_ylabel('Latitude')

plt.show()
