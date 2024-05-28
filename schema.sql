DROP TABLE IF EXISTS transfers CASCADE;
DROP TABLE IF EXISTS stop_times CASCADE;
DROP TABLE IF EXISTS trips CASCADE;
DROP TABLE IF EXISTS calendar_dates CASCADE;
DROP TABLE IF EXISTS calendar CASCADE;
DROP TABLE IF EXISTS routes CASCADE;
DROP TABLE IF EXISTS stops CASCADE;
DROP TABLE IF EXISTS shapes CASCADE;

CREATE TABLE stops
(
  stop_id           TEXT PRIMARY KEY,
  stop_code         TEXT NULL,
  stop_name         TEXT NOT NULL,
  stop_location     geometry(Point,4326),
  zone_id           TEXT NULL,
  stop_url          TEXT NULL
);

CREATE TABLE routes
( 
  route_id          TEXT PRIMARY KEY,
  route_short_name  TEXT NULL,
  route_long_name   TEXT NULL,
  route_desc        TEXT NULL,
  route_type        INTEGER NULL,
  route_url         TEXT NULL,
  route_color       TEXT NULL,
  route_text_color  TEXT NULL
);

CREATE TABLE calendar
(
  service_id        TEXT PRIMARY KEY,
  monday            BOOLEAN NOT NULL,
  tuesday           BOOLEAN NOT NULL,
  wednesday         BOOLEAN NOT NULL,
  thursday          BOOLEAN NOT NULL,
  friday            BOOLEAN NOT NULL,
  saturday          BOOLEAN NOT NULL,
  sunday            BOOLEAN NOT NULL,
  start_date        DATE NOT NULL,
  end_date          DATE NOT NULL
);

CREATE TABLE calendar_dates
(
  service_id        TEXT NOT NULL,
  date              DATE NOT NULL,
  exception_type    INTEGER NOT NULL,
  PRIMARY KEY (service_id, date),
  FOREIGN KEY (service_id) REFERENCES calendar(service_id)
);

CREATE TABLE shapes
(
  shape_id          TEXT PRIMARY KEY,
  shape_linestring geometry(LineString, 4326)
);

CREATE TABLE trips
(
  trip_id           TEXT PRIMARY KEY,
  route_id          TEXT NOT NULL,
  service_id        TEXT NOT NULL,
  trip_headsign     TEXT NULL,
  direction_id      BOOLEAN NULL,
  block_id          TEXT NULL,
  shape_id          TEXT NULL,
  wheelchair_accessible TEXT NULL,
  FOREIGN KEY (route_id) REFERENCES routes(route_id),
  FOREIGN KEY (service_id) REFERENCES calendar(service_id),
  FOREIGN KEY (shape_id) REFERENCES shapes(shape_id)
);

CREATE TABLE stop_times
(
  trip_id           TEXT NOT NULL,
  arrival_time      TIME NOT NULL,
  departure_time    TIME NOT NULL,
  stop_id           TEXT NOT NULL,
  stop_sequence     INTEGER NOT NULL,
  stop_headsign     TEXT NULL,
  PRIMARY KEY (trip_id, stop_sequence),
  FOREIGN KEY (trip_id) REFERENCES trips(trip_id),
  FOREIGN KEY (stop_id) REFERENCES stops(stop_id)
);

CREATE TABLE transfers
(
  from_stop_id      TEXT NOT NULL,
  to_stop_id        TEXT NOT NULL,
  transfer_type     INTEGER NOT NULL,
  PRIMARY KEY (from_stop_id, to_stop_id),
  FOREIGN KEY (from_stop_id) REFERENCES stops(stop_id),
  FOREIGN KEY (to_stop_id) REFERENCES stops(stop_id)
);

alter table shapes add proj_linestring geometry(LineString,3763);
update shapes set proj_linestring = st_transform(shape_linestring::geometry,3763);

alter table stops add proj_stop_location geometry(Point,3763);
update stops set proj_stop_location = st_transform(stop_location::geometry,3763);

