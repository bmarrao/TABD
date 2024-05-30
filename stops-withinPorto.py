import matplotlib.pyplot as plt 
import psycopg2

conn = psycopg2.connect("dbname=postgres user=brenin")
cursor_psql = conn.cursor()

sql_freguesias = """
    SELECT freguesia, concelho, ST_AsText(ST_Simplify(proj_boundary, 0.5)) AS geom 
    FROM cont_aad_caop2018 
    WHERE concelho IN ('PORTO', 'MATOSINHOS', 'MAIA', 'GAIA','GONDOMAR','VILA NOVA DE GAIA','VALONGO');
"""
cursor_psql.execute(sql_freguesias)
results_freguesias = cursor_psql.fetchall()

sql_stops = """
    SELECT ST_AsText(proj_stop_location) 
    FROM stops
"""
cursor_psql.execute(sql_stops)
results_stops = cursor_psql.fetchall()

cursor_psql.close()
conn.close()

freguesias_boundaries = {}
for freguesia, concelho, geom_wkt in results_freguesias:
    boundary_coords = []
    for part in geom_wkt.split('((')[1].split('))')[0].split(','):
        x, y = part.strip(')').split()
        boundary_coords.append((float(x), float(y)))
    if concelho not in freguesias_boundaries:
        freguesias_boundaries[concelho] = []
    freguesias_boundaries[concelho].append((freguesia, boundary_coords))

xs = []
ys = []
for row in results_stops:
    point_string = row[0]
    point_string = point_string[6:-1]  
    (x, y) = point_string.split()
    xs.append(float(x))
    ys.append(float(y))  

fig, ax = plt.subplots(figsize=(10, 8))

colors = ['blue', 'green', 'red', 'orange', 'purple', 'yellow', 'cyan']
for i, (concelho, freguesias) in enumerate(freguesias_boundaries.items()):
    for freguesia, boundary_coords in freguesias:
        x, y = zip(*boundary_coords)
        ax.plot(x, y, color=colors[i], label=concelho)

ax.scatter(xs, ys, color='black', s=0.25, label='Stop Locations')

ax.set_title('All bus stops within Porto Metropolitan Area')
ax.set_xlabel('Longitude')
ax.set_ylabel('Latitude')

# Creating a custom legend for concelhos
legend_handles = []
for concelho in freguesias_boundaries:
    legend_handles.append(plt.Line2D([0], [0], color=colors[len(legend_handles)], lw=2, label=concelho))
ax.legend(handles=legend_handles)

plt.show()
