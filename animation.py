import numpy as np 
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import psycopg2

def animate(i):
    scat.set_offsets([x[i],y[i]])

def linestring_to_points(line_string):
    xs,ys = [],[]
    points= line_string [11:-1].split(',')
    for point in points :
        (x,y) = point.split()
        xs.append(float(x))
        ys.append(float(y))
    return xs,ys


scale = 1/60000

conn = psycopg2.connect("dbname=postgres user=brenin")
cursor = conn.cursor()


sql_freguesias = """
    SELECT freguesia, ST_AsText(ST_Simplify(proj_boundary, 0.5)) AS geom 
    FROM cont_aad_caop2018 
    WHERE concelho IN ('PORTO', 'MATOSINHOS', 'MAIA', 'GAIA','GONDOMAR','VILA NOVA DE GAIA','VALONGO');

"""
cursor.execute(sql_freguesias)
results_freguesias = cursor.fetchall()

freguesias_boundaries = []
for freguesia, geom_wkt in results_freguesias:
    boundary_coords = []
    for part in geom_wkt.split('((')[1].split('))')[0].split(','):
        x, y = part.strip(')').split()
        boundary_coords.append((float(x), float(y)))
    freguesias_boundaries.append(boundary_coords)


sql = "SELECT st_astext(proj_linestring) FROM shapes"
cursor.execute(sql)

results = cursor.fetchall()
print(len(results))
x,y = [],[]
xs,ys = linestring_to_points(results[0][0])
xs_min = min(xs)
xs_max = max(xs)
ys_min = min(ys)
ys_max = max(ys)
for row in results :
    print(len(row))
    xs,ys = linestring_to_points(row[0])
    if(max(xs) > xs_max):
        xs_max= max(xs)
    if(max(ys) > ys_max):
        ys_max= max(ys)
    if(min(ys) > ys_min):
        ys_min= min(ys)
    if(min(xs) > xs_min):
        xs_min= min(xs)
    print(len(xs))
    x = x + xs
    y = y + ys

xs_max += 20000
xs_min -= 20000
ys_max += 20000
ys_min -= 20000

width_in_inches = (xs_max-xs_min)/0.0254*1.1
height_in_inches = (ys_max-ys_min)/0.0254*1.1


fig,ax = plt.subplots(figsize =(10,8))


ax.set(xlim=(xs_min,xs_max),ylim=(ys_min,ys_max))


scat = ax.scatter(x[0],y[0],s=10)
anim = FuncAnimation(fig,animate, interval=1,frames=len(y)-1)

plt.draw()
plt.show()
conn.close()