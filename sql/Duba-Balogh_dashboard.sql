-- Graf 1: Počet letov podľa hodiny
WITH flights_per_hour AS (
    SELECT
        t.hour,
        COUNT(*) AS total_flights
    FROM fact_flights f
    JOIN dim_time t
      ON f.time_key = t.time_key
    GROUP BY t.hour
)

SELECT
    hour,
    total_flights,
    RANK() OVER (ORDER BY total_flights DESC) AS rank_by_flights
FROM flights_per_hour
ORDER BY TO_NUMBER(hour) ASC;

-- Graf 2: Top 5 leteckých dopravcov podľa kapacity sedadiel
WITH carrier_seats AS (
    SELECT
        c.carrier,
        SUM(COALESCE(f.total_seats, 0)) AS total_seats,
        SUM(COALESCE(f.first_class_seats, 0)) AS first_class,
        SUM(COALESCE(f.business_class_seats, 0)) AS business_class,
        SUM(COALESCE(f.premium_economy_class_seats, 0)) AS premium_economy,
        SUM(COALESCE(f.economy_plus_class_seats, 0)) AS economy_plus,
        SUM(COALESCE(f.economy_class_seats, 0)) AS economy
    FROM fact_flights f
    JOIN dim_carrier c
      ON c.carrier_key = f.carrier_key
    GROUP BY c.carrier
)

SELECT *
FROM carrier_seats
QUALIFY RANK() OVER (ORDER BY total_seats DESC) <= 5
ORDER BY total_seats ASC;

-- Graf 3: Top 5 leteckých dopravcov podľa počtu letov
SELECT
  carrier,
  flights,
  flights * 100.0 / SUM(flights) OVER () AS pct_of_all_flights
FROM (
  SELECT
    c.carrier,
    COUNT(*) AS flights
  FROM fact_flights f
  JOIN dim_carrier c ON f.carrier_key = c.carrier_key
  GROUP BY c.carrier
  order by flights DESC
  LIMIT 5
);

--Graf 4: Top 5 cieľových miest podľa počtu príletov
SELECT
  carrier,
  flights,
  flights * 100.0 / SUM(flights) OVER () AS pct_of_all_flights
FROM (
  SELECT
    c.carrier,
    COUNT(*) AS flights
  FROM fact_flights f
  JOIN dim_carrier c ON f.carrier_key = c.carrier_key
  GROUP BY c.carrier
  order by flights DESC
  LIMIT 5
);
SELECT city, flight_count, city_rank
FROM (
  SELECT
    r.arr_city AS city,
    COUNT(*) AS flight_count,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS city_rank
  FROM fact_flights f
  JOIN dim_route r ON f.route_key = r.route_key
  GROUP BY r.arr_city
)
WHERE city_rank <= 5
ORDER BY city_rank;

--Graf 5: Typy lietadiel podľa leteckých dopravcov
WITH carrier_aircraft AS (
    SELECT
        c.carrier,
        a.generic_aircraft AS aircraft_type,
        COUNT(DISTINCT f.aircraft_key) AS num_aircraft
    FROM fact_flights f
    JOIN dim_carrier c
      ON c.carrier_key = f.carrier_key
    JOIN dim_aircraft a
      ON a.aircraft_key = f.aircraft_key
    GROUP BY c.carrier, a.generic_aircraft
),
carrier_totals AS (
    SELECT
        carrier,
        SUM(num_aircraft) AS total_aircraft
    FROM carrier_aircraft
    GROUP BY carrier
    QUALIFY RANK() OVER (ORDER BY total_aircraft DESC) <= 5
)

SELECT
    ca.carrier,
    ca.aircraft_type,
    ca.num_aircraft,
    ct.total_aircraft
FROM carrier_aircraft ca
JOIN carrier_totals ct
  ON ca.carrier = ct.carrier
ORDER BY ct.total_aircraft DESC, ca.num_aircraft DESC;

--Graf 6: Trasy z Londýna s najväčšou kapacitou sedadiel
SELECT
  from_city,
  to_city,
  total_seats,
  seat_rank
FROM (
  SELECT
    r.dep_city AS from_city,
    r.arr_city AS to_city,
    SUM(COALESCE(f.total_seats, 0)) AS total_seats,
    RANK() OVER (
      ORDER BY SUM(COALESCE(f.total_seats, 0)) DESC
    ) AS seat_rank
  FROM fact_flights f
  JOIN dim_route r 
    ON f.route_key = r.route_key
  WHERE r.dep_city = 'LON'
    AND r.dep_city <> r.arr_city
  GROUP BY r.dep_city, r.arr_city
)
WHERE seat_rank <= 5
ORDER BY total_seats ASC;
