# Retail Sales Profit Analysis — SQL

## Overview
A self-directed SQL project analysing a retail sales dataset (~9,994 orders) across customers, products, and employees. The project demonstrates advanced SQL skills including aggregations, window functions, CTEs, user-defined functions, stored procedures, and dynamic pivot tables.

---

## Dataset
| File | Description | Records |
|------|-------------|---------|
| `ORDERS.csv` | Sales transactions with revenue, profit, discount | 9,994 |
| `CUSTOMER.csv` | Customer segments, regions, states | 793 |
| `PRODUCT.csv` | Product categories and subcategories | 1,862 |
| `EMPLOYEES.csv` | Employee details and regions | 10 |

---

## Questions Answered

| # | Question | Key Technique |
|---|----------|---------------|
| 1 | Total sales for Furniture product line by quarter and year | `DATEPART`, `GROUP BY`, aggregation |
| 2 | Classify orders into discount tiers per product category | `CASE WHEN`, conditional aggregation |
| 3 | Top 2 most profitable product categories per customer segment | Window function (`DENSE_RANK`, `PARTITION BY`), CTE |
| 4 | Profit contribution (%) per category per employee | Window function (`SUM OVER`), CTE |
| 5 | Profitability ratio (Profit/Sales) per employee-category combination | Scalar user-defined function |
| 6 | Employee sales and profit report within a date range | Stored procedure with parameters |
| 7 | Dynamic pivot of total profit by state across the last 6 quarters | Dynamic SQL, `PIVOT`, `STRING_AGG` |

---

## Skills Demonstrated
- Aggregations and grouping (`SUM`, `COUNT`, `ROUND`, `GROUP BY`)
- Conditional logic (`CASE WHEN`)
- Common Table Expressions (`WITH`)
- Window functions (`DENSE_RANK`, `PARTITION BY`, `SUM OVER`)
- Scalar user-defined functions
- Stored procedures with input parameters
- Dynamic SQL with `PIVOT`

---

## Tools
- **SQL Server (T-SQL)**
- **Microsoft SQL Server Management Studio (SSMS)**
