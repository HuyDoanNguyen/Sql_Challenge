-- C. Challenge Payment Question
-- The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
    -- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
    -- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
    -- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
    -- once a customer churns they will no longer make payments


SELECT  s.customer_id,
        s.start_date,
        s.plan_id,
        lead(s.plan_id) over(PARTITION by s.customer_id order by start_date) next_plan
into #temp_payment
from subscriptions s
join plans p
on s.plan_id = p.plan_id




SELECT * from plans

SELECT top 10 * from subscriptions


SELECT  s.customer_id,
        s.plan_id,
        p.plan_name,
        s.start_date as payment_date,
        p.price as amount,
        COUNT(s.plan_id) over(PARTITION by s.customer_id) payment_order
FROM 
    subscriptions s
JOIN 
    plans p on s.plan_id = p.plan_id
where 
    s.plan_id not in (0,4)




--Insert payments data into payments_2020 table
WITH join_table AS --create base table
(
	SELECT 
	        s.customer_id,
		s.plan_id,
		p.plan_name,
		s.start_date AS payment_date,
		s.start_date,
		LEAD(s.start_date, 1) OVER(PARTITION BY s.customer_id ORDER BY s.start_date, s.plan_id) AS next_date,
		p.price AS amount
	FROM subscriptions s
	LEFT JOIN plans p 
	ON p.plan_id = s.plan_id
),

new_join AS --filter table (deselect trial and churn)
(
	SELECT 
		customer_id,
		plan_id,
		plan_name,
		payment_date,
		start_date,
		CASE WHEN next_date IS NULL or next_date > '20201231' THEN '20201231' ELSE next_date END next_date,
		amount
	FROM join_table
	WHERE plan_name NOT IN ('trial', 'churn')
),

new_join1 AS --add new column, 1 month before next_date
(
	SELECT 
		customer_id,
		plan_id,
		plan_name,
		payment_date,
		start_date,
		next_date,
		DATEADD(MONTH, -1, next_date) AS next_date1,
		amount
	FROM new_join
),

Date_CTE  AS --recursive function (for payment_date)
(
	SELECT 
		customer_id,
		plan_id,
		plan_name,
		start_Date,
		payment_date = (select top 1 start_Date FROM new_join1 where customer_id = a.customer_id and plan_id = a.plan_id),
		next_date, 
		next_date1,
		amount
	FROM new_join1 a

	UNION ALL 
    
	SELECT 
		customer_id,
		plan_id,
		plan_name,
		start_Date, 
		DATEADD(M, 1, payment_date) AS payment_date,
		next_date, 
		next_date1,
		amount
	FROM Date_CTE b
	WHERE payment_date < next_date1 AND plan_id != 3
)

-- INSERT INTO payments_2020 (customer_id, plan_id, plan_name, payment_date, amount, payment_order)
SELECT 
	customer_id,
	plan_id,
	plan_name,
	payment_date,
	amount,
	RANK() OVER(PARTITION BY customer_id ORDER BY customer_id, plan_id, payment_date) AS payment_order
FROM Date_CTE
WHERE YEAR(payment_date) = 2020
ORDER BY customer_id, plan_id, payment_date;