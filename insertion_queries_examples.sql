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


INSERT INTO dw_facts(time_id, taxi_id, location_id, number_of_trips)
SELECT tempo.time_id  , t.taxi , l.location_id, count(*) FROM tracks as t, dw_time as tempo, dw_location as l , taxi_stands as ts 
WHERE tempo.date = date (to_timestamp(initial_ts)) and tempo.hour =  (extract(hour from to_timestamp(initial_ts))) and  month  =extract(month from to_timestamp(initial_ts))
and 
GROUP BY 1, 2,3,;

select from taxi_

INSERT INTO dw_location (taxi_stand, freguesia, concelho)
SELECT tstand.id, o.freguesia, o.concelho
FROM cont_aad_caop2018 AS o
JOIN taxi_stands AS tstand ON ST_Within(tstand.proj_location, o.proj_boundary)
WHERE o.concelho = 'PORTO';

INSERT INTO dw_taxi (taxi_id)
SELECT DISTINCT taxi 
FROM tracks ;


INSERT INTO dw_time(hour, date, month)
SELECT DISTINCT (extract(hour from to_timestamp(initial_ts)), date (to_timestamp(initial_ts)),extract(month from to_timestamp(initial_ts)))
from taxi_services order by 1 desc;


SELECT 
    t.time_id,
    ts.taxi_id,
    l.location_id,
    COUNT(*) AS number_of_trips
FROM 
    dw_taxi t
JOIN 
    dw_time t ON date(to_timestamp(ts.initial_ts)) = t.date
JOIN 
    dw_location l ON ts.location = l.taxi_stand
GROUP BY 
    t.time_id, ts.taxi_id, l.location_id;

SELECT t.time_id , ta.taxi_id, l.location_id from dw_time as t, dw_taxi as ta, dw_location  as l GROUP BY t.time_id, ta.taxi_id, l.location_id;

