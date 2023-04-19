                                               
											   ----- A Comprehensive Analysis of Sales and Inventory Data for Maven Toys in Mexico -----
																 
															  /* Skills Used : Aggregate Functions, 
													                           Case Statements, 
																	           Joins, 
																	           Sub Queries, 
																	           CTE's, 
																	           Indexes, 
																	           Views, 
																	           Procedures,
																	           Window Functions,
																			   In-Built Functions,
																			   Clauses like : DISTINCT
																				              WHERE
																				              GROUP BY 
																				              ORDER BY 
																						      OFFSET 
																							  FETCH  */
													 
-- Creating Indexes on the Foreign Key Columns:

    CREATE INDEX store_id_Index 
	ON dbo.inventory(Store_ID,Product_ID);

	CREATE INDEX sales_Index
	ON dbo.sales(Store_ID,Product_ID);

-- Products Available in Store :

    SELECT DISTINCT(Product_Name) AS Product_Name
    FROM dbo.products;

						
-- Number of Units of Each Product were Sold in Each Store : 

	WITH CTE AS     (SELECT Product_Name,Store_Name,SUM(Units) AS No_of_products_sold 
                     FROM dbo.products AS Product 
					 INNER JOIN dbo.sales AS Sales
	                 ON Product.Product_ID = Sales.Product_ID 
	                 INNER JOIN dbo.stores AS Store
	                 ON Store.Store_ID  = Sales.Store_ID
					 GROUP BY Product_Name, Store_Name
				    )                    
    SELECT *
	FROM CTE
	ORDER  BY No_of_products_sold DESC,
		      Product_Name ASC;


-- Most Popular Product in Each Store [Based on No of Purchases]:

    WITH CTE2 AS     (SELECT Product_Name,Store_Name,SUM(Units) AS No_of_products_sold 
                      FROM dbo.products AS Product 
					  INNER JOIN dbo.sales AS Sales
	                  ON Product.Product_ID = Sales.Product_ID 
	                  INNER JOIN dbo.stores AS Store
	                  ON Store.Store_ID  = Sales.Store_ID
					  GROUP BY Product_Name, Store_Name
				     ),                   
         
		 CTE3 AS     (SELECT *,DENSE_RANK() OVER(PARTITION BY Store_Name ORDER BY No_of_products_sold DESC) AS DR 
 	                  FROM CTE2
					 )
	 
	 SELECT Store_Name, Product_Name 
	 FROM CTE3
	 WHERE DR=1
	 ORDER BY Store_Name;
			                     
    
-- Products Which Generated Highest Revenue in Each store :
    
	 SELECT  Product_Name, Store_Name, [Revenue $] 
	 FROM (SELECT* 
	       FROM (SELECT*, RANK() OVER(PARTITION BY Store_Name ORDER BY [Revenue $]DESC) AS RanK_
	             FROM (SELECT Product_Name,Store_Name,SUM([Revenue $]) AS [Revenue $] 
	                   FROM (SELECT Product_Name,Store_Name, (Product.Product_Price * sales.Units) - Product.Product_Cost AS [Revenue $]
                             FROM dbo.products AS Product 
			                 INNER JOIN dbo.sales AS Sales
	                         ON Product.Product_ID = Sales.Product_ID 
	                         INNER JOIN dbo.stores AS Store
	                         ON Store.Store_ID  = Sales.Store_ID
		                    ) AS Last_Query
		               GROUP BY Product_Name, Store_Name
		              ) AS Inner_Query
		        ) AS Penultimate_Query
	       ) AS Outer_Query
	  WHERE Rank_ =1
	  ORDER BY Product_Name ASC, 
	           [Revenue $] DESC; 


-- Products Which are Unsold :
     
	  SELECT Product_Name 
	  FROM dbo.products AS P LEFT JOIN dbo.sales AS S 
	  ON P.Product_ID = S.Product_ID
	  WHERE Sale_ID IS NULL; 
	  

-- Top Selling Product by Year and Location: 

    CREATE PROCEDURE Top_product_procedure (@Year INT) 
	AS 
	BEGIN
      WITH CTE4 AS (SELECT Product_Name,Store_Location,DATEPART(Year,[DATE]) AS [Year],(P.Product_Price * s.Units) - P.Product_Cost AS [Revenue $]
	               FROM products AS P INNER JOIN sales AS S 
	               ON P.Product_ID = S.Product_ID
	               INNER JOIN stores AS store 
	               ON store.Store_ID = S.Store_ID
				  ),
		   CTE5 AS (SELECT Product_Name,Store_Location,[Year],SUM([Revenue $]) AS [Revenue $]
		            FROM CTE4
					GROUP BY Product_Name,Store_Location,[Year]
		           ) 
	  
	  
	   
	       SELECT*,FIRST_VALUE(Product_Name) OVER(PARTITION BY Store_Location ORDER BY [Revenue $] DESC) AS [Top Product]
	       FROM CTE5 
	       WHERE [Year] = @Year 
	END 

	EXECUTE Top_product_procedure '2017';
	EXECUTE Top_product_procedure '2018';


-- AVG Cost of Product in each category :
    
	SELECT Product_Category, ROUND(AVG(Product_Price),2) AS [Avg Price of product in $]
	FROM products 
	GROUP BY Product_Category;


-- Year-Wise Product Revenue Comparision : 

    SELECT Product_Name,[Year], SUM([Revenue $]) AS [Revenue $]
	FROM (SELECT Product_Name,DATEPART(Year,[DATE]) AS [Year],(P.Product_Price * s.Units) - P.Product_Cost AS [Revenue $]
	      FROM products AS P INNER JOIN sales AS S 
	      ON P.Product_ID = S.Product_ID
	      INNER JOIN stores AS store 
	      ON store.Store_ID = S.Store_ID
		 )AS Inner_Query 
	GROUP BY Product_Name, [Year]
	ORDER BY Product_Name ASC;


-- Quarterly Revenue Generated by the Products, Year Wise : 
    
	WITH CTE6 AS (SELECT Product_Name, (products.Product_Price * sales.Units) - Products.Product_Cost AS [Revenue $],DATEPART(Year,[Date]) AS [Year],
	                    CASE 
	                        WHEN DATEPART(month,[Date]) <=3 THEN '1st Quarter'
		                    WHEN DATEPART(month,[Date]) >3 AND DATEPART(month,[Date]) <=6 THEN '2nd Quarter'
		                    WHEN DATEPART(month,[Date]) >6 AND DATEPART(month,[Date]) <=8 THEN '3rd Quarter'
		                    ELSE '4th Quarter'
		                END AS [Quarter]
	            FROM products INNER JOIN sales 
	            ON products.product_id = sales.product_id)
	 
	 select Product_Name,SUM([Revenue $]) AS [Revenue $],[Year],[Quarter] 
	 FROM CTE6
	 GROUP BY Product_Name, [Year],[Quarter]
	 ORDER BY Product_Name ASC,
	          [Year] ASC,
			  [Quarter] ASC;
			  

-- Comapring Revenue of the Categories by Year and Location :

     CREATE PROCEDURE Popular_Category_Procedure (@Year INT) 
	 AS 
	 BEGIN 
	      SELECT Product_Category,Store_Location,[Year],SUM([Revenue $]) AS [Revenue $]
		  FROM (SELECT Product_Category, Store_Location,DATEPART(Year,[DATE]) AS [Year], (products.Product_Price * sales.Units) - Products.Product_Cost AS [Revenue $]
		        FROM products INNER JOIN sales 
		        ON products.Product_ID = sales.Product_ID 
		        INNER JOIN stores AS S 
		        ON sales.Store_ID = S.Store_ID
			   ) AS Inner_Query
		  WHERE [Year] = @Year 
		  GROUP BY Product_Category,Store_Location,[Year]
		  ORDER BY Product_Category ASC,
		           [Revenue $] DESC;
 	 END 

	 EXECUTE Popular_Category_Procedure '2017';
	 EXECUTE Popular_Category_Procedure '2018';


-- Highest Revenue Generated Product in Each Category [2017-2018] :

    WITH CTE7 AS (SELECT Product_Name, Product_Category, SUM([Revenue $]) AS [Revenue $]
	              FROM (SELECT Product_Name, Product_Category,(products.Product_Price * sales.Units) - Products.Product_Cost AS [Revenue $]
	                    FROM products INNER JOIN sales 
	                    ON products.Product_ID = sales.Product_ID
		                ) AS Inner_Query
	              GROUP BY Product_Name, Product_Category),

		CTE8 AS  (SELECT*,DENSE_RANK() OVER(PARTITION BY Product_Category ORDER BY [Revenue $] DESC) AS Drank 
		          FROM CTE7
				  )
	SELECT Product_Category, Product_Name, [Revenue $]
	FROM CTE8
	WHERE Drank = 1
	ORDER BY [Revenue $] DESC;


-- Contribution of Each and Every Product In Overall Revenue [2017-2018] :

    WITH CTE9 AS (SELECT Product_Name, SUM([Revenue $]) AS [Revenue $]
	              FROM (SELECT Product_Name,(products.Product_Price * sales.Units) - Products.Product_Cost AS [Revenue $]
	                    FROM products INNER JOIN sales 
	                    ON products.Product_ID = sales.Product_ID
		               ) AS Inner_Query
	              GROUP BY Product_Name
				)
	SELECT Product_Name , ROUND(100.0* [Revenue $]/(SELECT SUM([Revenue $]) FROM CTE9),2) AS [Revenue Contribution in %]
	FROM CTE9
	ORDER BY [Revenue Contribution in %] DESC;


-- Revenue of Top 5 Stores [2017-2018] :

   CREATE VIEW Store_Sales 
   AS
   SELECT Store_Name , SUM([Revenue $]) AS [Revenue $]
   FROM (SELECT Store_Name, (products.Product_Price * sales.Units) - Products.Product_Cost AS [Revenue $]
         FROM products INNER JOIN sales 
         ON products.Product_ID= sales.Product_ID 
         INNER JOIN stores 
         ON stores.Store_ID = sales.Store_ID 
         WHERE DATEPART(Year,[DATE]) = 2017
	    ) AS Inner_Query
	GROUP BY Store_Name;


	SELECT*
	FROM Store_Sales 
	ORDER BY [Revenue $] DESC,
	         Store_Name ASC
	OFFSET 0 ROWS 
	FETCH NEXT 5 ROWS ONLY;


-- Quarterly Performance of the Stores, Year-Wise :

    WITH CTE10 AS (SELECT Store_Name, (products.Product_Price * sales.Units) - Products.Product_Cost AS [Revenue $],DATEPART(Year,[Date]) AS [Year],
	                    CASE 
	                        WHEN DATEPART(month,[Date]) <=3 THEN '1st Quarter'
		                    WHEN DATEPART(month,[Date]) >3 AND DATEPART(month,[Date]) <=6 THEN '2nd Quarter'
		                    WHEN DATEPART(month,[Date]) >6 AND DATEPART(month,[Date]) <=8 THEN '3rd Quarter'
		                    ELSE '4th Quarter'
		                END AS [Quarter]
	               FROM products 
				   INNER JOIN sales 
	               ON products.product_id = sales.product_id
				   INNER JOIN stores
				   ON stores.Store_ID = sales.Store_ID
				  )
	 
	 SELECT Store_Name,SUM([Revenue $]) AS [Revenue $],[Year],[Quarter] 
	 FROM CTE10
	 GROUP BY Store_Name, [Year],[Quarter]
	 ORDER BY Store_Name ASC,
	          [Year] ASC,
			  [Quarter] ASC;

-- Top Performing Stores in Each and Every Location :

    WITH CTE11 AS 
	            (SELECT Store_Name, Store_Location, SUM([Revenue $]) AS [Revenue $]
				 FROM (SELECT Store_Name, Store_Location, (products.Product_Price * sales.Units) - Products.Product_Cost AS [Revenue $] 
				       FROM products INNER JOIN sales 
				       ON products.Product_ID = sales.Product_ID 
				       INNER JOIN stores 
				       ON stores.Store_ID =sales.Store_ID
					  ) AS Innner_Query 
				 GROUP BY Store_Name, Store_Location
				),

		 CTE12 AS (SELECT*,DENSE_RANK() OVER(PARTITION BY Store_Location ORDER BY [Revenue $] DESC) AS Drank 
		           FROM CTE11) 
	SELECT Store_Name, Store_Location,[Revenue $]
	FROM CTE12 
	WHERE Drank=1
	ORDER BY [Revenue $] DESC;


-- Sales Insights Over the Years [2017-2018] :  
    
	SELECT [Year], SUM([Revenue $]) AS [Revenue $]
	FROM (SELECT DATEPART(Year,[Date]) AS [Year], (products.Product_Price * sales.Units) - Products.Product_Cost AS [Revenue $]  
	      FROM products INNER JOIN sales 
	      ON products.Product_ID = sales.Product_ID
		 ) AS Inner_Query
	GROUP BY [Year]
	ORDER BY [Revenue $] DESC;


-- Tracking the Growth : Quarterly Sales Over the Years : 

    SELECT [Year], [Quarter], SUM([Revenue $]) AS [Revenue $]
	FROM (SELECT DATEPART(Year,[Date]) AS [Year],(products.Product_Price * sales.Units) - Products.Product_Cost AS [Revenue $],
	             CASE 
	                 WHEN DATEPART(month,[Date]) <=3 THEN '1st Quarter'
		             WHEN DATEPART(month,[Date]) >3 AND DATEPART(month,[Date]) <=6 THEN '2nd Quarter'
		             WHEN DATEPART(month,[Date]) >6 AND DATEPART(month,[Date]) <=8 THEN '3rd Quarter'
		             ELSE '4th Quarter'
		         END AS [Quarter]
	      FROM products INNER JOIN sales 
	      ON products.Product_ID = sales.Product_ID
		 ) AS Inner_Query

	GROUP BY [Year],[Quarter]
	ORDER BY [Year] ASC,
	         [Quarter]ASC; 
    
   

   



		 




    

    


					  
	               

				

	
   
  