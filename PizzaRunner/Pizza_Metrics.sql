-- A. Pizza Metrics
-- How many pizzas were ordered?
SELECT COUNT(pizza_id)  AS pizza_order_qty
FROM customer_orders


-- How many unique customer orders were made?
SELECT COUNT(distinct customer_id) as num_cus
FROM customer_orders

-- How many successful orders were delivered by each runner?


SELECT Count(distinct order_id) as successful_order_qty
from customer_orders c
where order_id in(
    select order_id
    from runner_orders
    where cancellation is null
)

-- How many of each type of pizza was delivered?
SELECT pizza_id, COUNT(pizza_id) as sold_sty
From customer_orders
where order_id in(
    select order_id
    from runner_orders
    where cancellation is null)
GROUP by pizza_id

-- How many Vegetarian and Meatlovers were ordered by each customer?


SELECT * 
from pizza_names

SELECT c.customer_id, CAST(pn.pizza_name as varchar(max)) as pizza_name, Count(c.pizza_id) as order_qty
from customer_orders c
join pizza_names pn 
on c.pizza_id = pn.pizza_id
GROUP by c.customer_id, CAST(pn.pizza_name as varchar(max))
ORDER by c.customer_id


-- What was the maximum number of pizzas delivered in a single order?

SELECT top 1 order_id,
        COUNT(pizza_id) as pizza_qty
from customer_orders
GROUP by order_id
Order by pizza_qty desc

Select order_id, count(pizza_id) as pizza_qty
from customer_orders
GROUP by order_id
having count(pizza_id) = (
    SELECT top 1 COUNT(pizza_id) as pizza_qty
        from customer_orders
        GROUP by order_id
        Order by pizza_qty desc)


WITH RankedOrders AS (
    SELECT order_id, COUNT(pizza_id) AS pizza_order_qty, RANK() OVER (ORDER BY COUNT(pizza_id) DESC) AS order_rank
    FROM customer_orders
    GROUP BY order_id
)
SELECT order_id, pizza_order_qty
FROM RankedOrders
WHERE order_rank = 1;



-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT *
FROM customer_orders

SELECT customer_id,
        case when exclusions is null and extras is null then COUNT(pizza_id) else 0  end as no_changes,
        case when exclusions is not null or extras is not null then COUNT(pizza_id) else 0 end as changes
from customer_orders
GROUP by customer_id, exclusions, extras


SELECT 
    customer_id,
    SUM(CASE WHEN exclusions IS NULL AND extras IS NULL THEN 1 ELSE 0 END) AS no_changes,
    SUM(CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1 ELSE 0 END) AS changes
FROM customer_orders
GROUP BY customer_id;


-- How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(pizza_id) as sold_sty
From customer_orders
where order_id in(
    select order_id
    from runner_orders
    where cancellation is null) and
    exclusions is not null AND
    extras is not null
GROUP by pizza_id

-- What was the total volume of pizzas ordered for each hour of the day? NOT EACH DAY
SELECT *
FROM customer_orders


-- WITH Numbers AS (
--     SELECT 0 AS hour
--     UNION ALL
--     SELECT hour + 1
--     FROM Numbers
--     WHERE hour < 24
-- ),
-- a as (
-- SELECT DISTINCT
--     Datepart(MONTH, order_time) AS Month,
--     datepart(day, order_time) AS Day,
--     Numbers.hour as Hour
-- FROM
--     customer_orders
-- CROSS JOIN
--     Numbers

-- )

-- SELECT a.[Month], a.[Day], a.[Hour],
--         Sum(case when DATEPART(MONTH,c.order_time) = a.Month and
--                 DATEPART(DAY,c.order_time) = a.Day and
--                 DATEPART(HOUR,c.order_time) = a.HOUR 
--                 then 1 else 0 end
--          ) as pizza_order_qty
-- from a
-- cross join customer_orders c
-- group by a.[Month], a.[Day], a.[Hour]


SELECT 
    DATEPART(HOUR, order_time) AS Hour,
    COUNT(pizza_id) AS Pizza_Volume
FROM 
    customer_orders
GROUP BY 
    DATEPART(HOUR, order_time)
ORDER BY 
    DATEPART(HOUR, order_time);



-- What was the volume of orders for each day of the week?

SELECT 
    DATEPART(WEEKDAY, order_time) AS Weekday,
    COUNT(*) AS Order_Count
FROM 
    customer_orders
GROUP BY 
    DATEPART(WEEKDAY, order_time)
ORDER BY 
    DATEPART(WEEKDAY, order_time);