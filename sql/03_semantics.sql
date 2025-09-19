/*
 * U-Haul Snowflake Intelligence Demo - Semantic Layer
 * 
 * This script creates semantic views and helper analytics for the Intelligence Agent.
 * These views provide business-friendly abstractions over the raw data and enable
 * natural language queries about U-Haul operations.
 * 
 * Views created:
 * - RENTAL_ANALYTICS: Comprehensive rental metrics and KPIs
 * - VEHICLE_PERFORMANCE: Vehicle utilization and performance metrics
 * - CUSTOMER_INSIGHTS: Customer behavior and segmentation
 * - FLEET_HEALTH: Vehicle maintenance and operational status
 * - REVENUE_ANALYSIS: Financial performance and trends
 * - UHAUL_SEMANTIC: Main semantic view for Intelligence Agent
 * 
 * Prerequisites: Run 00_setup.sql, 01_tables.sql, and 02_load_synthetic.sql first
 */

-- Ensure we're in the right context
USE WAREHOUSE UHAUL_DEMO_WH;
USE DATABASE UHAUL_DEMO;
USE SCHEMA ANALYTICS;

-- RENTAL_ANALYTICS: Comprehensive rental metrics
CREATE OR REPLACE VIEW RENTAL_ANALYTICS AS
SELECT 
    r.rental_id,
    r.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    c.customer_tier,
    c.customer_since,
    r.vehicle_id,
    v.vehicle_type,
    v.vehicle_subtype,
    v.make || ' ' || v.model as vehicle_make_model,
    v.year as vehicle_year,
    r.pickup_location_id,
    pl.city as pickup_city,
    pl.state as pickup_state,
    pl.location_type as pickup_location_type,
    r.dropoff_location_id,
    dl.city as dropoff_city,
    dl.state as dropoff_state,
    CASE 
        WHEN r.pickup_location_id = r.dropoff_location_id THEN 'Round Trip'
        WHEN pl.city = dl.city THEN 'Local One-Way'
        WHEN pl.state = dl.state THEN 'In-State One-Way'
        ELSE 'Interstate One-Way'
    END as trip_type,
    r.rental_start_date,
    r.rental_end_date,
    r.actual_return_date,
    DATEDIFF(hour, r.rental_start_date, r.actual_return_date) as actual_rental_hours,
    DATEDIFF(hour, r.rental_end_date, r.actual_return_date) as late_hours,
    CASE WHEN r.actual_return_date > r.rental_end_date THEN TRUE ELSE FALSE END as is_late_return,
    r.miles_driven,
    r.base_rate,
    r.mileage_charges,
    r.equipment_charges,
    r.fuel_charges,
    r.late_fees,
    r.damage_fees,
    r.total_amount,
    r.payment_method,
    r.rental_status,
    r.reservation_channel,
    r.customer_rating,
    -- Calculated metrics
    ROUND(r.total_amount / NULLIF(r.miles_driven, 0), 2) as revenue_per_mile,
    ROUND(r.total_amount / NULLIF(DATEDIFF(hour, r.rental_start_date, r.actual_return_date), 0), 2) as revenue_per_hour,
    CASE 
        WHEN r.miles_driven = 0 THEN 'No Miles'
        WHEN r.miles_driven <= 50 THEN 'Short Distance (≤50 mi)'
        WHEN r.miles_driven <= 200 THEN 'Medium Distance (51-200 mi)'
        WHEN r.miles_driven <= 500 THEN 'Long Distance (201-500 mi)'
        ELSE 'Very Long Distance (>500 mi)'
    END as distance_category,
    CASE 
        WHEN DATEDIFF(hour, r.rental_start_date, r.actual_return_date) <= 24 THEN 'Same Day'
        WHEN DATEDIFF(hour, r.rental_start_date, r.actual_return_date) <= 72 THEN '2-3 Days'
        WHEN DATEDIFF(hour, r.rental_start_date, r.actual_return_date) <= 168 THEN '4-7 Days'
        ELSE 'Extended (>1 week)'
    END as duration_category,
    EXTRACT(YEAR FROM r.rental_start_date) as rental_year,
    EXTRACT(MONTH FROM r.rental_start_date) as rental_month,
    MONTHNAME(r.rental_start_date) as rental_month_name,
    EXTRACT(QUARTER FROM r.rental_start_date) as rental_quarter,
    DAYNAME(r.rental_start_date) as rental_day_of_week,
    CASE 
        WHEN DAYOFWEEK(r.rental_start_date) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END as rental_day_type,
    -- Seasonal patterns
    CASE 
        WHEN EXTRACT(MONTH FROM r.rental_start_date) IN (6, 7, 8) THEN 'Summer Peak'
        WHEN EXTRACT(MONTH FROM r.rental_start_date) IN (5, 9) THEN 'Shoulder Season'
        WHEN EXTRACT(MONTH FROM r.rental_start_date) IN (12, 1) THEN 'Winter Holiday'
        ELSE 'Regular Season'
    END as seasonal_period
FROM rentals r
LEFT JOIN customers c ON r.customer_id = c.customer_id
LEFT JOIN vehicles v ON r.vehicle_id = v.vehicle_id
LEFT JOIN locations pl ON r.pickup_location_id = pl.location_id
LEFT JOIN locations dl ON r.dropoff_location_id = dl.location_id;

-- VEHICLE_PERFORMANCE: Vehicle utilization and performance metrics
CREATE OR REPLACE VIEW VEHICLE_PERFORMANCE AS
SELECT 
    v.vehicle_id,
    v.vehicle_type,
    v.vehicle_subtype,
    v.make || ' ' || v.model as vehicle_make_model,
    v.year as vehicle_year,
    v.current_location_id,
    l.city as current_city,
    l.state as current_state,
    v.vehicle_status,
    v.mileage as current_mileage,
    v.daily_rate,
    v.mileage_rate,
    v.acquisition_date,
    DATEDIFF(day, v.acquisition_date, CURRENT_DATE()) as days_in_fleet,
    v.last_maintenance_date,
    DATEDIFF(day, v.last_maintenance_date, CURRENT_DATE()) as days_since_maintenance,
    v.next_maintenance_due_mileage,
    v.next_maintenance_due_mileage - v.mileage as miles_to_maintenance,
    -- Rental metrics (last 12 months)
    COALESCE(rental_stats.total_rentals, 0) as total_rentals_12mo,
    COALESCE(rental_stats.total_revenue, 0) as total_revenue_12mo,
    COALESCE(rental_stats.total_miles_driven, 0) as total_miles_driven_12mo,
    COALESCE(rental_stats.avg_rental_duration, 0) as avg_rental_duration_hours,
    COALESCE(rental_stats.avg_customer_rating, 0) as avg_customer_rating,
    -- Utilization metrics
    ROUND(COALESCE(rental_stats.total_rental_days, 0) / 365.0 * 100, 1) as utilization_rate_percent,
    ROUND(COALESCE(rental_stats.total_revenue, 0) / NULLIF(DATEDIFF(day, v.acquisition_date, CURRENT_DATE()), 0), 2) as revenue_per_day_owned,
    -- Maintenance metrics
    COALESCE(maint_stats.total_maintenance_events, 0) as maintenance_events_12mo,
    COALESCE(maint_stats.total_maintenance_cost, 0) as maintenance_cost_12mo,
    COALESCE(maint_stats.total_downtime_hours, 0) as maintenance_downtime_hours_12mo,
    -- Performance categories
    CASE 
        WHEN COALESCE(rental_stats.total_rentals, 0) = 0 THEN 'No Activity'
        WHEN COALESCE(rental_stats.total_rentals, 0) < 12 THEN 'Low Activity'
        WHEN COALESCE(rental_stats.total_rentals, 0) < 50 THEN 'Moderate Activity'
        ELSE 'High Activity'
    END as activity_level,
    CASE 
        WHEN COALESCE(rental_stats.avg_customer_rating, 0) >= 4.5 THEN 'Excellent'
        WHEN COALESCE(rental_stats.avg_customer_rating, 0) >= 4.0 THEN 'Good'
        WHEN COALESCE(rental_stats.avg_customer_rating, 0) >= 3.0 THEN 'Fair'
        WHEN COALESCE(rental_stats.avg_customer_rating, 0) > 0 THEN 'Poor'
        ELSE 'No Ratings'
    END as customer_satisfaction_level
FROM vehicles v
LEFT JOIN locations l ON v.current_location_id = l.location_id
LEFT JOIN (
    SELECT 
        vehicle_id,
        COUNT(*) as total_rentals,
        SUM(total_amount) as total_revenue,
        SUM(miles_driven) as total_miles_driven,
        SUM(DATEDIFF(day, rental_start_date, actual_return_date)) as total_rental_days,
        AVG(DATEDIFF(hour, rental_start_date, actual_return_date)) as avg_rental_duration,
        AVG(customer_rating) as avg_customer_rating
    FROM rentals 
    WHERE rental_start_date >= DATEADD(year, -1, CURRENT_DATE())
      AND rental_status = 'Completed'
    GROUP BY vehicle_id
) rental_stats ON v.vehicle_id = rental_stats.vehicle_id
LEFT JOIN (
    SELECT 
        vehicle_id,
        COUNT(*) as total_maintenance_events,
        SUM(total_cost) as total_maintenance_cost,
        SUM(vehicle_out_of_service_hours) as total_downtime_hours
    FROM maintenance_events 
    WHERE service_date >= DATEADD(year, -1, CURRENT_DATE())
    GROUP BY vehicle_id
) maint_stats ON v.vehicle_id = maint_stats.vehicle_id;

-- CUSTOMER_INSIGHTS: Customer behavior and segmentation
CREATE OR REPLACE VIEW CUSTOMER_INSIGHTS AS
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    c.email,
    c.customer_tier,
    c.customer_since,
    DATEDIFF(year, c.customer_since, CURRENT_DATE()) as years_as_customer,
    c.total_rentals as lifetime_rentals,
    c.total_spent as lifetime_spent,
    c.credit_score_range,
    -- Recent activity (last 12 months)
    COALESCE(recent_stats.rentals_12mo, 0) as rentals_12mo,
    COALESCE(recent_stats.revenue_12mo, 0) as revenue_12mo,
    COALESCE(recent_stats.miles_driven_12mo, 0) as miles_driven_12mo,
    COALESCE(recent_stats.avg_rating_given, 0) as avg_rating_given,
    COALESCE(recent_stats.preferred_vehicle_type, 'None') as preferred_vehicle_type,
    COALESCE(recent_stats.preferred_channel, 'None') as preferred_reservation_channel,
    -- Customer value metrics
    ROUND(c.total_spent / NULLIF(c.total_rentals, 0), 2) as avg_revenue_per_rental,
    ROUND(COALESCE(recent_stats.revenue_12mo, 0) / NULLIF(COALESCE(recent_stats.rentals_12mo, 0), 0), 2) as avg_revenue_per_rental_12mo,
    -- Customer segmentation
    CASE 
        WHEN c.total_rentals = 0 THEN 'Inactive'
        WHEN c.total_rentals = 1 THEN 'One-Time'
        WHEN c.total_rentals <= 5 THEN 'Occasional'
        WHEN c.total_rentals <= 15 THEN 'Regular'
        ELSE 'Frequent'
    END as rental_frequency_segment,
    CASE 
        WHEN c.total_spent < 100 THEN 'Low Value'
        WHEN c.total_spent < 500 THEN 'Medium Value'
        WHEN c.total_spent < 2000 THEN 'High Value'
        ELSE 'Premium Value'
    END as lifetime_value_segment,
    CASE 
        WHEN COALESCE(recent_stats.rentals_12mo, 0) = 0 THEN 'Dormant'
        WHEN COALESCE(recent_stats.rentals_12mo, 0) <= 2 THEN 'Low Activity'
        WHEN COALESCE(recent_stats.rentals_12mo, 0) <= 6 THEN 'Moderate Activity'
        ELSE 'High Activity'
    END as recent_activity_level,
    -- Risk indicators
    CASE 
        WHEN COALESCE(recent_stats.late_returns, 0) > 0 THEN TRUE 
        ELSE FALSE 
    END as has_late_returns,
    CASE 
        WHEN COALESCE(recent_stats.damage_incidents, 0) > 0 THEN TRUE 
        ELSE FALSE 
    END as has_damage_incidents,
    COALESCE(recent_stats.late_returns, 0) as late_returns_12mo,
    COALESCE(recent_stats.damage_incidents, 0) as damage_incidents_12mo
FROM customers c
LEFT JOIN (
    SELECT 
        customer_id,
        COUNT(*) as rentals_12mo,
        SUM(total_amount) as revenue_12mo,
        SUM(miles_driven) as miles_driven_12mo,
        AVG(customer_rating) as avg_rating_given,
        MODE(vehicle_type) as preferred_vehicle_type,
        MODE(reservation_channel) as preferred_channel,
        SUM(CASE WHEN late_fees > 0 THEN 1 ELSE 0 END) as late_returns,
        SUM(CASE WHEN damage_fees > 0 THEN 1 ELSE 0 END) as damage_incidents
    FROM rental_analytics 
    WHERE rental_start_date >= DATEADD(year, -1, CURRENT_DATE())
    GROUP BY customer_id
) recent_stats ON c.customer_id = recent_stats.customer_id;

-- FLEET_HEALTH: Vehicle maintenance and operational status
CREATE OR REPLACE VIEW FLEET_HEALTH AS
SELECT 
    v.vehicle_id,
    v.vehicle_type,
    v.vehicle_subtype,
    v.make || ' ' || v.model as vehicle_make_model,
    v.year as vehicle_year,
    v.vehicle_status,
    v.mileage as current_mileage,
    v.last_maintenance_date,
    v.next_maintenance_due_mileage,
    v.next_maintenance_due_mileage - v.mileage as miles_to_next_maintenance,
    DATEDIFF(day, v.last_maintenance_date, CURRENT_DATE()) as days_since_maintenance,
    -- Maintenance urgency
    CASE 
        WHEN v.next_maintenance_due_mileage - v.mileage <= 0 THEN 'Overdue'
        WHEN v.next_maintenance_due_mileage - v.mileage <= 500 THEN 'Due Soon'
        WHEN v.next_maintenance_due_mileage - v.mileage <= 1500 THEN 'Upcoming'
        ELSE 'Current'
    END as maintenance_status,
    -- Recent maintenance history
    COALESCE(maint_summary.total_events_12mo, 0) as maintenance_events_12mo,
    COALESCE(maint_summary.total_cost_12mo, 0) as maintenance_cost_12mo,
    COALESCE(maint_summary.preventive_events, 0) as preventive_maintenance_12mo,
    COALESCE(maint_summary.repair_events, 0) as repair_events_12mo,
    COALESCE(maint_summary.total_downtime_hours, 0) as downtime_hours_12mo,
    COALESCE(maint_summary.warranty_claims, 0) as warranty_claims_12mo,
    -- Vehicle age and utilization
    DATEDIFF(year, TO_DATE(v.year || '-01-01'), CURRENT_DATE()) as vehicle_age_years,
    ROUND(v.mileage / NULLIF(DATEDIFF(year, v.acquisition_date, CURRENT_DATE()), 0), 0) as avg_miles_per_year,
    -- Health indicators
    CASE 
        WHEN COALESCE(maint_summary.repair_events, 0) = 0 THEN 'Excellent'
        WHEN COALESCE(maint_summary.repair_events, 0) <= 2 THEN 'Good'
        WHEN COALESCE(maint_summary.repair_events, 0) <= 5 THEN 'Fair'
        ELSE 'Poor'
    END as reliability_rating,
    CASE 
        WHEN COALESCE(maint_summary.total_cost_12mo, 0) < 500 THEN 'Low Cost'
        WHEN COALESCE(maint_summary.total_cost_12mo, 0) < 1500 THEN 'Moderate Cost'
        WHEN COALESCE(maint_summary.total_cost_12mo, 0) < 3000 THEN 'High Cost'
        ELSE 'Very High Cost'
    END as maintenance_cost_category
FROM vehicles v
LEFT JOIN (
    SELECT 
        vehicle_id,
        COUNT(*) as total_events_12mo,
        SUM(total_cost) as total_cost_12mo,
        SUM(CASE WHEN maintenance_type = 'Preventive' THEN 1 ELSE 0 END) as preventive_events,
        SUM(CASE WHEN maintenance_type = 'Repair' THEN 1 ELSE 0 END) as repair_events,
        SUM(vehicle_out_of_service_hours) as total_downtime_hours,
        SUM(CASE WHEN warranty_claim = TRUE THEN 1 ELSE 0 END) as warranty_claims
    FROM maintenance_events 
    WHERE service_date >= DATEADD(year, -1, CURRENT_DATE())
    GROUP BY vehicle_id
) maint_summary ON v.vehicle_id = maint_summary.vehicle_id;

-- REVENUE_ANALYSIS: Financial performance and trends
CREATE OR REPLACE VIEW REVENUE_ANALYSIS AS
SELECT 
    rental_year,
    rental_month,
    rental_month_name,
    rental_quarter,
    seasonal_period,
    vehicle_type,
    trip_type,
    pickup_state,
    -- Volume metrics
    COUNT(*) as total_rentals,
    COUNT(DISTINCT customer_id) as unique_customers,
    COUNT(DISTINCT vehicle_id) as vehicles_used,
    -- Revenue metrics
    SUM(total_amount) as total_revenue,
    SUM(base_rate) as base_revenue,
    SUM(mileage_charges) as mileage_revenue,
    SUM(equipment_charges) as equipment_revenue,
    SUM(fuel_charges) as fuel_revenue,
    SUM(late_fees) as late_fee_revenue,
    SUM(damage_fees) as damage_fee_revenue,
    -- Averages
    AVG(total_amount) as avg_revenue_per_rental,
    AVG(miles_driven) as avg_miles_per_rental,
    AVG(actual_rental_hours) as avg_rental_duration_hours,
    AVG(customer_rating) as avg_customer_rating,
    -- Operational metrics
    SUM(miles_driven) as total_miles_driven,
    SUM(actual_rental_hours) as total_rental_hours,
    COUNT(CASE WHEN is_late_return THEN 1 END) as late_returns,
    COUNT(CASE WHEN damage_fees > 0 THEN 1 END) as damage_incidents,
    -- Percentages
    ROUND(COUNT(CASE WHEN is_late_return THEN 1 END) * 100.0 / COUNT(*), 1) as late_return_rate_percent,
    ROUND(COUNT(CASE WHEN damage_fees > 0 THEN 1 END) * 100.0 / COUNT(*), 1) as damage_incident_rate_percent,
    ROUND(SUM(equipment_charges) * 100.0 / SUM(total_amount), 1) as equipment_revenue_percent
FROM rental_analytics
WHERE rental_status = 'Completed'
GROUP BY 
    rental_year, rental_month, rental_month_name, rental_quarter, 
    seasonal_period, vehicle_type, trip_type, pickup_state;

-- Create the main semantic view for Intelligence Agent
USE SCHEMA SEMANTICS;

CREATE OR REPLACE VIEW UHAUL_SEMANTIC AS
SELECT 
    -- Rental Information
    ra.rental_id,
    ra.rental_start_date as "Rental Start Date",
    ra.rental_end_date as "Rental End Date", 
    ra.actual_return_date as "Actual Return Date",
    ra.rental_status as "Rental Status",
    ra.is_late_return as "Late Return",
    ra.late_hours as "Hours Late",
    
    -- Customer Information
    ra.customer_id,
    ra.customer_name as "Customer Name",
    ra.customer_tier as "Customer Tier",
    ci.years_as_customer as "Years as Customer",
    ci.lifetime_rentals as "Customer Lifetime Rentals",
    ci.lifetime_spent as "Customer Lifetime Spent",
    ci.rental_frequency_segment as "Customer Frequency Segment",
    ci.lifetime_value_segment as "Customer Value Segment",
    ci.recent_activity_level as "Customer Activity Level",
    
    -- Vehicle Information  
    ra.vehicle_id,
    ra.vehicle_type as "Vehicle Type",
    ra.vehicle_subtype as "Vehicle Size",
    ra.vehicle_make_model as "Vehicle Make Model",
    ra.vehicle_year as "Vehicle Year",
    vp.current_city as "Vehicle Current City",
    vp.current_state as "Vehicle Current State",
    vp.vehicle_status as "Vehicle Status",
    vp.utilization_rate_percent as "Vehicle Utilization Rate",
    vp.activity_level as "Vehicle Activity Level",
    
    -- Location Information
    ra.pickup_city as "Pickup City",
    ra.pickup_state as "Pickup State", 
    ra.dropoff_city as "Dropoff City",
    ra.dropoff_state as "Dropoff State",
    ra.trip_type as "Trip Type",
    
    -- Trip Details
    ra.miles_driven as "Miles Driven",
    ra.actual_rental_hours as "Rental Duration Hours",
    ra.distance_category as "Distance Category",
    ra.duration_category as "Duration Category",
    
    -- Financial Information
    ra.total_amount as "Total Revenue",
    ra.base_rate as "Base Rate",
    ra.mileage_charges as "Mileage Charges",
    ra.equipment_charges as "Equipment Charges", 
    ra.fuel_charges as "Fuel Charges",
    ra.late_fees as "Late Fees",
    ra.damage_fees as "Damage Fees",
    ra.revenue_per_mile as "Revenue per Mile",
    ra.revenue_per_hour as "Revenue per Hour",
    
    -- Operational Information
    ra.payment_method as "Payment Method",
    ra.reservation_channel as "Reservation Channel",
    ra.customer_rating as "Customer Rating",
    
    -- Time Dimensions
    ra.rental_year as "Rental Year",
    ra.rental_month as "Rental Month", 
    ra.rental_month_name as "Rental Month Name",
    ra.rental_quarter as "Rental Quarter",
    ra.rental_day_of_week as "Rental Day of Week",
    ra.rental_day_type as "Rental Day Type",
    ra.seasonal_period as "Seasonal Period",
    
    -- Fleet Health (for vehicles in this rental)
    fh.maintenance_status as "Vehicle Maintenance Status",
    fh.days_since_maintenance as "Days Since Last Maintenance",
    fh.miles_to_next_maintenance as "Miles to Next Maintenance",
    fh.reliability_rating as "Vehicle Reliability Rating",
    fh.maintenance_cost_category as "Vehicle Maintenance Cost Category"
    
FROM UHAUL_DEMO.ANALYTICS.RENTAL_ANALYTICS ra
LEFT JOIN UHAUL_DEMO.ANALYTICS.CUSTOMER_INSIGHTS ci ON ra.customer_id = ci.customer_id  
LEFT JOIN UHAUL_DEMO.ANALYTICS.VEHICLE_PERFORMANCE vp ON ra.vehicle_id = vp.vehicle_id
LEFT JOIN UHAUL_DEMO.ANALYTICS.FLEET_HEALTH fh ON ra.vehicle_id = fh.vehicle_id;

-- Display semantic layer creation completion
SELECT 'U-Haul Demo Semantic Layer Created Successfully!' as STATUS,
       (SELECT COUNT(*) FROM UHAUL_DEMO.ANALYTICS.RENTAL_ANALYTICS) as RENTAL_RECORDS,
       (SELECT COUNT(*) FROM UHAUL_DEMO.ANALYTICS.VEHICLE_PERFORMANCE) as VEHICLE_RECORDS,
       (SELECT COUNT(*) FROM UHAUL_DEMO.ANALYTICS.CUSTOMER_INSIGHTS) as CUSTOMER_RECORDS,
       (SELECT COUNT(*) FROM UHAUL_DEMO.ANALYTICS.FLEET_HEALTH) as FLEET_RECORDS,
       (SELECT COUNT(*) FROM UHAUL_SEMANTIC) as SEMANTIC_RECORDS;

/*
 * IMPORTANT: After running this script, you need to create a Semantic View in Snowsight UI
 * 
 * Steps to create the Semantic View for Intelligence Agent:
 * 1. In Snowsight, navigate to Data > Databases > UHAUL_DEMO > SEMANTICS
 * 2. Click on the UHAUL_SEMANTIC view
 * 3. Click "Create Semantic View" button
 * 4. Name it "U-Haul Operations Semantic View"
 * 5. Add descriptions for key columns to help the AI understand the data
 * 6. Save the semantic view
 * 
 * See AGENT_SETUP.md for detailed instructions.
 */
