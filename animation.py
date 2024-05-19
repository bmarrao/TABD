import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import psycopg2

def animate(i):
    scat.set_offsets([x[i], y[i]])
    scat_stops.set_offsets(np.c_[all_stops_xs, all_stops_ys])

def linestring_to_points(line_string):
    xs, ys = [], []
    points = line_string[11:-1].split(',')
    for point in points:
        (x, y) = point.split()
        xs.append(float(x))
        ys.append(float(y))
    return xs, ys

scale = 1/60000

conn = psycopg2.connect("dbname=postgres user=brenin")
cursor = conn.cursor()

sql_stops = "SELECT st_astext(proj_stop_location) FROM stops"
cursor.execute(sql_stops)
results_stops = cursor.fetchall()
all_stops_xs = []
all_stops_ys = []
for row in results_stops:
    point_string = row[0][6:-1]
    (x, y) = point_string.split()
    all_stops_xs.append(float(x))
    all_stops_ys.append(float(y))  

sql_shapes = "SELECT st_astext(proj_linestring) FROM shapes"
cursor.execute(sql_shapes)
results_shapes = cursor.fetchall()

sql_freguesias = """
    SELECT freguesia, ST_AsText(ST_Simplify(proj_boundary, 0.5)) AS geom 
    FROM cont_aad_caop2018 
    WHERE concelho IN ('PORTO', 'MATOSINHOS', 'MAIA', 'GAIA','GONDOMAR','VILA NOVA DE GAIA','VALONGO');
"""
cursor.execute(sql_freguesias)
results_freguesias = cursor.fetchall()

cursor.close()
conn.close()

x, y = [], []
xs, ys = linestring_to_points(results_shapes[0][0])
xs_min = min(xs)
xs_max = max(xs)
ys_min = min(ys)
ys_max = max(ys)
for row in results_shapes:
    xs, ys = linestring_to_points(row[0])
    xs_min = min(xs_min, min(xs))
    xs_max = max(xs_max, max(xs))
    ys_min = min(ys_min, min(ys))
    ys_max = max(ys_max, max(ys))
    x.extend(xs)
    y.extend(ys)

freguesias_boundaries = []
for freguesia, geom_wkt in results_freguesias:
    boundary_coords = []
    for part in geom_wkt.split('((')[1].split('))')[0].split(','):
        x_coord, y_coord = part.strip(')').split()
        boundary_coords.append((float(x_coord), float(y_coord)))
    freguesias_boundaries.append(boundary_coords)

padding = 2000
xs_max += padding
xs_min -= padding
ys_max += padding
ys_min -= padding

fig, ax = plt.subplots(figsize=(10, 8))
ax.set(xlim=(xs_min, xs_max), ylim=(ys_min, ys_max))

for boundary_coords in freguesias_boundaries:
    x_coords, y_coords = zip(*boundary_coords)
    ax.plot(x_coords, y_coords, color='blue')

scat = ax.scatter(x[0], y[0], s=10, color='blue')
scat_stops = ax.scatter(all_stops_xs, all_stops_ys, s=1, color='red')

# Animation function
anim = FuncAnimation(fig, animate, interval=1, frames=len(y) - 1)

plt.draw()
plt.show()
