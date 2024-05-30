import psycopg2
import matplotlib.pyplot as plt

conn = psycopg2.connect("dbname=postgres user=brenin")

cursor = conn.cursor()

cursor.execute("SELECT trips.service_id, count(*) FROM trips JOIN calendar ON trips.service_id = calendar.service_id GROUP BY trips.service_id;")

data = cursor.fetchall()


service_ids = [row[0] for row in data]
counts = [row[1] for row in data]

print(data)
print(service_ids)
print(counts)

plt.figure(figsize=(10, 6))
plt.bar(service_ids, counts, color='blue')
plt.title('Ocasions when there are more buses')
plt.xlabel('Ocasion')
plt.ylabel('Frequency')
plt.draw()
plt.show()

cursor.close()
conn.close()
