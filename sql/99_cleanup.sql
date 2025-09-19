/*
 * U-Haul Snowflake Intelligence Demo - Cleanup Script
 * 
 * This script removes all objects created by the U-Haul demo.
 * Use this to clean up your Snowflake environment after the demo.
 * 
 * WARNING: This will permanently delete all demo data and objects!
 * 
 * Objects removed:
 * - All tables in RAW_DATA schema
 * - All views in ANALYTICS schema  
 * - All views in SEMANTICS schema
 * - UHAUL_DEMO database (and all contained objects)
 * - UHAUL_DEMO_WH warehouse
 * - UHAUL_DEMO_ROLE role (optional)
 */

-- Confirm current context
SELECT 'Starting U-Haul Demo Cleanup...' as STATUS,
       CURRENT_WAREHOUSE() as CURRENT_WAREHOUSE,
       CURRENT_DATABASE() as CURRENT_DATABASE,
       CURRENT_SCHEMA() as CURRENT_SCHEMA;

-- Drop the semantic view first (if it exists in Snowsight)
-- Note: Semantic Views created in UI may need to be deleted manually in Snowsight

-- Drop all views in SEMANTICS schema
USE DATABASE UHAUL_DEMO;
USE SCHEMA SEMANTICS;

DROP VIEW IF EXISTS UHAUL_SEMANTIC;

-- Drop all views in ANALYTICS schema  
USE SCHEMA ANALYTICS;

DROP VIEW IF EXISTS RENTAL_ANALYTICS;
DROP VIEW IF EXISTS VEHICLE_PERFORMANCE;
DROP VIEW IF EXISTS CUSTOMER_INSIGHTS;
DROP VIEW IF EXISTS FLEET_HEALTH;
DROP VIEW IF EXISTS REVENUE_ANALYSIS;

-- Drop all tables in RAW_DATA schema
USE SCHEMA RAW_DATA;

DROP TABLE IF EXISTS RENTAL_EQUIPMENT;
DROP TABLE IF EXISTS VEHICLE_TELEMETRY;
DROP TABLE IF EXISTS MAINTENANCE_EVENTS;
DROP TABLE IF EXISTS RENTALS;
DROP TABLE IF EXISTS EQUIPMENT_INVENTORY;
DROP TABLE IF EXISTS CUSTOMERS;
DROP TABLE IF EXISTS VEHICLES;
DROP TABLE IF EXISTS LOCATIONS;

-- Drop schemas
DROP SCHEMA IF EXISTS SEMANTICS;
DROP SCHEMA IF EXISTS ANALYTICS;
DROP SCHEMA IF EXISTS RAW_DATA;

-- Drop database (this will remove all contained objects)
DROP DATABASE IF EXISTS UHAUL_DEMO;

-- Drop warehouse
DROP WAREHOUSE IF EXISTS UHAUL_DEMO_WH;

-- Optionally drop the demo role (uncomment if you want to remove it)
-- DROP ROLE IF EXISTS UHAUL_DEMO_ROLE;

-- Confirmation message
SELECT 'U-Haul Demo Cleanup Complete!' as STATUS,
       'All demo objects have been removed.' as MESSAGE,
       'If you created a Semantic View in Snowsight UI, please delete it manually.' as NOTE;

/*
 * Manual cleanup steps (if needed):
 * 
 * 1. Semantic Views: If you created a Semantic View in Snowsight UI, 
 *    navigate to Data > Semantic Views and delete it manually.
 * 
 * 2. Intelligence Agent: If you configured an Intelligence Agent,
 *    navigate to AI & ML > Agents and delete or reconfigure it.
 * 
 * 3. Role Grants: If you granted the UHAUL_DEMO_ROLE to users,
 *    those grants may need to be revoked manually.
 */
