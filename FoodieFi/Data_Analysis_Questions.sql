-- A. Data Analysis Questions
-- How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id)
FROM subscriptions

-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT top 10 *
FROM subscriptions


SELECT  YEAR(start_date) year,
        MONTH(start_date) as month,
        COUNT(customer_id) num_cus
from subscriptions
group by YEAR(start_date), MONTH(start_date)
ORDER by YEAR(start_date), MONTH(start_date)



-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

SELECT s.start_date, p.plan_name, count(s.customer_id) num_cus 
from subscriptions s
join plans p on s.plan_id =p.plan_id
where start_date = (
    SELECT MIN(start_date)
    from subscriptions
    where YEAR(start_date) > 2020) 
group by s.start_date, p.plan_name


-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT  Sum(case when plan_id = 4 then 1 else 0  end) as churn_qty,
        ROUND(cast(Sum(case when plan_id = 4 then 1 else 0  end)*100.0/ count(distinct customer_id) as float), 1) as churn_percentage
from subscriptions

-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
SELECT  customer_id,
        start_date,
        plan_id,
        lead(plan_id) over(PARTITION by customer_id order by start_date) next_plan
into #temp_nextplan
from subscriptions





SELECT  Sum(case when plan_id = 0 and next_plan = 4 then 1 else 0 end) num_cus_churn,
        Sum(case when plan_id = 0 and next_plan = 4 then 1 else 0 end) * 100/count(distinct customer_id) as num_cus_churn_percentage
from #temp_nextplan



-- What is the number and percentage of customer plans after their initial free trial?

SELECT  Sum(case when plan_id = 0 and next_plan = 1 then 1 else 0 end) as basic_monthly,
        Sum(case when plan_id = 0 and next_plan = 1 then 1 else 0 end)*100/Sum(case when plan_id = 0 then 1 else 0 end) as basic_monthly_per,
        Sum(case when plan_id = 0 and next_plan = 2 then 1 else 0 end) as pro_monthl,
        Sum(case when plan_id = 0 and next_plan = 2 then 1 else 0 end)*100/Sum(case when plan_id = 0 then 1 else 0 end) as pro_monthl_per,
        Sum(case when plan_id = 0 and next_plan = 3 then 1 else 0 end) as pro_annual,
        Sum(case when plan_id = 0 and next_plan = 3 then 1 else 0 end)*100/Sum(case when plan_id = 0 then 1 else 0 end) as pro_annual_per
from #temp_nextplan


-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

SELECT *
from subscriptions
where start_date = '2020-12-31 00:00:00.0000000'


-- How many customers have upgraded to an annual plan in 2020?
SELECT  Sum(case when next_plan = 3 then 1 else 0 end) as pro_annual
from #temp_nextplan
where year(start_date) = 2020

-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
SELECT *
from #temp_nextplan;

With A as (
        SELECT customer_id,
            start_date as entry_day
        from subscriptions
        where plan_id = 0),
    B as (
        SELECT customer_id,
                start_date as annual_day
        from subscriptions
        where plan_id = 3)

SELECT AVG(DATEDIFF(DAY, A.entry_day, B.annual_day)) Avg_day_to_annual
from A 
INNER join B on A.customer_id = B.customer_id;


-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
-- max day = 346
With A as (
        SELECT customer_id,
            start_date as entry_day
        from subscriptions
        where plan_id = 0),
    B as (
        SELECT customer_id,
                start_date as annual_day
        from subscriptions
        where plan_id = 3)

SELECT  Sum(Case when DATEDIFF(DAY, A.entry_day, B.annual_day) < 31 then 1 else 0 end) as  '0-30_days',
        Sum(Case when DATEDIFF(DAY, A.entry_day, B.annual_day) >31 and DATEDIFF(DAY, A.entry_day, B.annual_day) < 60  then 1 else 0 end) as  '31-60_days',
        Sum(Case when DATEDIFF(DAY, A.entry_day, B.annual_day) >61 and DATEDIFF(DAY, A.entry_day, B.annual_day) < 90  then 1 else 0 end) as  '61-90_days',
        Sum(Case when DATEDIFF(DAY, A.entry_day, B.annual_day) >91 and DATEDIFF(DAY, A.entry_day, B.annual_day) < 120  then 1 else 0 end) as  '91-120_days',
        Sum(Case when DATEDIFF(DAY, A.entry_day, B.annual_day) >121 and DATEDIFF(DAY, A.entry_day, B.annual_day) < 150  then 1 else 0 end) as  '121-150_days',
        Sum(Case when DATEDIFF(DAY, A.entry_day, B.annual_day) >151 and DATEDIFF(DAY, A.entry_day, B.annual_day) < 180  then 1 else 0 end) as  '151-180_days', 
        Sum(Case when DATEDIFF(DAY, A.entry_day, B.annual_day) >181 and DATEDIFF(DAY, A.entry_day, B.annual_day) < 210  then 1 else 0 end) as  '181-210_days', 
        Sum(Case when DATEDIFF(DAY, A.entry_day, B.annual_day) >211 and DATEDIFF(DAY, A.entry_day, B.annual_day) < 240  then 1 else 0 end) as  '211-240_days', 
        Sum(Case when DATEDIFF(DAY, A.entry_day, B.annual_day) >241 and DATEDIFF(DAY, A.entry_day, B.annual_day) < 270  then 1 else 0 end) as  '241-270_days', 
        Sum(Case when DATEDIFF(DAY, A.entry_day, B.annual_day) >271 and DATEDIFF(DAY, A.entry_day, B.annual_day) < 300  then 1 else 0 end) as  '271-300_days', 
        Sum(Case when DATEDIFF(DAY, A.entry_day, B.annual_day) >301 and DATEDIFF(DAY, A.entry_day, B.annual_day) < 330  then 1 else 0 end) as  '301-330_days', 
        Sum(Case when DATEDIFF(DAY, A.entry_day, B.annual_day) >331  then 1 else 0 end) as  '>331days'
from A 
INNER join B on A.customer_id = B.customer_id




-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
SELECT *
from #temp_nextplan;


SELECT count(distinct customer_id) as "customers downgraded from a pro monthly to a basic monthly plan in 2020"
from #temp_nextplan
where YEAR(start_date) = 2020 and plan_id = 2 and next_plan = 1