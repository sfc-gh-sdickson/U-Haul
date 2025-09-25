# Snowflake Intelligence Demo: U-Haul Operations

This repository contains a comprehensive, end-to-end demo showcasing Snowflake Intelligence with natural language queries over synthetic U-Haul rental operations data. The demo enables business users to ask questions about fleet management, rental operations, customer insights, and revenue analytics using conversational AI.

## 🚀 Quick Demo

Ask questions like:
- *"Show me our top performing locations by revenue"*
- *"Which vehicles need maintenance in the next 30 days?"*
- *"What's our customer satisfaction trend over the past year?"*
- *"Compare summer vs winter rental patterns"*
- *"Which customer segments are most profitable?"*

## 📋 Contents

### SQL Scripts (Run in Order)
- **`sql/00_setup.sql`** — Create warehouse, roles, database, schemas, and grants
- **`sql/01_tables.sql`** — Create tables for vehicles, customers, rentals, telemetry, and maintenance
- **`sql/02_load_synthetic.sql`** — Generate deterministic synthetic data with realistic business patterns
- **`sql/03_semantics.sql`** — Create semantic views and analytics layer for Intelligence Agent
- **`sql/99_cleanup.sql`** — Complete teardown script for demo cleanup

### Documentation
- **`AGENT_SETUP.md`** — Step-by-step guide to configure Intelligence Agent with sample queries
- **`README.md`** — This file with quickstart instructions

## 🎯 Demo Highlights

### Realistic Business Data
- **100 U-Haul locations** across major US cities
- **2,000 vehicles** with realistic fleet composition (trucks, vans, trailers)
- **5,000 customers** with diverse profiles and rental history
- **15,000 rental transactions** with seasonal patterns and business logic
- **Real-time vehicle telemetry** data for fleet monitoring
- **Comprehensive maintenance records** for operational insights

### Business Intelligence Ready
- **Revenue analytics** with seasonal trends and profitability insights
- **Fleet performance** metrics including utilization and maintenance costs
- **Customer segmentation** based on value, frequency, and behavior
- **Operational KPIs** for late returns, damage incidents, and satisfaction

### Natural Language Queries
- Ask complex business questions in plain English
- Get instant insights without writing SQL
- Interactive charts and visualizations
- Contextual business recommendations

## 🚀 Quickstart

### Prerequisites
- Snowflake account with Intelligence features enabled
- Role with privileges to create warehouses, databases, and objects
- Access to Snowsight UI

### Setup (15 minutes)

1. **Clone or download this repository**
   ```bash
   git clone <repository-url>
   cd U-Haul
   ```

2. **Run SQL scripts in Snowsight Worksheets**
   ```sql
   -- Step 1: Infrastructure setup
   -- Copy and run sql/00_setup.sql
   
   -- Step 2: Create tables  
   -- Copy and run sql/01_tables.sql
   
   -- Step 3: Load synthetic data (takes 2-3 minutes)
   -- Copy and run sql/02_load_synthetic.sql
   
   -- Step 4: Create semantic layer
   -- Copy and run sql/03_semantics.sql
   ```

3. **Configure Intelligence Agent**
   - Follow the detailed steps in `AGENT_SETUP.md`
   - Create Semantic View in Snowsight UI
   - Set up Intelligence Agent with business context

4. **Start asking questions!**
   - Test with sample queries from `AGENT_SETUP.md`
   - Explore your U-Haul operations data

## 📊 Sample Business Scenarios

### Operations Manager
*"Which locations have the highest vehicle utilization rates?"*
- Identifies top-performing locations
- Shows fleet efficiency metrics
- Highlights optimization opportunities

### Revenue Analyst  
*"What's driving our revenue growth this quarter compared to last year?"*
- Breaks down revenue by vehicle type, location, and time period
- Shows seasonal trends and growth drivers
- Identifies high-value customer segments

### Fleet Manager
*"Show me vehicles that are overdue for maintenance or have high repair costs"*
- Lists vehicles requiring immediate attention
- Displays maintenance cost trends
- Helps prioritize fleet investments

### Customer Success
*"What factors correlate with low customer ratings?"*
- Analyzes satisfaction drivers
- Identifies service improvement opportunities
- Shows impact of operational issues on customer experience

## 🎨 Demo Script for Customer Presentations

### Opening Hook (2 minutes)
"Imagine your operations team could ask questions about your business in plain English and get instant, accurate answers. Today I'll show you exactly how Snowflake Intelligence makes this possible with real U-Haul operations data."

### Core Demo Flow (15 minutes)

#### Scenario 1: Executive Dashboard (3 minutes)
- **Query**: *"Show me our key performance metrics for this quarter"*
- **Highlight**: Instant KPI summary without pre-built dashboards

#### Scenario 2: Operational Deep-dive (4 minutes)  
- **Query**: *"Which vehicles have the highest maintenance costs and why?"*
- **Follow-up**: *"Show me the utilization rates for these high-maintenance vehicles"*
- **Highlight**: Complex multi-table analysis in natural language

#### Scenario 3: Customer Analytics (4 minutes)
- **Query**: *"Segment our customers by profitability and rental frequency"*
- **Follow-up**: *"What's the retention rate for each segment?"*
- **Highlight**: Advanced analytics accessible to business users

#### Scenario 4: Predictive Insights (4 minutes)
- **Query**: *"Based on historical patterns, when should we expect peak demand?"*
- **Follow-up**: *"How should we position our fleet for the busy season?"*
- **Highlight**: Data-driven decision making

### Closing Impact (3 minutes)
"This is the power of Snowflake Intelligence - turning your data into a conversational partner that anyone in your organization can use to make better, faster decisions."

## 🔧 Customization for Your Environment

### Adapting the Demo
1. **Modify business context** in `AGENT_SETUP.md` to match your customer's industry
2. **Adjust data volumes** in `02_load_synthetic.sql` for performance requirements  
3. **Customize semantic layer** in `03_semantics.sql` for specific business metrics
4. **Update sample queries** to reflect customer use cases

### Extending the Demo
- Add more data sources (weather, economic indicators, competitor data)
- Include external APIs for real-time data enrichment
- Create industry-specific KPIs and metrics
- Build complementary Snowsight dashboards

## 📈 Key Demo Metrics

### Data Scale
- **100** U-Haul locations
- **2,000** vehicles in fleet
- **5,000** customers  
- **15,000** rental transactions
- **50,000+** telemetry records
- **6,000** maintenance events

### Business Realism
- ✅ Seasonal rental patterns (summer peak)
- ✅ Geographic distribution across US markets
- ✅ Realistic vehicle utilization rates
- ✅ Customer lifecycle and segmentation
- ✅ Maintenance schedules and costs
- ✅ Revenue optimization scenarios

## 🛠️ Technical Details

### Architecture
- **Raw Data Layer**: Normalized tables with referential integrity
- **Analytics Layer**: Business-friendly views with calculated metrics
- **Semantic Layer**: Natural language optimized view for AI agent
- **Intelligence Layer**: Conversational AI with business context

### Performance Optimization
- Deterministic synthetic data generation (no external dependencies)
- Efficient SQL with proper indexing strategies
- Optimized semantic views for fast query response
- Scalable architecture for larger datasets

### Security & Governance
- Role-based access control (RBAC) implementation
- Data masking capabilities for sensitive information
- Audit trails for all Intelligence Agent interactions
- Compliance-ready data governance framework

## 🧹 Cleanup

When you're done with the demo:

```sql
-- Run the cleanup script to remove all demo objects
-- Copy and run sql/99_cleanup.sql
```

**Note**: Also manually delete any Semantic Views and Intelligence Agents created in Snowsight UI.

## 🎯 Converting to Snowflake Quickstart

This demo is designed to be easily converted into a Snowflake Quickstart guide:

### Quickstart Adaptation Steps
1. **Add Quickstart metadata** (duration, audience, prerequisites)
2. **Create step-by-step tutorial format** with screenshots
3. **Add validation checkpoints** at each major step
4. **Include troubleshooting section** with common issues
5. **Provide learning objectives** and success criteria

### Suggested Quickstart Structure
- **Introduction** (5 minutes): Business context and learning objectives
- **Setup** (10 minutes): Environment preparation and data loading
- **Configuration** (10 minutes): Semantic View and Agent setup
- **Exploration** (15 minutes): Guided query examples and insights
- **Advanced Usage** (10 minutes): Complex scenarios and customization
- **Conclusion** (5 minutes): Next steps and additional resources

## 📞 Support & Resources

### For Technical Issues
- Verify Snowflake account has Intelligence features enabled
- Check role permissions and grants
- Validate data loading with provided SQL queries
- Review Snowflake Intelligence documentation

### For Demo Customization
- Modify synthetic data parameters in `02_load_synthetic.sql`
- Adjust business context in `AGENT_SETUP.md`
- Customize semantic layer descriptions for your use case
- Create industry-specific sample queries

### For Production Implementation
- Scale data volumes appropriately
- Implement proper security and governance
- Add real-time data integration
- Create comprehensive user training materials

---

## 🏆 Demo Success Metrics

Track these metrics to measure demo effectiveness:

### Engagement Metrics
- Time spent exploring the Intelligence Agent
- Number of unique queries attempted
- Complexity progression of questions asked
- Follow-up questions and deeper exploration

### Business Impact Metrics  
- Insights discovered that weren't obvious from traditional reports
- "Aha moments" when business users see new possibilities
- Questions about implementing similar capabilities
- Requests for follow-up meetings or POCs

### Technical Validation Metrics
- Query response times and accuracy
- Successful completion of all demo scenarios
- Ability to handle unexpected questions
- Integration possibilities with existing systems

---

*This demo showcases the power of Snowflake Intelligence to transform how organizations interact with their data. By making advanced analytics accessible through natural language, we enable every business user to become a data analyst.*
