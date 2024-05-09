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

xs_min, xs_max, ys_min, ys_max = -50000,-30000,160000,172000

width_in_inches = (xs_max-xs_min)/0.0254*1.1
height_in_inches = (ys_max-ys_min)/0.0254*1.1

fig,ax = plt.subplots(figsize =(width_in_inches*scale,height_in_inches*scale))
ax.set(xlim=(xs_min,xs_max),ylim=(ys_min,ys_max))
sql = "SELECT st_astext(ST_Transform(shape_linestring, 3763)) FROM shapes"

cursor.execute(sql)

results = cursor.fetchall()

x,y = [],[]
for row in results :
    print(row)
    xs,ys = linestring_to_points(row[0])
    x = x + xs
    y = y + ys

scat = ax.scatter(x[0],y[0],s=10)
anim = FuncAnimation(fig,animate, interval=1,frames=len(y)-1)

plt.draw()
plt.show()
conn.close()