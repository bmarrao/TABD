import matplotlib.pyplot as plt 
import psycopg2

scale = 1/30000
conn = psycopg2.connect("dbname=postgres user=brenin")
cursor_psql = conn.cursor()
sql = "SELECT st_astext(proj_stop_location) FROM stops"
cursor_psql.execute(sql)
results = cursor_psql.fetchall()
xs = []
ys = []
for row in results:
    point_string = row[0]
    point_string = point_string[6:-1]
    (x, y) = point_string.split()
    xs.append(float(x))
    ys.append(float(y))  

width_in_inches = ((max(xs) - min(xs)) / 0.0254) * 1.1
height_in_inches = ((max(ys) - min(ys)) / 0.0254) * 1.1

fig = plt.figure(figsize=(width_in_inches * scale, height_in_inches * scale))

plt.scatter(xs, ys, s=5)

plt.show()
