CREATE TABLE routes (
    route_id INT PRIMARY KEY,
    route_short_name VARCHAR(255),
    route_long_name VARCHAR(255),
    route_type INT,
    route_url VARCHAR(255),
    route_color VARCHAR(6),
    route_text_color VARCHAR(6)
);