                                                      ----Standardizing Data for Consistency and Compatibility---- 
                                                                     ---Transforming Data--- 
--Updating Datatype of Each and Every Column

   ALTER TABLE dbo.[sales 2017-2019]
   ALTER COLUMN order_id INT

   ALTER TABLE dbo.[sales 2017-2019]
   ALTER COLUMN revenue FLOAT;

   ALTER TABLE dbo.[sales 2017-2019]
   ALTER COLUMN stock INT;

   ALTER TABLE dbo.[sales 2017-2019]
   ALTER COLUMN sales INT;

   ALTER TABLE dbo.[sales 2017-2019] 
   ALTER COLUMN price FLOAT;

   ALTER TABLE dbo.[sales 2017-2019]
   ALTER COLUMN order_date DATE;

   ALTER TABLE dbo.[sales 2017-2019]
   ALTER COLUMN delivery_date_format1 DATE;

--Alternative way to Update Datatype 
   
   UPDATE dbo.[sales 2017-2019] 
   SET order_date = CONVERT(DATE,order_date)
         
		      --(OR)-- 

   UPDATE dbo.[sales 2017-2019] 
   SET order_date = CAST(order_date AS DATE)


-- Rounding The values :
   UPDATE dbo.[sales 2017-2019] 
   SET revenue = ROUND(revenue,2);
   

---Removing Unwanted and Redundant Columns at a Time
  
   ALTER TABLE dbo.[sales 2017-2019]
   DROP COLUMN column3,order_date_2,promo_type_1,promo_bin_1,promo_type_2,promo_bin_2,promo_discount_2,delivery_date_format2

---Replacing and Trimming the values: 
   UPDATE dbo.[sales 2017-2019] 
   SET sales = TRIM(REPLACE(sales,'sales','')) 

---Renaming Columns:
   EXECUTE sp_rename 'dbo.[sales 2017-2019].delivery_date_format1','delivery_date'


---Removing the Null Values for Improving Data Quality 
   
   DELETE FROM dbo.[sales 2017-2019]
   WHERE order_id IS NULL;

---Replacing Null values with the Mean Value :

 --[Revenue Column]
   UPDATE dbo.[sales 2017-2019] 
   SET revenue = avg_revenue 
   FROM dbo.[sales 2017-2019] AS T INNER JOIN (SELECT product_id, ROUND(AVG(revenue),2) as avg_revenue FROM dbo.[sales 2017-2019] GROUP BY product_id) S 
   ON T.product_id = S.product_id 
   WHERE revenue IS NULL;

 --[Price Column]
   UPDATE dbo.[sales 2017-2019] 
   SET price = avg_price
   FROM dbo.[sales 2017-2019] AS T INNER JOIN (SELECT product_id, ROUND(AVG(price),2) as avg_price FROM dbo.[sales 2017-2019] GROUP BY product_id) S 
   ON T.product_id = S.product_id 
   WHERE price IS NULL;

 --[stock Column]
   UPDATE dbo.[sales 2017-2019]
   SET stock = avg_stock
   FROM dbo.[sales 2017-2019] AS T INNER JOIN (SELECT product_id, ROUND(AVG(stock),2) as avg_stock FROM dbo.[sales 2017-2019] GROUP BY product_id) S 
   ON T.product_id = S.product_id 
   WHERE stock IS NULL;


---Replacing Null Values with the zero:

 --[Revenue Coulmn]
   UPDATE dbo.[sales 2017-2019] 
   SET revenue = 0 
   WHERE revenue IS NULL;

 --[Price Column]
   UPDATE dbo.[sales 2017-2019] 
   SET price = 0 
   WHERE price IS NULL;


 --[Stock Column]
   UPDATE dbo.[sales 2017-2019] 
   SET stock = 0 
   WHERE stock IS NULL;


---Removing Duplicates From the Table Using Window Function
 
 --Using CTE and Row_Number Window Function to Create Partitions 
   WITH CTE AS 
  (
   SELECT*,ROW_NUMBER() 
   OVER(PARTITION BY order_id,product_id,store_id,order_date,sales,revenue,stock,price,delivery_date ORDER BY order_id)AS rn
   FROM  dbo.[sales 2017-2019]
   )

	--Fetching the Rows with the row_number 1.
    SELECT*
	FROM CTE
	WHERE rn=1
	ORDER BY order_id;

---Alternative way to Remove the Duplicates :
   
  --If there is an unique identifier [ID] for each row the we can use this query to remove duplicates
	DELETE FROM dbo.[sales 2017-2019] 
	WHERE ID NOT IN (
	                  SELECT MIN(ID)
                      FROM dbo.[sales 2017-2019]
                      GROUP BY order_id,product_id,store_id,order_date,sales,revenue,stock,price,delivery_date
                      ORDER BY order_id ASC 
					 ) AS Inner_query;

	
---Adding a Constraint to the Column 
    ALTER TABLE dbo.[sales 2017-2019] 
    ADD CONSTRAINT product_id_fk FOREIGN KEY(product_id) REFERENCES dbo.products(product_id);


	

   




   
   
   