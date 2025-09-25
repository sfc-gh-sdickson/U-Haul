<img src="Snowflake_Logo.svg" width="200">

# U-Haul Intelligence Agent Setup Guide

This guide walks you through configuring a Snowflake Intelligence Agent to interact with the U-Haul demo data using natural language queries.

## Prerequisites

Before setting up the Intelligence Agent, ensure you have:

1. ✅ Completed the SQL setup scripts in order:
   - `sql/00_setup.sql` - Infrastructure setup
   - `sql/01_tables.sql` - Table creation  
   - `sql/02_load_synthetic.sql` - Synthetic data loading
   - `sql/03_semantics.sql` - Semantic layer creation

2. ✅ Access to Snowsight with Intelligence features enabled
3. ✅ Appropriate privileges to create Semantic Views and Intelligence Agents

## Step 1: Create the Semantic View in Snowsight UI

The Intelligence Agent requires a Semantic View to understand your data structure and business context.

### 1.1 Navigate to the Semantic View
1. Open Snowsight in your browser
2. Navigate to **Data** → **Databases** → **UHAUL_DEMO** → **SEMANTICS**
3. Click on the **UHAUL_SEMANTIC** view
4. Click the **"Create Semantic View"** button

### 1.2 Configure the Semantic View
1. **Name**: `U-Haul Operations Semantic View`
2. **Description**: `Comprehensive view of U-Haul rental operations, vehicle fleet, and customer data for natural language analysis`

### 1.3 Add Column Descriptions
Add meaningful descriptions for key columns to help the AI understand your data:

| Column Name | Suggested Description |
|-------------|----------------------|
| `Rental Start Date` | The date and time when the rental period began |
| `Customer Name` | Full name of the customer who made the rental |
| `Vehicle Type` | Type of vehicle rented (Pickup Truck, Cargo Van, Moving Truck, Trailer) |
| `Vehicle Size` | Specific size/capacity of the vehicle (10ft, 15ft, 20ft, 26ft, etc.) |
| `Trip Type` | Classification of the rental trip (Round Trip, Local One-Way, Interstate One-Way) |
| `Total Revenue` | Total amount charged for the rental including all fees |
| `Miles Driven` | Total miles driven during the rental period |
| `Customer Rating` | Rating given by customer (1-5 stars) |
| `Rental Status` | Current status of the rental (Active, Completed, Cancelled) |
| `Seasonal Period` | Time of year classification (Summer Peak, Shoulder Season, etc.) |
| `Vehicle Utilization Rate` | Percentage of time the vehicle was rented in the last 12 months |
| `Customer Frequency Segment` | Customer classification based on rental frequency |
| `Vehicle Maintenance Status` | Current maintenance status (Current, Due Soon, Overdue) |

### 1.4 Save the Semantic View
1. Review your configuration
2. Click **"Save"** to create the Semantic View

## Step 2: Create the Intelligence Agent

### 2.1 Navigate to Intelligence Agents
1. In Snowsight, navigate to **AI & ML** → **Agents**
2. Click **"Create Agent"**

### 2.2 Configure Basic Settings
1. **Agent Name**: `U-Haul Operations Assistant`
2. **Description**: `AI assistant for analyzing U-Haul rental operations, fleet performance, and customer insights`

### 2.3 Configure Data Sources
1. **Primary Data Source**: Select your `U-Haul Operations Semantic View`
2. **Additional Context**: Add any relevant business context about U-Haul operations

### 2.4 Set Agent Instructions
Add these instructions to help the agent understand the business context:

```
You are an AI assistant specialized in U-Haul rental operations analysis. You help users understand:

1. RENTAL OPERATIONS: Analyze rental patterns, revenue trends, and operational metrics
2. FLEET MANAGEMENT: Monitor vehicle utilization, maintenance needs, and performance
3. CUSTOMER INSIGHTS: Understand customer behavior, segmentation, and satisfaction
4. BUSINESS INTELLIGENCE: Provide actionable insights for operational improvements

Key Business Context:
- U-Haul operates a large fleet of rental vehicles including pickup trucks, cargo vans, moving trucks, and trailers
- Customers rent vehicles for moving, hauling, and transportation needs
- Peak season is typically summer months (May-September) when people move most frequently
- Vehicle maintenance is critical for safety and customer satisfaction
- Customer ratings and repeat business are key success metrics

When answering questions:
- Focus on actionable business insights
- Highlight trends and patterns in the data
- Consider seasonal variations in rental demand
- Explain the business impact of your findings
- Suggest operational improvements when relevant
```

### 2.5 Configure Response Settings
1. **Response Style**: Professional and analytical
2. **Data Visualization**: Enable charts and graphs when helpful
3. **Confidence Threshold**: Medium (to balance accuracy with responsiveness)

### 2.6 Save and Test the Agent
1. Click **"Create Agent"**
2. Test with a simple query like: "Show me rental revenue trends by month"

## Step 3: Test the Intelligence Agent

Try these sample queries to verify your setup:

### Basic Queries
- "How many rentals did we have last month?"
- "What's our most popular vehicle type?"
- "Show me revenue by state"

### Analytical Queries  
- "Which vehicles need maintenance soon?"
- "What factors correlate with high customer ratings?"
- "Show seasonal rental patterns"

### Business Intelligence Queries
- "Which customer segments are most profitable?"
- "What's our vehicle utilization rate by type?"
- "Identify trends in late returns and damage incidents"

### Advanced Queries
- "Compare summer vs winter rental patterns"
- "Which locations have the highest revenue per vehicle?"
- "Show me customers at risk of churning"

## Step 4: Demo Script for Customer Presentations

Use this script structure for customer demos:

### Opening (2 minutes)
"Today I'll show you how Snowflake Intelligence transforms your rental operations data into actionable insights using natural language queries."

### Core Demo Scenarios (15 minutes)

#### Scenario 1: Operations Manager
**Query**: "Show me our busiest rental locations and their performance metrics"
**Follow-up**: "Which vehicles at these locations need maintenance?"

#### Scenario 2: Revenue Analysis
**Query**: "What's driving our revenue growth this quarter?"
**Follow-up**: "Compare revenue per mile across different vehicle types"

#### Scenario 3: Fleet Management
**Query**: "Which vehicles have the highest maintenance costs?"
**Follow-up**: "Show me utilization rates for vehicles with high maintenance costs"

#### Scenario 4: Customer Experience
**Query**: "What factors lead to low customer ratings?"
**Follow-up**: "Show me the relationship between late returns and customer satisfaction"

### Closing (3 minutes)
"As you can see, Snowflake Intelligence enables anyone in your organization to get instant answers from your data without writing SQL or waiting for reports."

## Troubleshooting

### Common Issues

**Issue**: Agent doesn't understand business terms
**Solution**: Add more column descriptions and business context in the Semantic View

**Issue**: Queries return unexpected results  
**Solution**: Check that all SQL scripts ran successfully and data loaded properly

**Issue**: Agent is too slow
**Solution**: Adjust confidence threshold or simplify the semantic view

**Issue**: Agent can't access data
**Solution**: Verify role permissions and grants are properly configured

### Validation Queries

Run these SQL queries to validate your setup:

```sql
-- Check data counts
SELECT 
    (SELECT COUNT(*) FROM UHAUL_DEMO.RAW_DATA.RENTALS) as rentals,
    (SELECT COUNT(*) FROM UHAUL_DEMO.RAW_DATA.VEHICLES) as vehicles,
    (SELECT COUNT(*) FROM UHAUL_DEMO.RAW_DATA.CUSTOMERS) as customers;

-- Check semantic view
SELECT COUNT(*) FROM UHAUL_DEMO.SEMANTICS.UHAUL_SEMANTIC;

-- Sample data verification
SELECT * FROM UHAUL_DEMO.SEMANTICS.UHAUL_SEMANTIC LIMIT 5;
```

## Next Steps

1. **Customize for Your Environment**: Modify column descriptions and agent instructions based on your specific use case
2. **Add More Data Sources**: Connect additional relevant data sources to the agent
3. **Create Dashboards**: Build Snowsight dashboards to complement the conversational interface
4. **Train Users**: Provide training on effective query techniques
5. **Monitor Usage**: Track agent usage and optimize based on common query patterns

## Support

For technical issues:
- Check Snowflake documentation for Intelligence features
- Verify your account has Intelligence capabilities enabled
- Contact your Snowflake representative for advanced configuration help

For demo-specific issues:
- Ensure all SQL scripts completed successfully
- Verify data loaded correctly using the validation queries above
- Check that semantic view was created properly in Snowsight UI
