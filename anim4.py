import psycopg2
import matplotlib.pyplot as plt

conn = psycopg2.connect("dbname=postgres user=brenin")

cursor = conn.cursor()

cursor.execute("SELECT s.zone_id, COUNT(*) AS visit_count FROM stop_times st JOIN stops s ON st.stop_id = s.stop_id GROUP BY s.zone_id Order by s.zone_id;")

data = cursor.fetchall()

stops = {}

zone_ids = [row[0] for row in data]
counts = [row[1] for row in data]

print(stops)

plt.figure(figsize=(10, 6))
plt.bar(zone_ids, counts, color='blue')
plt.title('number of times a buses stop in a zone')
plt.xlabel('zones')
plt.ylabel('Frequency')
plt.draw()
plt.show()

cursor.close()
conn.close()