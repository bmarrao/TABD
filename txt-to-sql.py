import psycopg2
from datetime import time, datetime, timedelta, date

#psql -U brenin -d postgres
# Connect to the database
conn = psycopg2.connect("dbname=postgres user=brenin")
cursor = conn.cursor()


def normalize_time(time_str):
    hours, minutes, seconds = map(int, time_str.split(':'))
    if hours >= 24:
        excess_hours = hours % 24
        excess_days = hours // 24
        excess_time = timedelta(hours=excess_hours, minutes=minutes, seconds=seconds)
        today = date.today()
        normalized_time = datetime.combine(today, time(0, 0)) + excess_time
        return normalized_time.time()
    else:
        return time(hours, minutes, seconds)



with open("data/stops.txt", 'r') as f:
    next(f)  # Skip the header line
    for line in f:
        fields = line.strip().split(",")
        stop_id = fields[0]
        stop_code = fields[1]
        stop_name = fields[2]
        stop_lat = float(fields[3])
        stop_lon = float(fields[4])
        zone_id = fields[5]
        stop_url = fields[6]
        cursor.execute(
            """
            INSERT INTO stops (stop_id, stop_code, stop_name, stop_location, zone_id, stop_url) 
            VALUES (%s, %s, %s, ST_GeomFromText('POINT(%s %s)', 4326), %s, %s)
            """, 
            (stop_id, stop_code, stop_name, stop_lon, stop_lat, zone_id, stop_url)
        )
conn.commit()

with open("data/routes.txt", 'r') as f:
    next(f)
    for line in f:
        fields = line.strip().split(",")
        route_id = fields[0]
        route_short_name = fields[1]
        route_long_name = fields[2]
        route_type = int(fields[4])
        route_url = fields[5]
        route_color = fields[6]
        route_text_color = fields[7]
        cursor.execute("INSERT INTO routes (route_id, route_short_name, route_long_name, route_type, route_url, route_color, route_text_color) VALUES (%s, %s, %s, %s, %s, %s, %s)", (route_id, route_short_name, route_long_name, route_type, route_url, route_color, route_text_color))
conn.commit()

with open("data/calendar.txt", 'r') as f:
    next(f)
    for line in f:
        fields = line.strip().split(",")
        service_id = fields[0]
        monday = fields[1] == "1"
        tuesday = fields[2] == "1"
        wednesday = fields[3] == "1"
        thursday = fields[4] == "1"
        friday = fields[5] == "1"
        saturday = fields[6] == "1"
        sunday = fields[7] == "1"
        start_date_str = fields[8]
        end_date_str = fields[9]
        start_date = datetime.strptime(start_date_str, "%Y%m%d").date()
        end_date = datetime.strptime(end_date_str, "%Y%m%d").date()
        cursor.execute("INSERT INTO calendar (service_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, start_date, end_date) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", (service_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, start_date, end_date))
conn.commit()

with open("data/shapes.txt", 'r') as f:
        next(f) 
        shape_id = None
        shape_points = []

        for line in f:
            fields = line.strip().split(",")
            current_shape_id = fields[0]
            shape_pt_lat = float(fields[1])
            shape_pt_lon = float(fields[2])

            if current_shape_id != shape_id:
                if shape_points:
                    linestring = "LINESTRING(" + ",".join([f"{lat} {lon}" for lat, lon in shape_points]) + ")"
                    cursor.execute(
                        "INSERT INTO shapes (shape_id, shape_linestring) VALUES (%s, ST_GeomFromText(%s, 4326))",
                        (shape_id, linestring)
                    )
                shape_id = current_shape_id
                shape_points = []

            shape_points.append((shape_pt_lon, shape_pt_lat))

        if shape_points:
            linestring = "LINESTRING(" + ",".join([f"{lat} {lon}" for lat, lon in shape_points]) + ")"
            cursor.execute(
                "INSERT INTO shapes (shape_id, shape_linestring) VALUES (%s, ST_GeomFromText(%s, 4326))",
                (shape_id, linestring)
            )

conn.commit()


with open("data/transfers.txt", 'r') as f:

    next(f)
    for line in f:
        fields = line.strip().split(",")
        from_stop_id = fields[0]
        to_stop_id = fields[1]
        transfer_type = int(fields[2])

        cursor.execute("INSERT INTO transfers (from_stop_id, to_stop_id, transfer_type) VALUES (%s, %s, %s)", (from_stop_id, to_stop_id, transfer_type))
conn.commit()

with open("data/calendar_dates.txt", 'r') as f:
    next(f)
    for line in f:
        fields = line.strip().split(",")
        service_id = fields[0]
        date_str = fields[1]
        exception_type = int(fields[2])
        date = datetime.strptime(date_str, "%Y%m%d").date()
        cursor.execute("INSERT INTO calendar_dates (service_id, date, exception_type) VALUES (%s, %s, %s)", (service_id, date, exception_type))
conn.commit()

with open("data/trips.txt", 'r') as f:

    next(f)

    for line in f:
        route_id, direction_id, service_id, trip_id, trip_headsign, wheelchair_accessible, block_id, shape_id = line.strip().split(",")
        
        direction_id = bool(int(direction_id))
        
        wheelchair_accessible = bool(int(wheelchair_accessible))
        
        block_id = block_id if block_id else None
        shape_id = shape_id if shape_id else None
        
        cursor.execute("INSERT INTO trips (route_id, direction_id, service_id, trip_id, trip_headsign, wheelchair_accessible, block_id, shape_id) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)", (route_id, direction_id, service_id, trip_id, trip_headsign, wheelchair_accessible, block_id, shape_id))

conn.commit()

with open("data/stop_times.txt", 'r') as f:
    next(f)
    for line in f:
        fields = line.strip().split(",")
        trip_id = fields[0]
        arrival_time_str = fields[1]
        departure_time_str = fields[2]
        stop_id = fields[3]
        stop_sequence = int(fields[4])
        stop_headsign = fields[5] if len(fields) > 5 else None
        arrival_time = normalize_time(arrival_time_str)
        departure_time = normalize_time(departure_time_str)
        cursor.execute("INSERT INTO stop_times (trip_id, arrival_time, departure_time, stop_id, stop_sequence, stop_headsign) VALUES (%s, %s, %s, %s, %s, %s)", (trip_id, arrival_time, departure_time, stop_id, stop_sequence, stop_headsign))

conn.commit()



conn.commit()
conn.close()
