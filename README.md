# **ELT proces datasetu OAG: Global Airline Schedules (Sample)**

Tento projekt predstavuje implementáciu ELT procesu v cloudovom dátovom sklade Snowflake s využitím datasetu OAG: Global Airline Schedules (Sample), ktorý je dostupný prostredníctvom Snowflake Marketplace. Cieľom projektu je návrh a realizácia dátového skladu so schémou Star Schema, ktorý umožňuje efektívnu analytickú prácu nad leteckými prevádzkovými dátami a podporuje analytické scenáre zamerané na kapacitu letov, frekvenciu spojení a porovnanie leteckých dopravcov a trás.


---



## **1. Úvod a popis zdrojových dát**
Projekt využíva dataset OAG: Global Airline Schedules (Sample), ktorý je dostupný prostredníctvom Snowflake Marketplace. Dataset poskytuje aktuálne a historické informácie o plánovaných leteckých spojeniach po celom svete a je určený na analytické a rozhodovacie účely.

- Dataset bol zvolený z týchto dôvodov:

- pochádza z dôveryhodného a komerčne používaného zdroja (OAG),

- obsahuje reálne prevádzkové údaje o letoch a kapacitách,

- je vhodný na analytiku v oblasti dopravy, logistiky a mobility,

- umožňuje jednoduchý návrh dimenzionálneho modelu (Star Schema).

- Použitá verzia datasetu je sample dataset, ktorý obsahuje všetky globálne odlety v jednom konkrétnom dni – 5. januára 2023.
---

## **1.1. Dátová architektúra**
Zdrojové dáta pochádzajú zo Snowflake Marketplace a sú uložené v jednej hlavnej tabuľke OAG_SCHEDULE, ktorá obsahuje informácie o letoch, dopravcoch, letiskách, kapacite sedadiel a časových atribútoch. Táto tabuľka má denormalizovanú štruktúru a slúžila ako východiskový bod pre návrh dimenzionálneho modelu.

Na základe analýzy tejto tabuľky boli identifikované jednotlivé entity (dopravca, letisko, dátum, trasa), ktoré boli následne rozdelené do dimenzionálnych tabuliek a faktovej tabuľky.
<p align="center">
  <img src="https://github.com/Halalos/Balogh-Duba_projekt/blob/master/img/table.png" alt="Hlavna tabuka">
  <br>
  <em>Obrázok 1 Hlavná tabuľka OAG: Global Airline Schedules (Sample)</em>
</p>

### **ERD diagram**
Surové dáta sú uložené v jednej zdrojovej tabuľke, ktorá obsahuje informácie o letoch, dopravcoch, letiskách a časových atribútoch. Na základe tejto tabuľky bol vytvorený ERD diagram, ktorý slúžil ako východisko pre návrh dimenzionálneho modelu.

<p align="center">
  <img src="https://github.com/Halalos/Balogh-Duba_projekt/blob/master/img/ERD.png" alt="ERD Schema">
  <br>
  <em>Obrázok 2 Entitno-relačná schéma OAG: Global Airline Schedules (Sample)</em>
</p>

---

## **2 Dimenzionálny model**

V projekte bola navrhnutá schéma hviezdy (Star Schema) podľa Kimballovej metodológie, ktorej cieľom je podporiť analytické dotazy nad dátami o leteckých spojeniach. Centrálna faktová tabuľka fact_flights reprezentuje jednotlivé lety a je prepojená s nasledujúcimi dimenziami:
- dim_carrier – obsahuje informácie o leteckých spoločnostiach, ako sú názov dopravcu, ICAO kód, prevádzkovateľ a vlastník lietadiel.

- dim_route – popisuje trasu letu vrátane odletového a príletového letiska, miest, krajín, vzdialenosti a typu letu (vnútroštátny / medzinárodný).

- dim_airport – obsahuje údaje o letiskách, ako je kód letiska, mesto, krajina a terminál.

- dim_aircraft – poskytuje informácie o type lietadla a jeho konfigurácii.

- dim_date – slúži ako časová dimenzia pre analýzu podľa dátumu, mesiaca, roku a dňa v týždni.

- dim_time – obsahuje detailné časové údaje, ako hodina, minúta a časový interval dňa.

Faktová tabuľka fact_flights obsahuje okrem cudzích kľúčov na jednotlivé dimenzie aj hlavné metriky, ako je počet sedadiel podľa tried, počet medzipristátí a vzdialenosť letu. Súčasťou faktovej tabuľky je aj použitie analytickej (window) funkcie na výpočet kumulatívnej kapacity sedadiel podľa leteckého dopravcu.

Štruktúra hviezdicového modelu je znázornená na diagrame nižšie, ktorý ilustruje vzťahy medzi faktovou tabuľkou a jednotlivými dimenziami a uľahčuje pochopenie navrhnutého dátového skladu.

<p align="center">
  <img src="https://github.com/Halalos/Balogh-Duba_projekt/blob/master/img/ERD_star_schema.png" alt="Star Schema">
  <br>
  <em>Obrázok 3 Schéma hviezdy pre OAG: Global Airline Schedules (Sample)</em>
</p>

---


## **3. ELT proces v Snowflake**
Spracovanie dát v projekte prebiehalo pomocou prístupu ELT, ktorý bol realizovaný priamo v prostredí Snowflake. Celý proces zahŕňa tri základné kroky:

- Extract – získanie zdrojových dát zo Snowflake Marketplace,

- Load – uloženie surových dát do staging tabuľky,

- Transform – úprava a premena dát do analytickej štruktúry hviezdicového modelu.

### **3.1 Extract (Extrahovanie dát)**
V prvej fáze ELT procesu boli dáta prevzaté zo zdieľaného datasetu dostupného v Snowflake Marketplace. Hlavná tabuľka so zdrojovými dátami bola skopírovaná do vlastného prostredia pomocou projektového warehouse BLUEJAY_WH. Táto staging tabuľka následne slúžila ako hlavný zdroj dát pre všetky ďalšie kroky spracovania a transformácie v projekte.

---
### **3.2 Load (Načítanie dát)**
V tejto fáze bola vytvorená samostatná staging tabuľka oag_schedule_staging, do ktorej boli načítané všetky dáta zo zdrojovej tabuľky dostupnej v Snowflake Marketplace. Táto tabuľka obsahuje kompletné surové dáta a slúžila ako jednotný vstup pre tvorbu dimenzií a faktovej tabuľky v ďalšej fáze spracovania.
#### Príklad kódu:
```sql
USE WAREHOUSE BLUEJAY_WH;

CREATE OR REPLACE TABLE oag_schedule_staging AS
SELECT *
FROM OAG_GLOBAL_AIRLINE_SCHEDULES_SAMPLE.PUBLIC.OAG_SCHEDULE;
```

---

### **3.3 Transfor (Transformácia dát)**
V tejto fáze boli dáta zo staging tabuliek vyčistené, transformované a obohatené. Hlavným cieľom bolo pripraviť dimenzie a faktovú tabuľku, ktoré umožnia jednoduchú a efektívnu analýzu.

Dimenzia 'dim_aircraft' obsahuje informácie o lietadlách použitých pri letoch, ako je kód lietadla, jeho typ a konfigurácia interiéru. Slúži na analýzu letov podľa použitých typov lietadiel. Ide o dimenziu 'typu SCD 1', keďže historické zmeny nie sú sledované.

#### Príklad kódu:
```sql
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
```
Dimenzia 'dim_carrier' obsahuje údaje o leteckých spoločnostiach, ktoré prevádzkujú lety. Zahŕňa názov dopravcu, jeho ICAO kód a vlastníka lietadla. Umožňuje analyzovať lety podľa jednotlivých dopravcov. Dimenzia je 'typu SCD 1'.

#### Príklad kódu:
```sql
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
```
Dimenzia 'dim_airport' uchováva informácie o letiskách, ako sú ich kódy, mesto, krajina a terminál. Používa sa na analýzu letov z pohľadu konkrétnych letísk alebo geografických oblastí. Ide o dimenziu 'typu SCD 1'.

#### Príklad kódu:
```sql
CREATE OR REPLACE TABLE dim_airport AS
SELECT
    ROW_NUMBER() OVER (ORDER BY airport_code) AS airport_key,
    airport_code,
    airport_icao,
    city,
    country,
    terminal
FROM (
    SELECT DISTINCT
        DEPAPT AS airport_code,
        DEP_PORT_CD_ICAO AS airport_icao,
        DEPCITY AS city,
        DEPCTRY AS country,
        DEPTERM AS terminal
    FROM oag_schedule_staging
    WHERE DEPAPT IS NOT NULL

    UNION

    SELECT DISTINCT
        ARRAPT AS airport_code,
        ARR_PORT_CD_ICAO AS airport_icao,
        ARRCITY AS city,
        ARRCTRY AS country,
        ARRTERM AS terminal
    FROM oag_schedule_staging
    WHERE ARRAPT IS NOT NULL
);
```
Dimenzia 'dim_date' poskytuje časový kontext pre fakty v databáze. Obsahuje dátum, rok, mesiac a deň v týždni. Slúži na časové analýzy a je statická '(SCD 0)'.

#### Príklad kódu:
```sql
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
```

Dimenzia 'dim_route' popisuje letové trasy medzi odletovým a príletovým letiskom. Obsahuje informácie o vzdialenosti a type letu (vnútroštátny alebo medzinárodný). Dimenzia je denormalizovaná kvôli zjednodušeniu analytických dotazov a je 'typu SCD 1'.

#### Príklad kódu:
```sql
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
```

Dimenzia 'dim_time' obsahuje informácie o čase odletu alebo príletu, vrátane hodiny, minúty a časovej časti dňa (ráno, popoludnie, večer, noc). Umožňuje analyzovať lety podľa času počas dňa. Ide o 'SCD 0' dimenziu.

#### Príklad kódu:
```sql
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
```
Faktová tabuľka 'fact_flights' obsahuje údaje o jednotlivých letoch a ich kapacitách. Každý záznam predstavuje jeden let a je prepojený s dimenziami pomocou kľúčov. Slúži na analytické spracovanie údajov o letoch.

#### Príklad kódu:
```sql
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
```

---
## **4 Vizualizácia dát**
Dashboard obsahuje celkovo 6 vizualizácií, ktoré prezentujú údaje o letoch z rôznych analytických pohľadov.
<p align="center">
  <img src="https://github.com/Halalos/Balogh-Duba_projekt/blob/master/img/Vizualizacie.png" alt="Vizualizacie">
  <br>
  <em>Obrázok 4 Dashboard OAG: Global Airline Schedules (Sample) datasetu</em>
</p>

---

### **Graf 1: Počet letov podľa hodiny**
Táto vizualizácia zobrazuje rozloženie počtu letov počas dňa a umožňuje identifikovať časové intervaly s najvyššou a najnižšou intenzitou letovej prevádzky.

```sql
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
```
---
### **Graf 2: Top 5 leteckých dopravcov podľa kapacity sedadiel**
Vizualizácia porovnáva päť najväčších leteckých spoločností podľa celkového počtu ponúkaných sedadiel, rozdelených podľa tried (economy, business, first class a pod.).

```sql
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
```
---
### **Graf 3: Top 5 leteckých dopravcov podľa počtu letov**
Táto vizualizácia zobrazuje letecké spoločnosti, ktoré prevádzkujú najväčší počet letov, a umožňuje porovnanie ich aktivity.

```sql
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
```
---

### **Graf 4: Top 5 cieľových miest podľa počtu príletov**
Vizualizácia identifikuje mestá, do ktorých smeruje najväčší počet letov, čím poukazuje na najvyťaženejšie destinácie.

```sql
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
```
---
### **Graf 5: Typy lietadiel podľa leteckých dopravcov**
Táto vizualizácia zobrazuje rozdelenie typov lietadiel používaných jednotlivými dopravcami a poskytuje prehľad o štruktúre ich flotíl.

```sql
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
```
---
### **Graf 6: Trasy z Londýna s najväčšou kapacitou sedadiel**
Vizualizácia ukazuje destinácie, do ktorých je z Londýna dostupná najväčšia kapacita sedadiel, a identifikuje najvýznamnejšie letové trasy.

```sql
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
```
---

**Autori:** Márton Duba, László András Balogh



