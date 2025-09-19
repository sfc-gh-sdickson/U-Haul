/*
 * U-Haul Snowflake Intelligence Demo - Synthetic Data Generation
 * 
 * This script generates deterministic synthetic data for the U-Haul demo using SQL.
 * The data includes realistic patterns and relationships for:
 * - Locations across major US cities
 * - Fleet of vehicles with realistic specifications
 * - Customer profiles with rental history
 * - Rental transactions with seasonal patterns
 * - Vehicle telemetry data showing usage patterns
 * - Maintenance events and equipment rentals
 * 
 * All data uses seeded random functions for consistency across runs.
 * 
 * Prerequisites: Run 00_setup.sql and 01_tables.sql first
 */

-- Ensure we're in the right context
USE WAREHOUSE UHAUL_DEMO_WH;
USE DATABASE UHAUL_DEMO;
USE SCHEMA RAW_DATA;

-- Clear existing data for clean reload
TRUNCATE TABLE RENTAL_EQUIPMENT;
TRUNCATE TABLE VEHICLE_TELEMETRY;
TRUNCATE TABLE MAINTENANCE_EVENTS;
TRUNCATE TABLE RENTALS;
TRUNCATE TABLE EQUIPMENT_INVENTORY;
TRUNCATE TABLE CUSTOMERS;
TRUNCATE TABLE VEHICLES;
TRUNCATE TABLE LOCATIONS;

-- Generate LOCATIONS data (100 locations across major US cities)
INSERT INTO LOCATIONS (
    LOCATION_ID, LOCATION_NAME, ADDRESS, CITY, STATE, ZIP_CODE, 
    LATITUDE, LONGITUDE, LOCATION_TYPE, PHONE, IS_ACTIVE
)
WITH city_data AS (
    SELECT * FROM VALUES
    ('Los Angeles', 'CA', 34.0522, -118.2437, '90210'),
    ('New York', 'NY', 40.7128, -74.0060, '10001'),
    ('Chicago', 'IL', 41.8781, -87.6298, '60601'),
    ('Houston', 'TX', 29.7604, -95.3698, '77001'),
    ('Phoenix', 'AZ', 33.4484, -112.0740, '85001'),
    ('Philadelphia', 'PA', 39.9526, -75.1652, '19101'),
    ('San Antonio', 'TX', 29.4241, -98.4936, '78201'),
    ('San Diego', 'CA', 32.7157, -117.1611, '92101'),
    ('Dallas', 'TX', 32.7767, -96.7970, '75201'),
    ('San Jose', 'CA', 37.3382, -121.8863, '95101'),
    ('Austin', 'TX', 30.2672, -97.7431, '78701'),
    ('Jacksonville', 'FL', 30.3322, -81.6557, '32099'),
    ('Fort Worth', 'TX', 32.7555, -97.3308, '76101'),
    ('Columbus', 'OH', 39.9612, -82.9988, '43085'),
    ('Charlotte', 'NC', 35.2271, -80.8431, '28202'),
    ('San Francisco', 'CA', 37.7749, -122.4194, '94102'),
    ('Indianapolis', 'IN', 39.7684, -86.1581, '46201'),
    ('Seattle', 'WA', 47.6062, -122.3321, '98101'),
    ('Denver', 'CO', 39.7392, -104.9903, '80202'),
    ('Boston', 'MA', 42.3601, -71.0589, '02101')
    AS t(city, state, lat, lng, zip)
),
location_generator AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY city, seq) as rn,
        city, state, lat, lng, zip,
        seq
    FROM city_data,
    TABLE(GENERATOR(ROWCOUNT => 5)) -- 5 locations per city
)
SELECT 
    'LOC' || LPAD(rn, 4, '0') as location_id,
    city || ' U-Haul #' || seq as location_name,
    (1000 + (HASH(rn, 42) % 9000)) || ' ' || 
    CASE (HASH(rn, 123) % 10)
        WHEN 0 THEN 'Main St'
        WHEN 1 THEN 'Broadway'
        WHEN 2 THEN 'First Ave'
        WHEN 3 THEN 'Oak Street'
        WHEN 4 THEN 'Park Ave'
        WHEN 5 THEN 'Center St'
        WHEN 6 THEN 'Market St'
        WHEN 7 THEN 'Washington Blvd'
        WHEN 8 THEN 'Lincoln Way'
        ELSE 'Commerce Dr'
    END as address,
    city,
    state,
    zip,
    lat + (HASH(rn, 456) % 200 - 100) / 10000.0 as latitude,
    lng + (HASH(rn, 789) % 200 - 100) / 10000.0 as longitude,
    CASE (HASH(rn, 321) % 10)
        WHEN 0,1,2,3,4,5 THEN 'Company Store'
        WHEN 6,7,8 THEN 'Dealer'
        ELSE 'U-Box Container'
    END as location_type,
    '(' || (200 + (HASH(rn, 111) % 800)) || ') ' || 
    (200 + (HASH(rn, 222) % 800)) || '-' ||
    LPAD((HASH(rn, 333) % 10000), 4, '0') as phone,
    TRUE as is_active
FROM location_generator;

-- Generate VEHICLES data (2000 vehicles with realistic fleet composition)
INSERT INTO VEHICLES (
    VEHICLE_ID, VIN, VEHICLE_TYPE, VEHICLE_SUBTYPE, MAKE, MODEL, YEAR,
    LICENSE_PLATE, CURRENT_LOCATION_ID, VEHICLE_STATUS, MILEAGE,
    CARGO_CAPACITY_CUBIC_FEET, MAX_LOAD_WEIGHT_LBS, DAILY_RATE, MILEAGE_RATE,
    ACQUISITION_DATE, LAST_MAINTENANCE_DATE, NEXT_MAINTENANCE_DUE_MILEAGE
)
WITH vehicle_generator AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY seq) as rn,
        seq
    FROM TABLE(GENERATOR(ROWCOUNT => 2000))
),
vehicle_specs AS (
    SELECT 
        rn,
        CASE (HASH(rn, 100) % 100)
            WHEN 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19 THEN 'Pickup Truck'
            WHEN 20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35 THEN 'Cargo Van'
            WHEN 36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55 THEN 'Moving Truck'
            ELSE 'Trailer'
        END as vehicle_type,
        CASE 
            WHEN (HASH(rn, 100) % 100) < 20 THEN -- Pickup Truck
                CASE (HASH(rn, 200) % 3)
                    WHEN 0 THEN 'Pickup 8ft'
                    WHEN 1 THEN 'Pickup 6ft'
                    ELSE 'Pickup 5ft'
                END
            WHEN (HASH(rn, 100) % 100) < 36 THEN -- Cargo Van
                CASE (HASH(rn, 200) % 2)
                    WHEN 0 THEN 'Cargo Van'
                    ELSE 'Large Cargo Van'
                END
            WHEN (HASH(rn, 100) % 100) < 56 THEN -- Moving Truck
                CASE (HASH(rn, 200) % 4)
                    WHEN 0 THEN '10ft'
                    WHEN 1 THEN '15ft'
                    WHEN 2 THEN '20ft'
                    ELSE '26ft'
                END
            ELSE -- Trailer
                CASE (HASH(rn, 200) % 4)
                    WHEN 0 THEN '4x8 Cargo Trailer'
                    WHEN 1 THEN '5x8 Cargo Trailer'
                    WHEN 2 THEN '6x12 Cargo Trailer'
                    ELSE 'Auto Transport Trailer'
                END
        END as vehicle_subtype
    FROM vehicle_generator
)
SELECT 
    'VEH' || LPAD(rn, 5, '0') as vehicle_id,
    -- Generate realistic VIN
    CASE (HASH(rn, 301) % 3)
        WHEN 0 THEN '1FTFW1ET'
        WHEN 1 THEN '1GCCS14W'
        ELSE '3C6TRVAG'
    END || 
    CHR(65 + (HASH(rn, 302) % 26)) ||
    LPAD((HASH(rn, 303) % 1000000), 8, '0') as vin,
    vehicle_type,
    vehicle_subtype,
    CASE (HASH(rn, 400) % 6)
        WHEN 0 THEN 'Ford'
        WHEN 1 THEN 'Chevrolet'
        WHEN 2 THEN 'GMC'
        WHEN 3 THEN 'Isuzu'
        WHEN 4 THEN 'Freightliner'
        ELSE 'International'
    END as make,
    CASE vehicle_type
        WHEN 'Pickup Truck' THEN 
            CASE (HASH(rn, 500) % 4)
                WHEN 0 THEN 'F-150'
                WHEN 1 THEN 'Silverado'
                WHEN 2 THEN 'Sierra'
                ELSE 'Ram 1500'
            END
        WHEN 'Cargo Van' THEN
            CASE (HASH(rn, 500) % 3)
                WHEN 0 THEN 'Transit'
                WHEN 1 THEN 'Express'
                ELSE 'Savana'
            END
        WHEN 'Moving Truck' THEN 'Box Truck'
        ELSE 'Utility Trailer'
    END as model,
    2018 + (HASH(rn, 600) % 7) as year, -- 2018-2024
    -- Generate license plate
    CHR(65 + (HASH(rn, 700) % 26)) ||
    CHR(65 + (HASH(rn, 701) % 26)) ||
    CHR(65 + (HASH(rn, 702) % 26)) ||
    LPAD((HASH(rn, 703) % 1000), 3, '0') as license_plate,
    'LOC' || LPAD(1 + (HASH(rn, 800) % 100), 4, '0') as current_location_id,
    CASE (HASH(rn, 900) % 100)
        WHEN 0,1,2,3,4 THEN 'Rented'
        WHEN 5,6 THEN 'Maintenance'
        WHEN 7 THEN 'Out of Service'
        ELSE 'Available'
    END as vehicle_status,
    5000 + (HASH(rn, 1000) % 95000) as mileage, -- 5K to 100K miles
    -- Cargo capacity based on vehicle type
    CASE vehicle_type
        WHEN 'Pickup Truck' THEN 50 + (HASH(rn, 1100) % 30)
        WHEN 'Cargo Van' THEN 200 + (HASH(rn, 1100) % 100)
        WHEN 'Moving Truck' THEN 
            CASE vehicle_subtype
                WHEN '10ft' THEN 400
                WHEN '15ft' THEN 764
                WHEN '20ft' THEN 1016
                WHEN '26ft' THEN 1611
                ELSE 300
            END
        ELSE 100 + (HASH(rn, 1100) % 200)
    END as cargo_capacity_cubic_feet,
    -- Max load weight
    CASE vehicle_type
        WHEN 'Pickup Truck' THEN 1500 + (HASH(rn, 1200) % 500)
        WHEN 'Cargo Van' THEN 3000 + (HASH(rn, 1200) % 1000)
        WHEN 'Moving Truck' THEN 
            CASE vehicle_subtype
                WHEN '10ft' THEN 2850
                WHEN '15ft' THEN 3500
                WHEN '20ft' THEN 5790
                WHEN '26ft' THEN 7400
                ELSE 4000
            END
        ELSE 2000 + (HASH(rn, 1200) % 2000)
    END as max_load_weight_lbs,
    -- Daily rates
    CASE vehicle_type
        WHEN 'Pickup Truck' THEN 19.95 + (HASH(rn, 1300) % 10)
        WHEN 'Cargo Van' THEN 29.95 + (HASH(rn, 1300) % 15)
        WHEN 'Moving Truck' THEN 
            CASE vehicle_subtype
                WHEN '10ft' THEN 29.95
                WHEN '15ft' THEN 39.95
                WHEN '20ft' THEN 49.95
                WHEN '26ft' THEN 59.95
                ELSE 39.95
            END
        ELSE 14.95 + (HASH(rn, 1300) % 10)
    END as daily_rate,
    0.99 + (HASH(rn, 1400) % 50) / 100.0 as mileage_rate, -- $0.99-$1.49 per mile
    DATEADD(day, -1 * (HASH(rn, 1500) % 2000), CURRENT_DATE()) as acquisition_date,
    DATEADD(day, -1 * (HASH(rn, 1600) % 90), CURRENT_DATE()) as last_maintenance_date,
    (5000 + (HASH(rn, 1000) % 95000)) + 3000 + (HASH(rn, 1700) % 2000) as next_maintenance_due_mileage
FROM vehicle_specs;

-- Generate CUSTOMERS data (5000 customers)
INSERT INTO CUSTOMERS (
    CUSTOMER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE, DATE_OF_BIRTH,
    DRIVERS_LICENSE_NUMBER, DRIVERS_LICENSE_STATE, ADDRESS, CITY, STATE, ZIP_CODE,
    CUSTOMER_SINCE, CUSTOMER_TIER, TOTAL_RENTALS, TOTAL_SPENT, CREDIT_SCORE_RANGE
)
WITH customer_generator AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY seq) as rn
    FROM TABLE(GENERATOR(ROWCOUNT => 5000))
),
names AS (
    SELECT * FROM VALUES
    ('James', 'Smith'), ('Mary', 'Johnson'), ('John', 'Williams'), ('Patricia', 'Brown'),
    ('Robert', 'Jones'), ('Jennifer', 'Garcia'), ('Michael', 'Miller'), ('Linda', 'Davis'),
    ('David', 'Rodriguez'), ('Barbara', 'Martinez'), ('Richard', 'Hernandez'), ('Susan', 'Lopez'),
    ('Joseph', 'Gonzalez'), ('Jessica', 'Wilson'), ('Thomas', 'Anderson'), ('Sarah', 'Thomas'),
    ('Christopher', 'Taylor'), ('Karen', 'Moore'), ('Daniel', 'Jackson'), ('Nancy', 'Martin'),
    ('Matthew', 'Lee'), ('Betty', 'Perez'), ('Anthony', 'Thompson'), ('Helen', 'White'),
    ('Mark', 'Harris'), ('Sandra', 'Sanchez'), ('Donald', 'Clark'), ('Donna', 'Ramirez'),
    ('Steven', 'Lewis'), ('Carol', 'Robinson'), ('Paul', 'Walker'), ('Ruth', 'Young'),
    ('Andrew', 'Allen'), ('Sharon', 'King'), ('Joshua', 'Wright'), ('Michelle', 'Scott'),
    ('Kenneth', 'Torres'), ('Laura', 'Nguyen'), ('Kevin', 'Hill'), ('Emily', 'Flores')
    AS t(first_name, last_name)
),
states AS (
    SELECT * FROM VALUES
    ('CA'), ('TX'), ('FL'), ('NY'), ('PA'), ('IL'), ('OH'), ('GA'), ('NC'), ('MI'),
    ('NJ'), ('VA'), ('WA'), ('AZ'), ('MA'), ('TN'), ('IN'), ('MO'), ('MD'), ('WI')
    AS t(state)
)
SELECT 
    'CUST' || LPAD(rn, 6, '0') as customer_id,
    (SELECT first_name FROM names LIMIT 1 OFFSET (HASH(rn, 2000) % 40)) as first_name,
    (SELECT last_name FROM names LIMIT 1 OFFSET (HASH(rn, 2001) % 40)) as last_name,
    LOWER((SELECT first_name FROM names LIMIT 1 OFFSET (HASH(rn, 2000) % 40))) || '.' ||
    LOWER((SELECT last_name FROM names LIMIT 1 OFFSET (HASH(rn, 2001) % 40))) || 
    (HASH(rn, 2002) % 1000) || '@' ||
    CASE (HASH(rn, 2003) % 5)
        WHEN 0 THEN 'gmail.com'
        WHEN 1 THEN 'yahoo.com'
        WHEN 2 THEN 'hotmail.com'
        WHEN 3 THEN 'outlook.com'
        ELSE 'aol.com'
    END as email,
    '(' || (200 + (HASH(rn, 2100) % 800)) || ') ' || 
    (200 + (HASH(rn, 2101) % 800)) || '-' ||
    LPAD((HASH(rn, 2102) % 10000), 4, '0') as phone,
    DATEADD(year, -18 - (HASH(rn, 2200) % 50), CURRENT_DATE()) as date_of_birth,
    CHR(65 + (HASH(rn, 2300) % 26)) ||
    LPAD((HASH(rn, 2301) % 100000000), 8, '0') as drivers_license_number,
    (SELECT state FROM states LIMIT 1 OFFSET (HASH(rn, 2400) % 20)) as drivers_license_state,
    (1000 + (HASH(rn, 2500) % 9000)) || ' ' || 
    CASE (HASH(rn, 2501) % 10)
        WHEN 0 THEN 'Main St'
        WHEN 1 THEN 'Oak Ave'
        WHEN 2 THEN 'Pine St'
        WHEN 3 THEN 'Maple Dr'
        WHEN 4 THEN 'Cedar Ln'
        WHEN 5 THEN 'Elm St'
        WHEN 6 THEN 'Park Ave'
        WHEN 7 THEN 'First St'
        WHEN 8 THEN 'Second Ave'
        ELSE 'Third St'
    END as address,
    CASE (HASH(rn, 2600) % 20)
        WHEN 0 THEN 'Los Angeles' WHEN 1 THEN 'New York' WHEN 2 THEN 'Chicago'
        WHEN 3 THEN 'Houston' WHEN 4 THEN 'Phoenix' WHEN 5 THEN 'Philadelphia'
        WHEN 6 THEN 'San Antonio' WHEN 7 THEN 'San Diego' WHEN 8 THEN 'Dallas'
        WHEN 9 THEN 'San Jose' WHEN 10 THEN 'Austin' WHEN 11 THEN 'Jacksonville'
        WHEN 12 THEN 'Fort Worth' WHEN 13 THEN 'Columbus' WHEN 14 THEN 'Charlotte'
        WHEN 15 THEN 'San Francisco' WHEN 16 THEN 'Indianapolis' WHEN 17 THEN 'Seattle'
        WHEN 18 THEN 'Denver' ELSE 'Boston'
    END as city,
    (SELECT state FROM states LIMIT 1 OFFSET (HASH(rn, 2700) % 20)) as state,
    LPAD((HASH(rn, 2800) % 100000), 5, '0') as zip_code,
    DATEADD(day, -1 * (HASH(rn, 2900) % 3650), CURRENT_DATE()) as customer_since, -- Up to 10 years ago
    CASE (HASH(rn, 3000) % 100)
        WHEN 0,1,2,3,4 THEN 'U-Haul Pro'
        WHEN 5,6,7 THEN 'Business'
        ELSE 'Standard'
    END as customer_tier,
    HASH(rn, 3100) % 25 as total_rentals, -- 0-24 previous rentals
    (HASH(rn, 3200) % 5000) + 100.00 as total_spent, -- $100-$5100 lifetime spend
    CASE (HASH(rn, 3300) % 5)
        WHEN 0 THEN '300-579'
        WHEN 1 THEN '580-669'
        WHEN 2 THEN '670-739'
        WHEN 3 THEN '740-799'
        ELSE '800-850'
    END as credit_score_range
FROM customer_generator;

-- Generate EQUIPMENT_INVENTORY data
INSERT INTO EQUIPMENT_INVENTORY (
    EQUIPMENT_ID, EQUIPMENT_TYPE, EQUIPMENT_NAME, LOCATION_ID, 
    QUANTITY_AVAILABLE, DAILY_RATE, REPLACEMENT_COST
)
WITH equipment_types AS (
    SELECT * FROM VALUES
    ('Dolly', 'Appliance Dolly', 7.95, 89.95),
    ('Dolly', 'Furniture Dolly', 7.95, 79.95),
    ('Dolly', 'Utility Dolly', 6.95, 69.95),
    ('Furniture Pad', 'Moving Blanket', 7.95, 24.95),
    ('Furniture Pad', 'Furniture Pad', 7.95, 19.95),
    ('Tie Down', 'Ratchet Tie Down', 2.95, 12.95),
    ('Tie Down', 'Bungee Cord Set', 2.95, 8.95),
    ('Box', 'Small Box', 2.95, 2.95),
    ('Box', 'Medium Box', 3.95, 3.95),
    ('Box', 'Large Box', 4.95, 4.95),
    ('Tape', 'Packing Tape', 3.95, 4.95),
    ('Tape', 'Bubble Wrap', 19.95, 24.95)
    AS t(equipment_type, equipment_name, daily_rate, replacement_cost)
),
location_equipment AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY l.location_id, e.equipment_name) as rn,
        l.location_id,
        e.equipment_type,
        e.equipment_name,
        e.daily_rate,
        e.replacement_cost
    FROM (SELECT DISTINCT location_id FROM locations) l
    CROSS JOIN equipment_types e
)
SELECT 
    'EQP' || LPAD(rn, 6, '0') as equipment_id,
    equipment_type,
    equipment_name,
    location_id,
    5 + (HASH(rn, 4000) % 20) as quantity_available, -- 5-24 items per location
    daily_rate,
    replacement_cost
FROM location_equipment;

-- Generate RENTALS data (15000 rentals over the past 2 years with seasonal patterns)
INSERT INTO RENTALS (
    RENTAL_ID, CUSTOMER_ID, VEHICLE_ID, PICKUP_LOCATION_ID, DROPOFF_LOCATION_ID,
    RENTAL_START_DATE, RENTAL_END_DATE, PLANNED_RETURN_DATE, ACTUAL_RETURN_DATE,
    START_MILEAGE, END_MILEAGE, MILES_DRIVEN, RENTAL_DURATION_HOURS,
    BASE_RATE, MILEAGE_CHARGES, EQUIPMENT_CHARGES, FUEL_CHARGES, LATE_FEES, DAMAGE_FEES,
    TOTAL_AMOUNT, PAYMENT_METHOD, RENTAL_STATUS, RESERVATION_CHANNEL, CUSTOMER_RATING
)
WITH rental_generator AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY seq) as rn
    FROM TABLE(GENERATOR(ROWCOUNT => 15000))
),
rental_data AS (
    SELECT 
        rn,
        'RENT' || LPAD(rn, 6, '0') as rental_id,
        'CUST' || LPAD(1 + (HASH(rn, 5000) % 5000), 6, '0') as customer_id,
        'VEH' || LPAD(1 + (HASH(rn, 5001) % 2000), 5, '0') as vehicle_id,
        'LOC' || LPAD(1 + (HASH(rn, 5002) % 100), 4, '0') as pickup_location_id,
        'LOC' || LPAD(1 + (HASH(rn, 5003) % 100), 4, '0') as dropoff_location_id,
        -- Generate rental dates with seasonal patterns (more in summer)
        DATEADD(day, 
            -1 * (HASH(rn, 5100) % 730) + 
            CASE 
                WHEN (HASH(rn, 5101) % 12) IN (5,6,7,8) THEN -30 -- Summer bias
                WHEN (HASH(rn, 5101) % 12) IN (11,0,1) THEN 30   -- Winter less likely
                ELSE 0
            END, 
            CURRENT_DATE()
        ) as rental_start_date,
        -- Rental duration (1-7 days mostly, some longer)
        CASE (HASH(rn, 5200) % 100)
            WHEN 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19 THEN 1 -- 20% 1 day
            WHEN 20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39 THEN 2 -- 20% 2 days
            WHEN 40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55 THEN 3 -- 16% 3 days
            WHEN 56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71 THEN 4 -- 16% 4 days
            WHEN 72,73,74,75,76,77,78,79,80,81,82,83 THEN 5 -- 12% 5 days
            WHEN 84,85,86,87,88,89,90,91 THEN 6 -- 8% 6 days
            WHEN 92,93,94,95 THEN 7 -- 4% 7 days
            ELSE 8 + (HASH(rn, 5201) % 7) -- 4% 8-14 days
        END as rental_duration_days,
        50000 + (HASH(rn, 5300) % 50000) as start_mileage,
        50 + (HASH(rn, 5400) % 500) as miles_driven -- 50-550 miles typical
    FROM rental_generator
)
SELECT 
    rental_id,
    customer_id,
    vehicle_id,
    pickup_location_id,
    CASE (HASH(rn, 5500) % 10)
        WHEN 0,1 THEN pickup_location_id -- 20% same location return
        ELSE dropoff_location_id -- 80% different location
    END as dropoff_location_id,
    rental_start_date,
    DATEADD(hour, rental_duration_days * 24, rental_start_date) as rental_end_date,
    DATEADD(hour, rental_duration_days * 24, rental_start_date) as planned_return_date,
    DATEADD(hour, 
        rental_duration_days * 24 + 
        CASE (HASH(rn, 5600) % 20)
            WHEN 0,1,2 THEN HASH(rn, 5601) % 48 -- 15% late return (up to 2 days)
            ELSE 0 -- On time
        END, 
        rental_start_date
    ) as actual_return_date,
    start_mileage,
    start_mileage + miles_driven as end_mileage,
    miles_driven,
    rental_duration_days * 24 as rental_duration_hours,
    29.95 + (HASH(rn, 5700) % 30) as base_rate, -- $29.95-$59.95 base rate
    miles_driven * (0.99 + (HASH(rn, 5800) % 50) / 100.0) as mileage_charges,
    CASE (HASH(rn, 5900) % 3)
        WHEN 0 THEN 0.00 -- No equipment
        WHEN 1 THEN 15.95 + (HASH(rn, 5901) % 20) -- Some equipment
        ELSE 35.95 + (HASH(rn, 5902) % 40) -- More equipment
    END as equipment_charges,
    CASE (HASH(rn, 6000) % 10)
        WHEN 0,1,2 THEN 25.00 + (HASH(rn, 6001) % 50) -- 30% fuel charges
        ELSE 0.00 -- Returned with same fuel level
    END as fuel_charges,
    CASE (HASH(rn, 6100) % 20)
        WHEN 0 THEN 40.00 + (HASH(rn, 6101) % 100) -- 5% late fees
        ELSE 0.00
    END as late_fees,
    CASE (HASH(rn, 6200) % 50)
        WHEN 0 THEN 150.00 + (HASH(rn, 6201) % 500) -- 2% damage fees
        ELSE 0.00
    END as damage_fees,
    0 as total_amount, -- Will be calculated
    CASE (HASH(rn, 6300) % 10)
        WHEN 0,1,2,3,4,5,6 THEN 'Credit Card' -- 70%
        WHEN 7,8 THEN 'Debit Card' -- 20%
        WHEN 9 THEN 'Corporate Account' -- 10%
        ELSE 'Cash'
    END as payment_method,
    CASE 
        WHEN rental_start_date > CURRENT_DATE() THEN 'Reserved'
        WHEN DATEADD(hour, rental_duration_days * 24, rental_start_date) > CURRENT_TIMESTAMP() THEN 'Active'
        WHEN (HASH(rn, 6400) % 100) < 2 THEN 'Cancelled' -- 2% cancelled
        ELSE 'Completed'
    END as rental_status,
    CASE (HASH(rn, 6500) % 10)
        WHEN 0,1,2,3,4 THEN 'Website' -- 50%
        WHEN 5,6,7 THEN 'Mobile App' -- 30%
        WHEN 8 THEN 'Phone' -- 10%
        ELSE 'In-Store' -- 10%
    END as reservation_channel,
    CASE (HASH(rn, 6600) % 20)
        WHEN 0 THEN 1 -- 5% 1 star
        WHEN 1,2 THEN 2 -- 10% 2 stars
        WHEN 3,4,5 THEN 3 -- 15% 3 stars
        WHEN 6,7,8,9,10,11,12 THEN 4 -- 35% 4 stars
        ELSE 5 -- 35% 5 stars
    END as customer_rating
FROM rental_data;

-- Update total_amount in rentals
UPDATE RENTALS 
SET TOTAL_AMOUNT = BASE_RATE + MILEAGE_CHARGES + EQUIPMENT_CHARGES + FUEL_CHARGES + LATE_FEES + DAMAGE_FEES;

-- Generate MAINTENANCE_EVENTS data
INSERT INTO MAINTENANCE_EVENTS (
    MAINTENANCE_ID, VEHICLE_ID, MAINTENANCE_TYPE, MAINTENANCE_CATEGORY,
    DESCRIPTION, SERVICE_DATE, MILEAGE_AT_SERVICE, LABOR_HOURS,
    PARTS_COST, LABOR_COST, TOTAL_COST, SERVICE_PROVIDER, VEHICLE_OUT_OF_SERVICE_HOURS,
    NEXT_SERVICE_DUE_MILEAGE, NEXT_SERVICE_DUE_DATE, WARRANTY_CLAIM
)
WITH maintenance_generator AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY v.vehicle_id, seq) as rn,
        v.vehicle_id,
        v.mileage,
        seq
    FROM vehicles v,
    TABLE(GENERATOR(ROWCOUNT => 3)) -- 3 maintenance events per vehicle on average
    WHERE (HASH(v.vehicle_id || seq, 7000) % 100) < 60 -- 60% of vehicles have this many events
),
maintenance_types AS (
    SELECT * FROM VALUES
    ('Preventive', 'Engine', 'Oil Change', 1.0, 25.00, 75.00),
    ('Preventive', 'Tires', 'Tire Rotation', 0.5, 0.00, 40.00),
    ('Preventive', 'Brakes', 'Brake Inspection', 1.0, 0.00, 80.00),
    ('Repair', 'Engine', 'Engine Repair', 4.0, 350.00, 320.00),
    ('Repair', 'Transmission', 'Transmission Service', 3.0, 200.00, 240.00),
    ('Repair', 'Brakes', 'Brake Pad Replacement', 2.0, 120.00, 160.00),
    ('Repair', 'Tires', 'Tire Replacement', 1.0, 400.00, 80.00),
    ('Repair', 'Body', 'Body Repair', 6.0, 800.00, 480.00),
    ('Repair', 'Electrical', 'Electrical Repair', 2.5, 150.00, 200.00),
    ('Inspection', 'Engine', 'Annual Inspection', 0.5, 0.00, 40.00)
    AS t(maintenance_type, maintenance_category, description, labor_hours, parts_cost, labor_cost)
)
SELECT 
    'MAINT' || LPAD(rn, 6, '0') as maintenance_id,
    vehicle_id,
    mt.maintenance_type,
    mt.maintenance_category,
    mt.description,
    DATEADD(day, -1 * (HASH(rn, 8000) % 365), CURRENT_DATE()) as service_date,
    mileage - (HASH(rn, 8100) % 5000) as mileage_at_service,
    mt.labor_hours + (HASH(rn, 8200) % 100) / 100.0 as labor_hours,
    mt.parts_cost * (0.8 + (HASH(rn, 8300) % 40) / 100.0) as parts_cost,
    mt.labor_cost * (0.9 + (HASH(rn, 8400) % 20) / 100.0) as labor_cost,
    0 as total_cost, -- Will be calculated
    CASE (HASH(rn, 8500) % 10)
        WHEN 0,1,2,3,4,5,6 THEN 'U-Haul Service' -- 70%
        ELSE 'Third Party Shop' -- 30%
    END as service_provider,
    CASE mt.maintenance_type
        WHEN 'Preventive' THEN HASH(rn, 8600) % 4 -- 0-3 hours
        WHEN 'Inspection' THEN HASH(rn, 8600) % 2 -- 0-1 hours
        ELSE 4 + (HASH(rn, 8600) % 20) -- 4-23 hours for repairs
    END as vehicle_out_of_service_hours,
    mileage + 3000 + (HASH(rn, 8700) % 2000) as next_service_due_mileage,
    DATEADD(day, 90 + (HASH(rn, 8800) % 90), CURRENT_DATE()) as next_service_due_date,
    CASE (HASH(rn, 8900) % 20)
        WHEN 0 THEN TRUE -- 5% warranty claims
        ELSE FALSE
    END as warranty_claim,
    (SELECT maintenance_type FROM maintenance_types LIMIT 1 OFFSET (HASH(rn, 9000) % 10)) as mt_type,
    (SELECT maintenance_category FROM maintenance_types LIMIT 1 OFFSET (HASH(rn, 9000) % 10)) as mt_category,
    (SELECT description FROM maintenance_types LIMIT 1 OFFSET (HASH(rn, 9000) % 10)) as mt_description,
    (SELECT labor_hours FROM maintenance_types LIMIT 1 OFFSET (HASH(rn, 9000) % 10)) as mt_labor_hours,
    (SELECT parts_cost FROM maintenance_types LIMIT 1 OFFSET (HASH(rn, 9000) % 10)) as mt_parts_cost,
    (SELECT labor_cost FROM maintenance_types LIMIT 1 OFFSET (HASH(rn, 9000) % 10)) as mt_labor_cost
FROM maintenance_generator mg
CROSS JOIN maintenance_types mt
WHERE ROW_NUMBER() OVER (PARTITION BY mg.rn ORDER BY RANDOM()) = 1;

-- Update total_cost in maintenance_events
UPDATE MAINTENANCE_EVENTS 
SET TOTAL_COST = PARTS_COST + LABOR_COST;

-- Generate sample VEHICLE_TELEMETRY data (last 30 days for active rentals)
INSERT INTO VEHICLE_TELEMETRY (
    TELEMETRY_ID, VEHICLE_ID, RENTAL_ID, TIMESTAMP, LATITUDE, LONGITUDE,
    SPEED_MPH, ENGINE_RPM, FUEL_LEVEL_PERCENT, ENGINE_TEMPERATURE_F,
    ODOMETER_READING, HARSH_BRAKING_EVENT, HARSH_ACCELERATION_EVENT,
    SPEEDING_EVENT, IDLE_TIME_MINUTES, FUEL_CONSUMPTION_RATE
)
WITH active_rentals AS (
    SELECT 
        rental_id, 
        vehicle_id, 
        rental_start_date,
        actual_return_date,
        start_mileage
    FROM rentals 
    WHERE rental_status = 'Active' 
       OR (rental_status = 'Completed' AND actual_return_date >= DATEADD(day, -30, CURRENT_TIMESTAMP()))
    LIMIT 100 -- Limit for demo purposes
),
telemetry_generator AS (
    SELECT 
        ar.*,
        seq,
        ROW_NUMBER() OVER (ORDER BY ar.rental_id, seq) as rn
    FROM active_rentals ar,
    TABLE(GENERATOR(ROWCOUNT => 50)) -- 50 telemetry points per rental
)
SELECT 
    'TEL' || LPAD(rn, 8, '0') as telemetry_id,
    vehicle_id,
    rental_id,
    DATEADD(minute, 
        seq * 30 + (HASH(rn, 10000) % 60), -- Every 30 minutes with some variance
        rental_start_date
    ) as timestamp,
    34.0522 + (HASH(rn, 10100) % 1000 - 500) / 10000.0 as latitude, -- Around LA area
    -118.2437 + (HASH(rn, 10101) % 1000 - 500) / 10000.0 as longitude,
    CASE (HASH(rn, 10200) % 100)
        WHEN 0,1,2,3,4,5,6,7,8,9 THEN 0 -- 10% stopped
        WHEN 10,11,12,13,14,15,16,17,18,19,20,21,22,23,24 THEN 15 + (HASH(rn, 10201) % 20) -- 15% city driving
        WHEN 25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49 THEN 35 + (HASH(rn, 10202) % 30) -- 25% highway
        ELSE 25 + (HASH(rn, 10203) % 25) -- 50% mixed
    END as speed_mph,
    1000 + (HASH(rn, 10300) % 2500) as engine_rpm, -- 1000-3500 RPM
    20 + (HASH(rn, 10400) % 80) as fuel_level_percent, -- 20-100%
    180 + (HASH(rn, 10500) % 40) as engine_temperature_f, -- 180-220°F
    start_mileage + (seq * 2) + (HASH(rn, 10600) % 5) as odometer_reading,
    CASE (HASH(rn, 10700) % 200) WHEN 0 THEN TRUE ELSE FALSE END as harsh_braking_event, -- 0.5%
    CASE (HASH(rn, 10800) % 300) WHEN 0 THEN TRUE ELSE FALSE END as harsh_acceleration_event, -- 0.33%
    CASE (HASH(rn, 10900) % 100) WHEN 0 THEN TRUE ELSE FALSE END as speeding_event, -- 1%
    CASE 
        WHEN (HASH(rn, 10200) % 100) < 10 THEN 5 + (HASH(rn, 11000) % 25) -- If stopped, some idle time
        ELSE 0
    END as idle_time_minutes,
    15.0 + (HASH(rn, 11100) % 100) / 10.0 as fuel_consumption_rate -- 15-25 MPG
FROM telemetry_generator
WHERE DATEADD(minute, seq * 30, rental_start_date) <= actual_return_date;

-- Display data loading completion
SELECT 'U-Haul Demo Synthetic Data Loaded Successfully!' as STATUS,
       (SELECT COUNT(*) FROM locations) as LOCATIONS,
       (SELECT COUNT(*) FROM vehicles) as VEHICLES,
       (SELECT COUNT(*) FROM customers) as CUSTOMERS,
       (SELECT COUNT(*) FROM rentals) as RENTALS,
       (SELECT COUNT(*) FROM maintenance_events) as MAINTENANCE_EVENTS,
       (SELECT COUNT(*) FROM vehicle_telemetry) as TELEMETRY_RECORDS,
       (SELECT COUNT(*) FROM equipment_inventory) as EQUIPMENT_ITEMS;
