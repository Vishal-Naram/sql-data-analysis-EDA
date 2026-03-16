/*
=================================================
Database Exploration and Exploratory Data Analysis
=================================================
Purpose:
    1. These scripts explore the metadata, structure of the database, including all the tables and columns.
    2. Followed by the Exploratory Data Analysis (EDA) like:
1) Dimension Exploration: Identifying the unique values in each dimension and recognizing how date might be grouped as segmented, which is useful for later analysis.
2) Date Exploration: Identifying the earliest and latest dates (boundaries) and understand the scope of data and the timespan.
3) Measures Exploration: Calculate the key metric of the business (big numbers), Highest level of Aggregation/Lowerst level of Details.
4) Magnitude Analysis: Compare the measure values by categories. It helps us understand the importance of different categories.
5) Ranking: Order the values of dimensions by measure. Top N performers | Bottom N performers.

*/

/*
Exploratory Data Analysis
Database Exploration */

-- Explore All Ojbects in the Database
SELECT * FROM INFORMATION_SCHEMA.TABLES

-- Explore All Columns in the Database
SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers'

-- Dimensions Exploration

-- Explore All Countries our customers come from

SELECT DISTINCT country FROM gold.dim_customers

-- Explore All Categories "The major Divisions"
SELECT DISTINCT category, subcategory, product_name FROM gold.dim_products
ORDER BY 1,2,3

-- Date Exploration
-- Find the date of the first and last order
SELECT MIN(order_date) first_order_date,
	   MAX(order_date) last_order_date
FROM gold.fact_sales

-- How many years of sales are available
SELECT DATEDIFF(year, MIN(order_date), MAX(order_date)) AS order_range_years
FROM gold.fact_sales

-- Find the youngest and oldest customer
SELECT MIN(birthdate) AS oldest_customer,
	   DATEDIFF(year, MIN(birthdate), GETDATE()) AS oldest_age,
	   MAX(birthdate) AS youngest_customer,
	   DATEDIFF(year, MAX(birthdate), GETDATE()) AS youngest_age
FROM gold.dim_customers

-- Measures Exploration

-- Find the Total Sales
SELECT SUM(sales_amount) AS total_sales FROM gold.fact_sales

-- Find how many items are sold
SELECT SUM(quantity) AS total_quantity
FROM gold.fact_sales

-- Find the average selling price
SELECT AVG(price) AS average_price FROM gold.fact_sales

-- Find the Total number of Orders
SELECT COUNT(order_number) AS total_orders FROM gold.fact_sales
SELECT COUNT(DISTINCT(order_number)) AS total_orders FROM gold.fact_sales

-- Find the Total number of Products
SELECT COUNT(product_key) AS total_products FROM gold.dim_products
SELECT COUNT(DISTINCT(product_key)) AS total_products FROM gold.dim_products

-- Find the Total number of Customers
SELECT COUNT(customer_key) AS total_customers FROM gold.dim_customers

-- Find the Total number of customers that has placed an order
SELECT COUNT(DISTINCT(customer_key)) AS customers FROM gold.fact_sales

-- Generate a Report that shows all key metrics of the business
SELECT 'Total Sales' as measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT  'Average Price', AVG(price) AS average_price FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Order', COUNT(DISTINCT order_number) AS total_orders FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Products', COUNT(product_key) AS total_products FROM gold.dim_products
UNION ALL
SELECT 'Total Nr. Customers', COUNT(customer_key) AS total_customers FROM gold.dim_customers


-- Magnitude Analysis

-- Find total customers by countries
SELECT 
country,
COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC

-- Find total customers by gender
SELECT 
gender,
COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC

-- Find total products by category
SELECT
category, 
COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC

-- What is the average costs in each category?
SELECT
category,
AVG(cost) AS avg_costs
FROM gold.dim_products
GROUP BY category
ORDER BY avg_costs DESC

-- What is the total revenue generated for each catergory?
SELECT
p.category,
SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC

-- Find total revenue is generted by each customer?
SELECT
c.customer_key,
c.first_name,
c.last_name,
SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY
c.customer_key,
c.first_name,
c.last_name
ORDER BY total_revenue DESC

-- What is the distribution of sold items across countries?
SELECT
c.country,
SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY
c.country
ORDER BY total_sold_items DESC

-- Ranking Analysis

-- Which 5 products generated the highest revenue?
SELECT TOP 5
p.subcategory,
SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.subcategory
ORDER BY total_revenue DESC

SELECT *
FROM(
	SELECT
	p.product_name,
	SUM(f.sales_amount) AS total_revenue,
	ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_products
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
	GROUP BY p.product_name)t
WHERE rank_products <= 5

-- What are the 5 worst-performing products in terms of sales?
SELECT TOP 5
p.product_name,
SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue

-- Find teh top 10 customers who have generated the highest revenue
SELECT TOP 10
c.customer_key,
c.first_name,
c.last_name,
SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY
c.customer_key,
c.first_name,
c.last_name
ORDER BY total_revenue DESC

-- The 3 customers with the fewest orders placed
SELECT TOP 3
c.customer_key,
c.first_name,
c.last_name,
COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY
c.customer_key,
c.first_name,
c.last_name
ORDER BY total_orders 
