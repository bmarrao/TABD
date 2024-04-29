import psycopg2

# Connect to the database
conn = psycopg2.connect("dbname=postgres user=brenin")
cursor = conn.cursor()

with open("data/shapes.txt", 'r') as f:
    # Skip the header line
    next(f)
    # Read the file line by line
    for line in f:
        # Split the line into fields
        fields = line.strip().split(",")
        # Extract values for each field
        shape_id = fields[0]
        shape_pt_lat = float(fields[1])
        shape_pt_lon = float(fields[2])
        shape_pt_sequence = int(fields[3])
        
        # Insert values into the database
        cursor.execute("INSERT INTO shapes (shape_id, shape_pt_location, shape_pt_sequence) VALUES (%s, ST_SetSRID(ST_MakePoint(%s, %s), 4326)::POINT, %s)", (shape_id, shape_pt_lon, shape_pt_lat, shape_pt_sequence))


with open("data/routes.txt", 'r') as f:
    # Skip the header line
    next(f)
    # Read the file line by line
    for line in f:
        # Split the line into fields
        fields = line.strip().split(",")
        # Extract values for each field
        route_id = fields[0]
        route_short_name = fields[1]
        route_long_name = fields[2]
        route_type = int(fields[4])
        route_url = fields[5]
        route_color = fields[6]
        route_text_color = fields[7]
        
        # Insert values into the database
        cursor.execute("INSERT INTO routes (route_id, route_short_name, route_long_name, route_type, route_url, route_color, route_text_color) VALUES (%s, %s, %s, %s, %s, %s, %s)", (route_id, route_short_name, route_long_name, route_type, route_url, route_color, route_text_color))

with open("data/stops.txt", 'r') as f:
    # Skip the header line
    next(f)
    # Read the file line by line
    for line in f:
        # Split the line into fields
        fields = line.strip().split(",")
        # Extract values for each field
        stop_id = fields[0]
        stop_code = fields[1]
        stop_name = fields[2]
        stop_lat = float(fields[3])
        stop_lon = float(fields[4])
        zone_id = fields[5]
        stop_url = fields[6]
        
        # Insert values into the database
        cursor.execute("INSERT INTO stops (stop_id, stop_code, stop_name,  stop_location, zone_id, stop_url) VALUES (%s, %s, %s, ST_SetSRID(ST_MakePoint(%s, %s), 4326), %s, %s)", (stop_id, stop_code, stop_name, stop_lon, stop_lat, zone_id, stop_url))

with open("data/calendar.txt", 'r') as f:
    # Skip the header line
    next(f)
    # Read the file line by line
    for line in f:
        # Split the line into fields
        fields = line.strip().split(",")
        # Extract values for each field
        service_id = fields[0]
        monday = fields[1] == "1"
        tuesday = fields[2] == "1"
        wednesday = fields[3] == "1"
        thursday = fields[4] == "1"
        friday = fields[5] == "1"
        saturday = fields[6] == "1"
        sunday = fields[7] == "1"
        start_date = int(fields[8])
        end_date = int(fields[9])
        
        # Insert values into the database
        cursor.execute("INSERT INTO calendar (service_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, start_date, end_date) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", (service_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, start_date, end_date))

with open("data/calendar_dates.txt", 'r') as f:
    # Skip the header line
    next(f)
    # Read the file line by line
    for line in f:
        # Split the line into fields
        fields = line.strip().split(",")
        # Extract values for each field
        service_id = fields[0]
        date = int(fields[1])
        exception_type = int(fields[2])
        
        # Insert values into the database
        cursor.execute("INSERT INTO calendar_dates (service_id, date, exception_type) VALUES (%s, %s, %s)", (service_id, date, exception_type))

with open("data/stop_times.txt", 'r') as f:
    # Skip the header line
    next(f)
    # Read the file line by line
    for line in f:
        # Split the line into fields
        fields = line.strip().split(",")
        # Extract values for each field
        trip_id = fields[0]
        arrival_time = fields[1]
        departure_time = fields[2]
        stop_id = fields[3]
        stop_sequence = int(fields[4])
        stop_headsign = fields[5] if len(fields) > 5 else None
        
        # Insert values into the database
        cursor.execute("INSERT INTO stop_times (trip_id, arrival_time, departure_time, stop_id, stop_sequence, stop_headsign) VALUES (%s, %s, %s, %s, %s, %s)", (trip_id, arrival_time, departure_time, stop_id, stop_sequence, stop_headsign))

with open("data/transfers.txt", 'r') as f:
    # Skip the header line
    next(f)
    # Read the file line by line
    for line in f:
        # Split the line into fields
        fields = line.strip().split(",")
        # Extract values for each field
        from_stop_id = fields[0]
        to_stop_id = fields[1]
        print(fields[2])
        transfer_type = int(fields[2])

        # Insert values into the database
        cursor.execute("INSERT INTO transfers (from_stop_id, to_stop_id, transfer_type) VALUES (%s, %s, %s)", (from_stop_id, to_stop_id, transfer_type))

# Commit changes and close connection
conn.commit()
conn.close()
