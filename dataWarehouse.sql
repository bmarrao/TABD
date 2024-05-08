CREATE TABLE dw_time (
    time_id SERIAL PRIMARY KEY,
    hour INTEGER,
    date DATE,
    month INTEGER
);

CREATE TABLE dw_taxi (
    taxi_id CHARACTER(8) PRIMARY KEY
);

CREATE TABLE dw_location (
    location_id SERIAL PRIMARY KEY,
    taxi_stand INTEGER,
    freguesia character varying(255),
    concelho character varying(255)
);

CREATE TABLE dw_facts (
    time_id INTEGER REFERENCES dw_time(time_id),
    taxi_id CHARACTER(8) REFERENCES dw_taxi(taxi_id),
    location_id INTEGER REFERENCES dw_location(location_id),
    number_of_trips INTEGER,
    PRIMARY KEY (time_id, taxi_id, location_id)
);
