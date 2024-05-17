import matplotlib.pyplot as plt 
import psycopg2
from matplotlib.colors import Normalize
from matplotlib.cm import get_cmap

conn = psycopg2.connect("dbname=postgres user=brenin")
cursor_psql = conn.cursor()
sql = "SELECT st_astext(proj_linestring) FROM shapes"
cursor_psql.execute(sql)
results = cursor_psql.fetchall()

fig, ax = plt.subplots()

num_linestrings = len(results)

cmap = plt.cm.hsv  
norm = Normalize(vmin=0, vmax=num_linestrings-1)

for i, row in enumerate(results):
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

plt.show()
