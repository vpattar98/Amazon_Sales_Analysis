SELECT * FROM amazondb.amazon;

SELECT Branch from amazondb.amazon;

# Renaming the Table Name  
ALTER TABLE amazondb.amazon RENAME TO amazon;

SELECT * FROM amazon;
SELECT DATABASE();

SHOW COLUMNS FROM amazon;

SELECT * 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'amazon';

             ### Changing the Column names and Datatypes ###
ALTER TABLE amazon 
CHANGE COLUMN `Invoice ID` Invoice_Id VARCHAR(30);

ALTER TABLE amazon
MODIFY COLUMN Invoice_Id VARCHAR(30);

ALTER TABLE amazon 
CHANGE COLUMN `Branch` branch VARCHAR(5),
CHANGE COLUMN `City` city VARCHAR(30),
CHANGE COLUMN `Customer type` customer_type VARCHAR(30),
CHANGE COLUMN `Gender` gender VARCHAR(10),
CHANGE COLUMN `Product line` Product_line VARCHAR(100);

ALTER TABLE amazon
CHANGE COLUMN `Unit price` Unit_price DECIMAL(10,2);

ALTER TABLE amazon
CHANGE COLUMN `Tax 5%` Tax_5_percent FLOAT(6,4),
CHANGE COLUMN `Total` total DECIMAL(10,2),
CHANGE COLUMN `Date` date Date,
CHANGE COLUMN `cogs` Cogs DECIMAL(10,2),
CHANGE COLUMN `gross margin percentage` gross_margin_percentage FLOAT(11,9),
CHANGE COLUMN `gross income` gross_income DECIMAL(10,2),
CHANGE COLUMN `Payment` Payment VARCHAR(20);

ALTER TABLE amazon
MODIFY COLUMN `Time` TIMESTAMP;

            ### PRODUCT ANALYSIS ###

/* TO CHECK DISTINCT Product_lines */
SELECT DISTINCT Product_line FROM amazon;

/* the Products_lines PERFORMING BEST */
SELECT Product_line, SUM(total) AS Total_sales
FROM amazon
GROUP BY Product_line
ORDER BY Total_sales DESC; 

/* AVERAGE Rating FOR EACH Product_line */
SELECT Product_line, ROUND(AVG(Rating),2) AS avg_rating
FROM amazon
GROUP BY  Product_line
ORDER BY avg_rating DESC;


           ####  SALES ANALYSIS ###

SELECT month_name ,SUM(Total)  AS month_wise_sales
FROM amazon
GROUP BY month_name
ORDER BY month_wise_sales DESC ;


SELECT day_name ,SUM(Total)  AS day_wise_sales
FROM amazon
GROUP BY day_name
ORDER BY day_wise_sales DESC ;


                ##### CUSTOMER ANALYSIS #######
 
/* Number of customers by customer type */
 SELECT Customer_type, COUNT(DISTINCT Invoice_ID) AS num_customers
FROM Amazon
GROUP BY Customer_type;

/*Total revenue by gender  */
SELECT gender, SUM(total) as total_revenue
FROM amazon
GROUP BY gender
ORDER BY total_revenue DESC;

/*Number of customers by city and product line */
SELECT city, Product_line, COUNT(DISTINCT Invoice_Id) AS num_customers
FROM amazon
GROUP BY city, Product_line;

/* profitability of each customer segment */
SELECT customer_type, SUM(total - Cogs) AS Profit
FROM amazon
GROUP BY customer_type;


                 #### DATA WRANGLING ####
               
#   This is the first step where inspection of data is done to make sure NULL values and
#   missing values are detected and data replacement methods are used to replace missing or NULL values.

SELECT * FROM amazon WHERE COALESCE(Invoice_Id,branch,city,customer_type,gender,Product_line,Unit_price,Quantity,Tax_5_percent,
total,date,Time,Payment,Cogs,gross_margin_percentage,gross_income,Rating) IS NULL;


           ##### FEATURE ENGINEERING #####
 #-- This will help us generate some new columns from existing ones.

/* Add a new column named "timeofday" to give insight of sales in the Morning, Afternoon and Evening. 
This will help answer the question on which part of the day most sales are made. */

ALTER TABLE amazon
ADD COLUMN time_of_day varchar(25);

SET sql_safe_updates=0;

UPDATE amazon
SET time_of_day = CASE
                    WHEN HOUR(Time) < 12 THEN 'Morning'
                    WHEN HOUR(Time) < 17 THEN 'Afternoon'
                    ELSE 'Evening'
               END;

/* Add a new column named "dayname" that contains the extracted days of the week on which the given transaction took place (Mon, Tue, Wed, Thur, Fri). 
This will help answer the question on which week of the day each branch is busiest.*/

ALTER TABLE amazon
ADD COLUMN day_name VARCHAR(25);

UPDATE amazon
SET day_name=DAYNAME(date);

/*Add a new column named monthname that contains the extracted months of the year on which the given transaction took place (Jan, Feb, Mar). 
Help determine which month of the year has the most sales and profit. */

ALTER TABLE amazon
ADD COLUMN month_name VARCHAR(25);

UPDATE amazon
SET month_name=MONTHNAME(date);

         ####Exploratory Data Analysis (EDA) ####
-- Exploratory data analysis is done to answer the listed questions and aims of this project. 

    ####  Business Questions To Answer ####

# 1) What is the count of distinct cities in the dataset?
SELECT COUNT(DISTINCT(city)) as count_of_distinct_city FROM amazon;

# 2) For each branch, what is the corresponding city?
SELECT DISTINCT branch , city from amazon;

# 3) What is the count of distinct product lines in the dataset?
SELECT COUNT(DISTINCT(Product_line)) AS count_of_distinct_productlines FROM amazon;

# 4) Which payment method occur most frequently?
SELECT payment, COUNT(payment) AS frequency
FROM amazon
GROUP BY payment
ORDER BY frequency DESC
LIMIT 1;


# 5) Which product line has the highest sales?
SELECT * FROM amazon;	
SELECT Product_line , SUM(Total) as highest_sales
FROM amazon
GROUP BY Product_line
ORDER BY highest_sales DESC
LIMIT 1;

# 6) How much revenue is generated each month?
SELECT month_name , SUM(total) AS revenue
FROM amazon
GROUP BY month_name
ORDER BY revenue;

# 7) In which month did the cost of goods sold reach its peak?
SELECT Cogs,month_name
FROM amazon
WHERE Cogs = (SELECT MAX(Cogs) FROM amazon);


# 8) Which product line generated the highest revenue?
SELECT Product_line ,SUM(Total) AS highest_revenue
FROM amazon
GROUP BY Product_line
ORDER BY highest_revenue DESC
LIMIT 1;

#9) In which city was the highest revenue recorded?
SELECT city,SUM(total) AS highest_revenue
FROM amazon
GROUP BY city
ORDER BY highest_revenue DESC
LIMIT 1;

# 10) Which Product line incurred the highest Value Added Tax?
SELECT Product_line , SUM(Tax_5_percent) AS high_added_tax
FROM amazon
GROUP BY Product_line
ORDER BY high_added_tax DESC
LIMIT 1;

# 11) For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."

 SELECT AVG(total) AS avg_total FROM amazon;

SELECT Product_line,
       (CASE 
           WHEN SUM(total) >(SELECT  AVG(total) FROM amazon)  THEN 'Good'
           ELSE 'Bad'
       END) AS Sales_Above_Average
FROM amazon
GROUP BY Product_line;

# 12) Identify the branch that exceeded the average number of products sold.
SELECT branch ,SUM(Quantity) AS quantity
FROM amazon
GROUP BY branch
HAVING SUM(Quantity) > (SELECT AVG(Quantity) FROM amazon)
ORDER BY quantity DESC
LIMIT 1 ;

# 13) Which product line is most frequently associated with each gender?  ---------CORRECT THIS ONE
/*SELECT gender, Product_line, COUNT(*) AS Frequency
FROM amazon
GROUP BY gender, Product_line
ORDER BY gender, Frequency DESC; */

WITH Productline_gender AS (
SELECT gender,Product_line,
ROW_NUMBER() OVER (PARTITION BY gender ORDER BY COUNT(*) DESC) AS row_num
FROM amazon 
GROUP BY gender,Product_line
)
SELECT gender , Product_line
FROM Productline_gender
WHERE row_num =1;

# 14) Calculate the average rating for each product line
SELECT Product_line, ROUND(AVG(Rating),2) AS avg_rating
FROM amazon
GROUP BY Product_line
ORDER BY avg_rating DESC ;

# 15) Count the sales occurrences for each time of day on every weekday.
SELECT time_of_day , COUNT(*) AS sales_occurrences
FROM amazon
GROUP BY time_of_day
ORDER BY sales_occurrences DESC;

# 16)Identify the customer type contributing the highest revenue.
SELECT customer_type,SUM(total) as highest_revenue
FROM amazon
GROUP BY customer_type
ORDER BY highest_revenue DESC ;

# 17) Determine the city with the highest VAT percentage.
SELECT CITY,SUM(TAX_5_PERCENT)/SUM(TOTAL) *100 AS VAT
FROM amazon
GROUP BY CITY
ORDER BY VAT DESC
LIMIT 1;

# 18) Identify the customer type with the highest VAT payments.
SELECT customer_type , SUM(Tax_5_percent) AS highest_vat_payments
FROM amazon
GROUP BY customer_type 
ORDER BY highest_vat_payments DESC
LIMIT 1;

# 19) What is the count of distinct customer types in the dataset?
SELECT COUNT(DISTINCT(customer_type)) AS count_distinct_customertype FROM amazon;

# 20) What is the count of distinct payment methods in the dataset?
SELECT COUNT(DISTINCT(Payment)) AS count_distinct_payments FROM amazon;

# 21) Which customer type occurs most frequently?
SELECT customer_type , COUNT(*) AS freq
FROM amazon
GROUP BY customer_type
ORDER BY freq DESC
LIMIT 1;

# 22) Identify the customer type with the highest purchase frequency.
SELECT customer_type , COUNT(*) highest_purchase_freq
FROM amazon
GROUP BY customer_type
ORDER BY highest_purchase_freq DESC
LIMIT 1;

# 23) Determine the predominant gender among customers.
SELECT gender ,COUNT(*) AS freq
FROM amazon
GROUP BY gender
ORDER BY freq DESC
LIMIT 1;

# 24) Examine the distribution of genders within each branch.
SELECT gender, branch, COUNT(*) AS gender_count
FROM amazon
GROUP BY gender,branch;

# 25) Identify the time of day when customers provide the most ratings.
SELECT time_of_day, Rating, COUNT(*) AS rating_count
FROM amazon
GROUP BY time_of_day,Rating
ORDER BY rating_count DESC;

# 26) Determine the time of day with the highest customer ratings for each branch.
SELECT time_of_day , branch ,AVG(Rating) as highest_rating
FROM amazon
GROUP BY time_of_day , branch
ORDER BY branch, highest_rating DESC
LIMIT 1;

# 27) Identify the day of the week with the highest average ratings.
SELECT day_name , AVG(Rating) AS highest_avg_rating
FROM amazon
GROUP BY day_name
ORDER BY highest_avg_rating DESC
LIMIT 1; 

# 28) Determine the day of the week with the highest average ratings for each branch.
SELECT day_name, branch, AVG(Rating) AS highest_avg_rating
FROM amazon
GROUP BY day_name,branch
ORDER BY highest_avg_rating DESC
LIMIT 1; 

