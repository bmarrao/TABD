import psycopg2
files = ['routes.txt','shapes.txt','stop_times.txt','stops.txt','transfers.txt','trips.txt']
conn = psycopg2.connect("dbname=postgres user=brenin")

with open("data/routes", 'r') as f:
# Read the file line by line
    for line in f:
        for field in line.split(","):
            

