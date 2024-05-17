DROP TABLE IF EXISTS dw_time CASCADE;
DROP TABLE IF EXISTS dw_taxi CASCADE;
DROP TABLE IF EXISTS dw_location CASCADE;
DROP TABLE IF EXISTS dw_facts CASCADE;

CREATE TABLE dw_time 
(
    time_id SERIAL PRIMARY KEY,
    hour INTEGER,
    date DATE,
    month INTEGER
);

CREATE TABLE dw_taxi 
(
    taxi_id CHARACTER(8) PRIMARY KEY
);

CREATE TABLE dw_location
(
    stop_id SERIAL PRIMARY KEY,
    location     geometry(Point),
    freguesia character varying(255),
    concelho character varying(255)
);


CREATE TABLE dw_facts (
    time_id INTEGER REFERENCES dw_time(time_id),
    taxi_id CHARACTER(8) REFERENCES dw_taxi(taxi_id),
    initial_stop INTEGER REFERENCES dw_location(initial_stop),
    final_stop INTEGER REFERENCES dw_location(final_stop),
    number_of_trips INTEGER,
    PRIMARY KEY (time_id, taxi_id, location_id)
);
