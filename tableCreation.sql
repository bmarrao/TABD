DROP TABLE IF EXISTS agency;
DROP TABLE IF EXISTS stops;
DROP TABLE IF EXISTS routes;
DROP TABLE IF EXISTS calendar;
DROP TABLE IF EXISTS calendar_dates;
DROP TABLE IF EXISTS shapes;
DROP TABLE IF EXISTS stop_times;
DROP TABLE IF EXISTS transfers;
DROP TABLE IF EXISTS trips;


CREATE TABLE agency
(
  agency_id         TEXT UNIQUE NULL,
  agency_name       TEXT NOT NULL,
  agency_url        TEXT NOT NULL,
  agency_timezone   TEXT NOT NULL,
  agency_lang       TEXT NULL
);

CREATE TABLE stops
(
  stop_id           TEXT PRIMARY KEY,
  stop_code         TEXT NULL,
  stop_name         TEXT NOT NULL,
  stop_location     POINT NOT NULL, -- Use POINT data type for location
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
  start_date        NUMERIC(8) NOT NULL,
  end_date          NUMERIC(8) NOT NULL
);

CREATE TABLE calendar_dates
(
  service_id        TEXT NOT NULL,
  date              NUMERIC(8) NOT NULL,
  exception_type    INTEGER NOT NULL
);

CREATE TABLE shapes
(
  shape_id          TEXT,
  shape_pt_location POINT NOT NULL, -- Use POINT data type for location
  shape_pt_sequence INTEGER NOT NULL
);

CREATE TABLE stop_times
(
  trip_id           TEXT NOT NULL,
  arrival_time      INTERVAL NOT NULL,
  departure_time    INTERVAL NOT NULL,
  stop_id           TEXT NOT NULL,
  stop_sequence     INTEGER NOT NULL,
  stop_headsign     TEXT NULL
);

CREATE TABLE transfers
(
  from_stop_id      TEXT NOT NULL,
  to_stop_id        TEXT NOT NULL,
  transfer_type     INTEGER NOT NULL
);

CREATE TABLE trips
(
  route_id          text NOT NULL,
  service_id        text NOT NULL,
  trip_id           text NOT NULL PRIMARY KEY,
  trip_headsign     text NULL,
  direction_id      boolean NULL,
  block_id          text NULL,
  shape_id          text NULL,
  wheelchair_accessible text NULL
);
