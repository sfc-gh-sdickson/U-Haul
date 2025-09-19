/*
 * U-Haul Snowflake Intelligence Demo - Setup Script
 * 
 * This script creates the foundational infrastructure for the U-Haul demo:
 * - Warehouse for compute
 * - Database and schemas for data organization
 * - Roles and grants for access control
 * 
 * Run this first before any other scripts.
 */

-- Create a dedicated warehouse for the demo
CREATE WAREHOUSE IF NOT EXISTS UHAUL_DEMO_WH
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for U-Haul Intelligence Demo';

-- Use the warehouse
USE WAREHOUSE UHAUL_DEMO_WH;

-- Create database for the demo
CREATE DATABASE IF NOT EXISTS UHAUL_DEMO
    COMMENT = 'U-Haul Snowflake Intelligence Demo Database';

-- Use the database
USE DATABASE UHAUL_DEMO;

-- Create schemas for different data domains
CREATE SCHEMA IF NOT EXISTS RAW_DATA
    COMMENT = 'Raw transactional data for U-Haul operations';

CREATE SCHEMA IF NOT EXISTS ANALYTICS
    COMMENT = 'Processed views and analytics objects';

CREATE SCHEMA IF NOT EXISTS SEMANTICS
    COMMENT = 'Semantic layer for Intelligence Agent';

-- Create a demo role (optional - adjust based on your role model)
CREATE ROLE IF NOT EXISTS UHAUL_DEMO_ROLE
    COMMENT = 'Role for U-Haul demo users';

-- Grant permissions to the demo role
GRANT USAGE ON WAREHOUSE UHAUL_DEMO_WH TO ROLE UHAUL_DEMO_ROLE;
GRANT USAGE ON DATABASE UHAUL_DEMO TO ROLE UHAUL_DEMO_ROLE;
GRANT USAGE ON SCHEMA UHAUL_DEMO.RAW_DATA TO ROLE UHAUL_DEMO_ROLE;
GRANT USAGE ON SCHEMA UHAUL_DEMO.ANALYTICS TO ROLE UHAUL_DEMO_ROLE;
GRANT USAGE ON SCHEMA UHAUL_DEMO.SEMANTICS TO ROLE UHAUL_DEMO_ROLE;

-- Grant create privileges for demo setup
GRANT CREATE TABLE ON SCHEMA UHAUL_DEMO.RAW_DATA TO ROLE UHAUL_DEMO_ROLE;
GRANT CREATE VIEW ON SCHEMA UHAUL_DEMO.ANALYTICS TO ROLE UHAUL_DEMO_ROLE;
GRANT CREATE VIEW ON SCHEMA UHAUL_DEMO.SEMANTICS TO ROLE UHAUL_DEMO_ROLE;

-- Grant select privileges (will be inherited by objects)
GRANT SELECT ON ALL TABLES IN SCHEMA UHAUL_DEMO.RAW_DATA TO ROLE UHAUL_DEMO_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA UHAUL_DEMO.ANALYTICS TO ROLE UHAUL_DEMO_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA UHAUL_DEMO.SEMANTICS TO ROLE UHAUL_DEMO_ROLE;

-- Grant future privileges
GRANT SELECT ON FUTURE TABLES IN SCHEMA UHAUL_DEMO.RAW_DATA TO ROLE UHAUL_DEMO_ROLE;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA UHAUL_DEMO.ANALYTICS TO ROLE UHAUL_DEMO_ROLE;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA UHAUL_DEMO.SEMANTICS TO ROLE UHAUL_DEMO_ROLE;

-- Set default context
USE SCHEMA UHAUL_DEMO.RAW_DATA;

-- Display setup completion
SELECT 'U-Haul Demo Setup Complete!' as STATUS,
       CURRENT_WAREHOUSE() as WAREHOUSE,
       CURRENT_DATABASE() as DATABASE,
       CURRENT_SCHEMA() as SCHEMA;
