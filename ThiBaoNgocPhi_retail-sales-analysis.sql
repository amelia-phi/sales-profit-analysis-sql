USE Advancedtest;

-- QUESTION 1:
/* 
Write an SQL query to calculate the total sales for all products belonging to the 'Furniture' product line, 
grouped by quarter and year. Return two columns: Quarter_Year formatted as Q{quarter}-{year} (e.g. Q1-2014), 
and Total_Sales as the rounded total sales for that quarter. Order the results chronologically from the 
earliest to the most recent quarter.
*/

SELECT 
    'Q' + CAST(DATEPART(QUARTER, o.ORDER_DATE) AS VARCHAR) + '-' + CAST(YEAR(o.ORDER_DATE) AS VARCHAR) AS Quarter_Year,
    ROUND(SUM(o.SALES), 2) AS Total_Sales
FROM 
    ORDERS o
JOIN 
    PRODUCT p ON o.PRODUCT_ID = p.ID
WHERE 
    p.NAME = 'Furniture'
GROUP BY 
    YEAR(o.ORDER_DATE), 
    DATEPART(QUARTER, o.ORDER_DATE)
ORDER BY 
    YEAR(o.ORDER_DATE) ASC, 
    DATEPART(QUARTER, o.ORDER_DATE) ASC;
    
    
-- QUESTION 2:
/* 
For each product category, classify orders into four discount tiers: No Discount, Low, Medium, and High. 
For each category/tier combination, calculate the total number of order lines and total profit. 
Order results by category and discount tier.

Discount level tiers:
No Discount = 0%
0% < Low Discount <= 20%
20% < Medium Discount <= 50%
High Discount > 50% 
*/
SELECT 
    p.CATEGORY,
    CASE 
        WHEN o.DISCOUNT = 0 THEN 'No Discount'
        WHEN o.DISCOUNT > 0 AND o.DISCOUNT <= 0.2 THEN 'Low Discount'
        WHEN o.DISCOUNT > 0.2 AND o.DISCOUNT <= 0.5 THEN 'Medium Discount'
        WHEN o.DISCOUNT > 0.5 THEN 'High Discount'
    END AS DISCOUNT_LEVEL,
    COUNT(p.CATEGORY) AS NUMBER_OF_ORDERS,
    ROUND(SUM(o.PROFIT), 2) AS Total_Profit
FROM 
    ORDERS o
JOIN 
    PRODUCT p ON o.PRODUCT_ID = p.ID
GROUP BY 
    p.CATEGORY,
    CASE  
        WHEN o.DISCOUNT = 0 THEN 'No Discount'
        WHEN o.DISCOUNT > 0 AND o.DISCOUNT <= 0.2 THEN 'Low Discount'
        WHEN o.DISCOUNT > 0.2 AND o.DISCOUNT <= 0.5 THEN 'Medium Discount'
        WHEN o.DISCOUNT > 0.5 THEN 'High Discount'
    END
ORDER BY
    CATEGORY ASC, DISCOUNT_LEVEL ASC
;


-- QUESTION 3:
/* 
For each customer segment, aggregate total sales and total profit by product category, then rank the categories
within each segment by total profit (highest to lowest). Return only the top 2 ranked categories per segment, 
including their total sales, total profit, and profit rank.
*/
-- use window function
WITH RankedProfit AS (
    SELECT 
        c.segment,
        p.category,
        ROUND(SUM(o.sales), 2) AS Total_Sales,
        ROUND(SUM(o.profit), 2) AS Total_Profit,
        DENSE_RANK() OVER (
            PARTITION BY c.segment 
            ORDER BY SUM(o.profit) DESC
        ) AS Profit_Rank
    FROM 
        dbo.ORDERS o
    JOIN 
        dbo.CUSTOMER c ON o.customer_id = c.id
    JOIN 
        dbo.PRODUCT p ON o.product_id = p.id
    GROUP BY 
        c.segment, 
        p.category
)
SELECT 
    segment,
    category,
    Total_Sales,
    Total_Profit,
    Profit_Rank
FROM 
    RankedProfit
WHERE 
    Profit_Rank <= 2
ORDER BY 
    segment ASC, 
    Profit_Rank ASC;

-- QUESTION 4
/*
For each employee, calculate the total profit per product category they have sold. Then compute each category's
profit contribution (%) as its share of that employee's overall total profit across all categories. Return the 
employee ID, employee name, category, total profit, and profit contribution percentage. Order the results by 
employee, then by profit contribution percentage from highest to lowest.
*/

WITH EmployeeCategoryProfit AS (
    SELECT 
        e.ID_EMPLOYEE, 
        e.NAME, 
        p.category AS CATEGORY, 
        SUM(o.profit) AS CATEGORY_PROFIT
    FROM 
        employees e
    JOIN 
        orders o ON o.id_employee = e.ID_EMPLOYEE
    JOIN 
        product p ON o.product_id = p.id
    GROUP BY 
        e.ID_EMPLOYEE, 
        e.NAME, 
        p.category
)
SELECT 
    ID_EMPLOYEE,
    NAME,
    CATEGORY,
    ROUND(CATEGORY_PROFIT, 2) AS CATEGORY_PROFIT,
    -- Calculate the % contribution
    ROUND(
        (CATEGORY_PROFIT / SUM(CATEGORY_PROFIT) OVER(PARTITION BY ID_EMPLOYEE)) * 100, 
        2
    ) AS PROFIT_CONTRIBUTION
FROM 
    EmployeeCategoryProfit
ORDER BY 
    ID_EMPLOYEE ASC, 
    PROFIT_CONTRIBUTION DESC;

-- QUESTION 5:
/*
Create a scalar user-defined function that takes an employee ID and a product category as inputs and returns 
the profitability ratio, defined as Total Profit / Total Sales for that employee–category combination 
(return NULL if total sales is zero or NULL). Then use this function in a report query that returns 
each employee's ID, name, product category, total sales, total profit, and the computed profitability ratio. 
Order results by employee, then by profitability ratio from highest to lowest.
*/
GO
CREATE OR ALTER FUNCTION dbo.fn_GetProfitabilityRatio (
    @EmployeeID INT,
    @Category NVARCHAR(255)
)
RETURNS DECIMAL(18, 4)
AS
BEGIN
    DECLARE @TotalSales DECIMAL(18, 2);
    DECLARE @TotalProfit DECIMAL(18, 2);
    DECLARE @Ratio DECIMAL(18, 4);

    -- 1. Get the totals for this specific combo
    SELECT 
        @TotalSales = SUM(o.sales),
        @TotalProfit = SUM(o.profit)
    FROM ORDERS o
    JOIN PRODUCT p ON o.product_id = p.id
    WHERE o.id_employee = @EmployeeID 
      AND p.category = @Category;

    -- 2. Apply the "Safety Switch" for Zero/NULL Sales
    IF @TotalSales IS NULL OR @TotalSales = 0
    BEGIN
        SET @Ratio = NULL;
    END
    ELSE
    BEGIN
        -- Cast to FLOAT to ensure we get decimal precision
        SET @Ratio = CAST(@TotalProfit AS FLOAT) / CAST(@TotalSales AS FLOAT);
    END

    RETURN @Ratio;
END;
GO
------------------------------------------
SELECT 
    e.ID_EMPLOYEE,
    e.NAME,
    p.category AS PRODUCT_CATEGORY,
    ROUND(SUM(o.sales), 2) AS TOTAL_SALES,
    ROUND(SUM(o.profit), 2) AS TOTAL_PROFIT,
    dbo.fn_GetProfitabilityRatio(e.ID_EMPLOYEE, p.category) AS PROFITABILITY_RATIO
FROM 
    EMPLOYEES e
JOIN 
    ORDERS o ON e.ID_EMPLOYEE = o.id_employee
JOIN 
    PRODUCT p ON o.product_id = p.id
GROUP BY 
    e.ID_EMPLOYEE, 
    e.NAME, 
    p.category
ORDER BY 
    e.ID_EMPLOYEE ASC, 
    PROFITABILITY_RATIO DESC;


-- QUESTION 6:
/* 
Create a stored procedure that accepts EMPLOYEE_ID, StartDate, and EndDate as parameters and returns a single 
row containing the employee's ID, name, total sales, and total profit for all orders placed within the given 
date range (inclusive on both ends). If no orders exist for that employee in the specified range, the procedure
should return no rows.
Test with: 
EXEC GetEmployeeSalesProfit @EmployeeID = 3, @StartDate = '2016-12-01', @EndDate = '2016-12-31';
*/
GO 

CREATE OR ALTER PROCEDURE GetEmployeeSalesProfit
    @EmployeeID INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SELECT 
        e.ID_EMPLOYEE,
        e.NAME,
        ROUND(SUM(o.sales), 2) AS TOTAL_SALES,
        ROUND(SUM(o.profit), 2) AS TOTAL_PROFIT
    FROM 
        dbo.employees e
    INNER JOIN 
        dbo.orders o ON e.ID_EMPLOYEE = o.id_employee
    WHERE 
        e.ID_EMPLOYEE = @EmployeeID
        AND o.order_date >= @StartDate 
        AND o.order_date <= @EndDate
    GROUP BY 
        e.ID_EMPLOYEE, 
        e.NAME;
END;
GO
--------
EXEC GetEmployeeSalesProfit 
    @EmployeeID = 3, 
    @StartDate = '2016-12-01', 
    @EndDate = '2016-12-31';



-- QUESTION 7:
/*
Write a stored procedure using dynamic SQL that pivots total profit by the last 6 quarters found in the dataset,
with one row per state. The procedure should:
-	Automatically detect the 6 most recent quarters from the ORDERS table
-	Output one column per quarter, named in the format Q{quarter}-{year} (e.g. Q4-2017), ordered from most 
recent to oldest left to right
-	Output one row per customer STATE, showing the rounded total profit for each quarter (NULL if no orders 
existed for that state in that quarter)
-	Order rows alphabetically by state
The procedure must remain correct if new quarterly data is added in the future.
*/
GO
CREATE OR ALTER PROCEDURE GetQuarterlyProfitPivot
AS
BEGIN
    DECLARE @Columns NVARCHAR(MAX);
    DECLARE @DynamicSQL NVARCHAR(MAX);

    -- Automatically detect the 6 most recent quarters
    SELECT @Columns = STRING_AGG(QUOTENAME(QuarterLabel), ',') 
    WITHIN GROUP (ORDER BY MaxDate DESC)
    FROM (
        SELECT TOP 6 
            'Q' + CAST(DATEPART(QUARTER, order_date) AS VARCHAR) + '-' + CAST(DATEPART(YEAR, order_date) AS VARCHAR) AS QuarterLabel,
            MAX(order_date) AS MaxDate
        FROM dbo.ORDERS
        GROUP BY DATEPART(YEAR, order_date), DATEPART(QUARTER, order_date)
        ORDER BY MaxDate DESC
    ) AS RecentQuarters;

    -- Build the Pivot Query with the JOIN
    -- Join ORDERS (o) and CUSTOMER (c) to get both the Profit and the State
    SET @DynamicSQL = N'
    SELECT State, ' + @Columns + '
    FROM (
        SELECT 
            c.state, 
            ''Q'' + CAST(DATEPART(QUARTER, o.order_date) AS VARCHAR) + ''-'' + CAST(DATEPART(YEAR, o.order_date) AS VARCHAR) AS QuarterLabel,
            ROUND(o.profit, 2) AS Profit
        FROM dbo.ORDERS o
        INNER JOIN dbo.CUSTOMER c ON o.customer_id = c.id -- Linking the tables here
    ) AS SourceTable
    PIVOT (
        SUM(Profit)
        FOR QuarterLabel IN (' + @Columns + ')
    ) AS PivotTable
    ORDER BY State ASC;';


-- Execute
    EXEC sp_executesql @DynamicSQL;
END;
GO

-- Run and see results:
EXEC GetQuarterlyProfitPivot;