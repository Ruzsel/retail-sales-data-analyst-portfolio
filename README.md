# Retail Sales Data Analyst Portfolio

## Overview
This project demonstrates an end-to-end data analytics workflow using PostgreSQL and Power BI.
The objective is to analyze retail sales performance and provide business insights through proper data preparation, modeling, and visualization.

This portfolio is designed to reflect real-world data analyst practices, including handling data quality issues and making business-driven modeling decisions.

---

## Business Context
The retail business requires visibility into:
- Overall sales performance
- Revenue trends over time
- Market and product contribution
- Customer behavior, especially repeat customers

The analysis aims to support data-driven decision-making for business and management teams.

---

## Data Source
- Retail transaction data (invoice-level)
- Period: December 2010 – December 2011
- Data includes transactions, customers, products, and countries

---

## Tools & Technologies
- PostgreSQL
- SQL (CTE, window function, aggregation)
- Power BI

---

## Data Preparation
Raw data is stored in PostgreSQL as `raw_sales`.

A logical layer `cleaned_sales` is created to:
- Remove cancelled and returned transactions
- Filter invalid quantity and price values
- Handle exact duplicate records using window function (`row_number`)

This ensures all downstream analysis uses validated and consistent data.

---

## Data Modeling
The data is modeled using a star schema approach:

- `fact_sales`
  - Transaction-level data and metrics
  - Revenue calculated at invoice-item level
  - Built using window function to avoid duplicate transactions

- `dim_customer`
  - `customerid` treated as a single business entity
  - One customer may appear in multiple countries in raw data
  - To maintain entity consistency, the country with the highest revenue contribution is selected for each customer

- `dim_product`
  - `stockcode` treated as a single product entity
  - Multiple descriptions found due to inconsistent text entries
  - The description with the highest revenue contribution is selected for each product

These decisions are made to balance data integrity and business relevance.

---

## Analysis Highlights
Key analyses include:
- KPI monitoring (Total Revenue, Total Orders, Total Customers, AOV)
- Monthly sales trend analysis
- Revenue contribution by country and product
- Customer analysis (new vs returning customers)
- Cohort analysis to understand customer retention behavior

---

## Dashboard
The Power BI dashboard consists of two main pages:
1. Performance Dashboard
2. Customer Dashboard

Features include:
- Executive KPI summary
- Interactive filters (date, country, product)
- Trend and contribution analysis
- Customer cohort and retention insights

Dashboard and screenshots are available in the `/dashboard` folder.

---

## Key Insights
- Total revenue reached approximately $8.89M during the analysis period
- Revenue shows an increasing trend toward the end of the year
- Sales are dominated by a few key markets and products
- Returning customers contribute the majority of total revenue
- Early customer cohorts show strong retention over time

---

## Author
**Fairuz Mujahid**  
Data Analyst (1 year experience)

