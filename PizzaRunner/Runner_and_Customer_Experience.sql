-- B. Runner and Customer Experience
-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT  COUNT(runner_id) as new_runner,
        DATEPART(WEEK, registration_date) as week
from runners
GROUP by DATEPART(WEEK, registration_date)


-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT ro.runner_id, avg(DATEDIFF(MINUTE, co.order_time, ro.pickup_time))  avg_mins_diff
from runner_orders ro
JOIN customer_orders co 
On ro.order_id = co.order_id
where ro.pickup_time is not null
group by ro.runner_id

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?

SELECT  distinct ro.order_id, 
        Count(co.pizza_id) num_pizza,
        DATEDIFF(MINUTE, co.order_time, ro.pickup_time) mins_diff,
        DATEDIFF(MINUTE, co.order_time, ro.pickup_time)/Count(co.pizza_id) as avg_mins_per_pizza
from runner_orders ro
JOIN customer_orders co 
On ro.order_id = co.order_id
where ro.pickup_time is not null
group by ro.order_id, co.order_time, ro.pickup_time



-- What was the average distance travelled for each customer?


SELECT  co.customer_id,
        AVG(CAST(ro.distance as float)) as avg_distance_km
from customer_orders co
join runner_orders ro
on co.order_id = ro.order_id
where ro.cancellation is NULL
group by co.customer_id;


-- What was the difference between the longest and shortest delivery times for all orders?

WITH a AS (
    SELECT  
        distinct co.order_id,
        DATEDIFF(SECOND, co.order_time, ro.pickup_time) AS sec_deli,
        RANK() OVER (ORDER BY DATEDIFF(SECOND, co.order_time, ro.pickup_time) DESC) AS deli_rank_longest
    FROM 
        customer_orders co
    JOIN 
        runner_orders ro ON co.order_id = ro.order_id
    WHERE 
        ro.cancellation IS NULL
)
SELECT  
    co.order_id, 
    co.customer_id,
    ro.runner_id,
    COUNT(co.pizza_id) AS pizza_count,
    ro.distance,
    ro.duration,
    a.deli_rank_longest
FROM 
    customer_orders co
JOIN 
    runner_orders ro ON co.order_id = ro.order_id
JOIN 
    a ON a.order_id = co.order_id
WHERE 
    a.deli_rank_longest IN (SELECT MAX(deli_rank_longest) FROM a)
    OR a.deli_rank_longest IN (SELECT MIN(deli_rank_longest) FROM a)
GROUP BY 
    co.order_id, 
    co.customer_id,
    ro.runner_id,
    ro.distance,
    ro.duration,
    a.deli_rank_longest;

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?


SELECT  order_id,
        runner_id,
        CAST(distance as float)*60/CAST(duration as float) as speed_km_h
from runner_orders
where cancellation is NULL

-- What is the successful delivery percentage for each runner?

SELECT runner_id,
        COUNT(runner_id) total_order,
        Sum(case when cancellation is null then 1 end) successful,
        Sum(case when cancellation is not null then 1 else 0 end) fail,
        Sum(case when cancellation is null then 1 end)*100/ COUNT(runner_id) successful_delivery_percentage
from runner_orders
group by runner_id
