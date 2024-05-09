import matplotlib.pyplot as plt 
import psycopg2

conn = psycopg2.connect("dbname=postgres user=brenin")
cursor_psql = conn.cursor()

sql = """
    SELECT freguesia, ST_AsText(ST_Simplify(proj_boundary, 0.5)) AS geom 
    FROM cont_aad_caop2018 
    WHERE concelho IN ('PORTO', 'MATOSINHOS', 'MAIA', 'GAIA', 'GONDOMAR', 'VILA NOVA DE GAIA');

"""
cursor_psql.execute(sql)
results = cursor_psql.fetchall()

cursor_psql.close()
conn.close()

fig, ax = plt.subplots(figsize=(10, 10))

for freguesia, geom_wkt in results:
    boundary_coords = []
    for part in geom_wkt.split('((')[1].split('))')[0].split(','):
        x, y = part.strip(')').split()
        boundary_coords.append((float(x), float(y)))
    
    x, y = zip(*boundary_coords)
    ax.plot(x, y, label=freguesia)

ax.set_title('Freguesias within the Municipality of Porto')
ax.set_xlabel('Longitude')
ax.set_ylabel('Latitude')

# Show plot
plt.show()
