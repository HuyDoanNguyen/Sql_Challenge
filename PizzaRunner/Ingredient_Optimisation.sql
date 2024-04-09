-- C. Ingredient Optimisation
-- What are the standard ingredients for each pizza?

--------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Tạo bảng tạm thời chứa mỗi topping trong một hàng
DROP TABLE IF EXISTS #temp_toppings;
SELECT 
    pizza_id,
    Trim(value) as value
INTO 
    #temp_toppings
FROM 
    pizza_recipes
CROSS APPLY 
    STRING_SPLIT(toppings, ',');
    

SELECT * from #temp_toppings

-- UPDATE #temp_toppings
-- SET topping_name = 
--     CASE 
--         WHEN topping_name LIKE ' %' THEN CAST(REPLACE(topping_name, ' ', '') AS FLOAT)
--         ELSE CAST(topping_name as float)
--     END
-- WHERE topping_name IS NOT NULL;

SELECT pn.pizza_name, pt.topping_name
from #temp_toppings tt
join pizza_toppings pt on pt.topping_id = tt.topping_name
join pizza_names pn on pn.pizza_id = tt.pizza_id
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
 SELECT		
   p.pizza_id,
   TRIM(t.value) AS topping_id,
   pt.topping_name
 INTO #cleaned_toppings
 FROM 
     pizza_recipes as p
     CROSS APPLY string_split(p.toppings, ',') as t
     JOIN pizza_toppings as pt
     ON TRIM(t.value) = pt.topping_id 

SELECT *
from #cleaned_toppings



--------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- What was the most commonly added extra?

SELECT * from #temp_extras

DROP TABLE IF EXISTS #temp_extras;
SELECT 
    pizza_id,
    Trim(value) AS topping_extras
INTO 
    #temp_extras
FROM 
    customer_orders
CROSS APPLY 
    STRING_SPLIT(extras, ',');
    
-- UPDATE #temp_extras
-- SET topping_extras = 
--     CASE 
--         WHEN topping_extras LIKE ' %' THEN CAST(REPLACE(topping_extras, ' ', '') AS FLOAT)
--         ELSE CAST(topping_extras as float)
--     END
-- WHERE topping_extras IS NOT NULL;

SELECT pn.pizza_name, pt.topping_name
from #temp_extras tx
join pizza_toppings pt on pt.topping_id = tx.topping_extras
join pizza_names pn on pn.pizza_id = tx.pizza_id

SELECT * from customer_orders

-- What was the most common exclusion?
DROP TABLE IF EXISTS #temp_exclusion;
SELECT 
    pizza_id,
    TRim(value) AS topping_exclusion
INTO 
    #temp_exclusion
FROM 
    customer_orders
CROSS APPLY 
    STRING_SPLIT(exclusions, ',');
    
-- UPDATE #temp_exclusion
-- SET topping_exclusion = 
--     CASE 
--         WHEN topping_exclusion LIKE ' %' THEN CAST(REPLACE(topping_exclusion, ' ', '') AS FLOAT)
--         ELSE CAST(topping_exclusion as float)
--     END
-- WHERE topping_exclusion IS NOT NULL;

SELECT pn.pizza_name, pt.topping_name as topping_exclusion
from #temp_exclusion tx
join pizza_toppings pt on pt.topping_id = tx.topping_exclusion
join pizza_names pn on pn.pizza_id = tx.pizza_id



-- Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers




--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
    order_id,
    customer_id,
    pizza_id,
    CASE
        WHEN exclusions = 'null' THEN null
        ELSE exclusions
    END as exclusions,
    CASE
        WHEN extras = 'null' THEN null
        ELSE extras
    END as extras,
    order_time
INTO #cleaned_customer_orders
FROM customer_orders;

SELECT		
   p.pizza_id,
   TRIM(t.value) AS topping_id,
   pt.topping_name
INTO #cleaned_toppings
FROM 
     pizza_recipes as p
     CROSS APPLY string_split(p.toppings, ',') as t
     JOIN pizza_toppings as pt
     ON TRIM(t.value) = pt.topping_id 
;

ALTER TABLE #cleaned_customer_orders
ADD record_id INT IDENTITY(1,1);


-- to generate extra table
SELECT		
	c.record_id,
	TRIM(e.value) AS topping_id
INTO #extras
FROM 
	#cleaned_customer_orders as c
	CROSS APPLY string_split(c.extras, ',') as e
;

select * from #e
-- to generate exclusions table
SELECT		
	c.record_id,
	TRIM(e.value) AS topping_id
INTO #exclusions
FROM 
	#cleaned_customer_orders as c
	CROSS APPLY string_split(c.exclusions, ',') as e
;
-- Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

WITH extras_cte AS
(
	SELECT 
		record_id,
		'Extra ' + STRING_AGG(t.topping_name, ', ') as record_options
	FROM
		#extras e,
		pizza_toppings t
	WHERE e.topping_id = t.topping_id
	GROUP BY record_id
),
exclusions_cte AS
(
	SELECT 
		record_id,
		'Exclude ' + STRING_AGG(t.topping_name, ', ') as record_options
	FROM
		#exclusions e,
		pizza_toppings t
	WHERE e.topping_id = t.topping_id
	GROUP BY record_id
),
union_cte AS
(
	SELECT * FROM extras_cte
	UNION
	SELECT * FROM exclusions_cte
)

SELECT 
	c.record_id,
	CONCAT_WS(' - ', p.pizza_name, STRING_AGG(cte.record_options, ' - '))
FROM 
	#cleaned_customer_orders c
	JOIN pizza_names p
	ON c.pizza_id = p.pizza_id
	LEFT JOIN union_cte cte
	ON c.record_id = cte.record_id
GROUP BY
	c.record_id,
	p.pizza_name
ORDER BY 1;



