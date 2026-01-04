USE WAREHOUSE BLUEJAY_WH;

CREATE OR REPLACE TABLE oag_schedule_staging AS
SELECT *
FROM OAG_GLOBAL_AIRLINE_SCHEDULES_SAMPLE.PUBLIC.OAG_SCHEDULE;


CREATE OR REPLACE TABLE dim_aircraft AS
SELECT
  ROW_NUMBER() OVER (ORDER BY aircraft_code) AS aircraft_key,
  aircraft_code,
  MAX(generic_aircraft)  AS generic_aircraft,
  MAX(in_plane_aircraft) AS in_plane_aircraft
FROM (
  SELECT
    EQUIPMENT_CD_ICAO AS aircraft_code,
    GENACFT           AS generic_aircraft,
    INPACFT           AS in_plane_aircraft
  FROM oag_schedule_staging
)
GROUP BY aircraft_code;


SELECT * FROM dim_aircraft;


CREATE OR REPLACE TABLE dim_carrier AS
SELECT
  ROW_NUMBER() OVER (ORDER BY carrier) AS carrier_key,
  carrier,
  carrier_cd_icao,
  operating,
  acft_owner
FROM (
  SELECT
    carrier,
    ANY_VALUE(carrier_cd_icao) AS carrier_cd_icao,
    ANY_VALUE(operating) AS operating,
    ANY_VALUE(acft_owner) AS acft_owner
  FROM oag_schedule_staging
  GROUP BY carrier
);

SELECT * FROM dim_carrier;


CREATE OR REPLACE TABLE dim_airport AS
SELECT
    ROW_NUMBER() OVER (ORDER BY airport_code) AS airport_key,
    airport_code,
    airport_icao,
    city,
    country,
    terminal
FROM (
    -- induló repülőterek
    SELECT DISTINCT
        DEPAPT AS airport_code,
        DEP_PORT_CD_ICAO AS airport_icao,
        DEPCITY AS city,
        DEPCTRY AS country,
        DEPTERM AS terminal
    FROM oag_schedule_staging
    WHERE DEPAPT IS NOT NULL

    UNION

    -- érkező repülőterek
    SELECT DISTINCT
        ARRAPT AS airport_code,
        ARR_PORT_CD_ICAO AS airport_icao,
        ARRCITY AS city,
        ARRCTRY AS country,
        ARRTERM AS terminal
    FROM oag_schedule_staging
    WHERE ARRAPT IS NOT NULL
);

select * from dim_airport;


//kontrola
SELECT carrier, COUNT() AS cnt
FROM dim_carrier
GROUP BY carrier
HAVING COUNT() > 1;


CREATE OR REPLACE TABLE dim_date AS
SELECT
  ROW_NUMBER() OVER (ORDER BY date) AS date_key,
  date,
  YEAR(date) AS year,
  MONTH(date) AS month,
  DAYNAME(date) AS weekday
FROM (
  SELECT DISTINCT FLIGHT_DATE AS date
  FROM oag_schedule_staging
);

SELECT * FROM dim_date;







CREATE OR REPLACE TABLE dim_route AS
SELECT
  ROW_NUMBER() OVER (ORDER BY dep_airport, arr_airport) AS route_key,
  dep_airport,
  dep_city,
  dep_country,
  arr_airport,
  arr_city,
  arr_country,
  distance,
  domestic_international
FROM (
  SELECT
    DEPAPT  AS dep_airport,
    MAX(DEPCITY) AS dep_city,
    MAX(DEPCTRY) AS dep_country,
    ARRAPT  AS arr_airport,
    MAX(ARRCITY) AS arr_city,
    MAX(ARRCTRY) AS arr_country,
    MAX(DISTANCE) AS distance,
    MAX(DOMINT) AS domestic_international
  FROM oag_schedule_staging
  GROUP BY DEPAPT, ARRAPT
);

SELECT * FROM dim_route;

CREATE OR REPLACE TABLE dim_time AS
SELECT
  ROW_NUMBER() OVER (ORDER BY time_hhmm) AS time_key,
  time_hhmm,
  hour,
  minute,
  CASE
    WHEN hour BETWEEN 5 AND 11 THEN 'Morning'
    WHEN hour BETWEEN 12 AND 17 THEN 'Afternoon'
    WHEN hour BETWEEN 18 AND 22 THEN 'Evening'
    ELSE 'Night'
  END AS time_bucket
FROM (
  SELECT DISTINCT
    DEPTIM AS time_hhmm,
    TO_NUMBER(SUBSTR(DEPTIM, 1, 2)) AS hour,
    TO_NUMBER(SUBSTR(DEPTIM, 3, 2)) AS minute
  FROM oag_schedule_staging
  WHERE LENGTH(DEPTIM) = 4

  UNION

  SELECT DISTINCT
    ARRTIM AS time_hhmm,
    TO_NUMBER(SUBSTR(ARRTIM, 1, 2)) AS hour,
    TO_NUMBER(SUBSTR(ARRTIM, 3, 2)) AS minute
  FROM oag_schedule_staging
  WHERE LENGTH(ARRTIM) = 4
);

select * from dim_time;

CREATE OR REPLACE TABLE fact_flights AS
SELECT
    -- surrogate keys
    ROW_NUMBER() OVER (ORDER BY s.flight_date, s.carrier, s.fltno) AS flight_key,
    d.date_key,
    t.time_key,
    c.carrier_key,
    r.route_key,
    a.aircraft_key,
    
    s.stops,
    s.total_seats,
    s.first_class_seats,
    s.business_class_seats,
    s.premium_economy_class_seats,
    s.economy_plus_class_seats,
    s.economy_class_seats
    
FROM oag_schedule_staging s

-- JOIN dim_date
JOIN dim_date d
  ON d.date = s.flight_date

JOIN dim_time t
  ON t.time_hhmm = s.deptim

-- JOIN dim_carrier
JOIN dim_carrier c
  ON c.carrier = s.carrier

-- JOIN dim_route
JOIN dim_route r
  ON r.dep_airport = s.depapt
 AND r.arr_airport = s.arrapt

-- JOIN dim_aircraft
JOIN dim_aircraft a
  ON a.aircraft_code = s.equipment_cd_icao;

select * from fact_flights;