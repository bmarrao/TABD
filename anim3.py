import psycopg2
import matplotlib.pyplot as plt

conn = psycopg2.connect("dbname=postgres user=Ricardo port=5434")

cursor = conn.cursor()

cursor.execute("SELECT zone_id, count(*) FROM stops group by zone_id order by zone_id")

zones_ids = cursor.fetchall()

cursor.close()
conn.close()

zones = [a[0] for a in zones_ids]
counts = [a[1] for a in zones_ids]

plt.figure(figsize=(10, 6))
plt.bar(zones, counts, color='blue')
plt.title('number of stops per zone')
plt.xlabel('Zones')
plt.ylabel('Frequency')
plt.show()
