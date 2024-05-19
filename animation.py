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

sql = "SELECT st_astext(proj_stop_location) FROM stops"
cursor.execute(sql)
results_stops = cursor.fetchall()
all_stops_xs = []
all_stops_ys = []
for row in results_stops:
    point_string = row[0]
    point_string = point_string[6:-1]
    (x, y) = point_string.split()
    all_stops_xs.append(float(x))
    all_stops_ys.append(float(y))  

print(max(all_stops_xs))
print(max(all_stops_ys))
print(min(all_stops_xs))
print(min(all_stops_ys))
# Fetch linestring shapes
sql = "SELECT st_astext(proj_linestring) FROM shapes"
cursor.execute(sql)
results = cursor.fetchall()
print(f"Number of linestrings: {len(results)}")
x, y = [], []
xs, ys = linestring_to_points(results[0][0])
xs_min = min(xs)
xs_max = max(xs)
ys_min = min(ys)
ys_max = max(ys)
for row in results:
    xs, ys = linestring_to_points(row[0])
    xs_min = min(xs_min, min(xs))
    xs_max = max(xs_max, max(xs))
    ys_min = min(ys_min, min(ys))
    ys_max = max(ys_max, max(ys))
    x.extend(xs)
    y.extend(ys)

padding = 2000
xs_max += padding
xs_min -= padding
ys_max += padding
ys_min -= padding

print(max(all_stops_xs), xs_max)
print(max(all_stops_ys),ys_max)
print(min(all_stops_xs), xs_min)
print(min(all_stops_ys),ys_min)
fig, ax = plt.subplots(figsize=(10, 8))
ax.set(xlim=(xs_min, xs_max), ylim=(ys_min, ys_max))

scat = ax.scatter(x[0], y[0], s=10, color='blue')

scat_stops = ax.scatter(all_stops_xs, all_stops_ys, s=1, color='red')

anim = FuncAnimation(fig, animate, interval=1, frames=len(y) - 1)

plt.draw()
plt.show()

# Close the database connection
conn.close()
