import matplotlib.pyplot as plt 
import psycopg2

conn = psycopg2.connect("dbname=postgres user=brenin")
cursor_psql = conn.cursor()


sql_freguesias = """
    SELECT freguesia, ST_AsText(ST_Simplify(proj_boundary, 0.5)) AS geom 
    FROM cont_aad_caop2018 
    WHERE concelho IN ('PORTO', 'MATOSINHOS', 'MAIA', 'GAIA','GONDOMAR','VILA NOVA DE GAIA','VALONGO');

"""
cursor_psql.execute(sql_freguesias)
results_freguesias = cursor_psql.fetchall()

sql_stops = """
    SELECT ST_AsText(ST_Transform(ST_SetSRID(stop_location::geometry, 4326), 3763)) 
    FROM stops
"""
cursor_psql.execute(sql_stops)
results_stops = cursor_psql.fetchall()

cursor_psql.close()
conn.close()

freguesias_boundaries = []
for freguesia, geom_wkt in results_freguesias:
    boundary_coords = []
    for part in geom_wkt.split('((')[1].split('))')[0].split(','):
        x, y = part.strip(')').split()
        boundary_coords.append((float(x), float(y)))
    freguesias_boundaries.append(boundary_coords)

xs = []
ys = []
for row in results_stops:
    point_string = row[0]
    point_string = point_string[6:-1]  
    (x, y) = point_string.split()
    xs.append(float(x))
    ys.append(float(y))  

fig, ax = plt.subplots(figsize=(10, 8))

for boundary_coords in freguesias_boundaries:
    x, y = zip(*boundary_coords)
    ax.plot(x, y, color='blue')

ax.scatter(xs, ys, color='red', s=5, label='Stop Locations')

ax.set_title('Freguesias within the Municipality of Porto with Stop Locations')
ax.set_xlabel('Longitude')
ax.set_ylabel('Latitude')
ax.legend()

# Show plot
plt.show()
