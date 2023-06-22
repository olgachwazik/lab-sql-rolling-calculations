-- 1. Get number of monthly active customers.

-- Getting the table with customer_id and rental_date split into Month and Year columns (will be used as a CTE):

select customer_id, convert(rental_date, date) as Activity_date,
	date_format(convert(rental_date, date), '%m') as Activity_Month, 
    date_format(convert(rental_date, date), '%Y') as Activity_Month
from sakila.rental;

-- FINAL: using the above table as a CTE to display the amount of active customers (by active I understand a customer who rented at least 1 movie during the month) per month:

with cte_active_customers as (
	select customer_id, convert(rental_date, date) as Activity_date,
		date_format(convert(rental_date, date), '%m') as Activity_Month, 
		date_format(convert(rental_date, date), '%Y') as Activity_Year
	from sakila.rental
)
select Activity_Year, Activity_Month, count(distinct customer_id) as Active_customers
from cte_active_customers
group by Activity_Year, Activity_Month;

-- 2. Active users in the previous month.

-- I'm using the query from the 1st question as CTE, then selecting same information with the lag:
with cte_active_customers as (
	select customer_id, convert(rental_date, date) as Activity_date,
		date_format(convert(rental_date, date), '%m') as Activity_Month, 
		date_format(convert(rental_date, date), '%Y') as Activity_Year
	from sakila.rental
), cte_rentals_count as (
	select Activity_Year, Activity_Month, count(distinct customer_id) as Active_customers
	from cte_active_customers
	group by Activity_Year, Activity_Month
)
select Activity_year, Activity_month, Active_customers, 
   lag(Active_customers) over (order by Activity_Year, Activity_Month) as Previous_month
from cte_rentals_count;

-- 3. Percentage change in the number of active customers.

-- using the query from above plus adding a column calculating percentage change:

with cte_active_customers as (
	select customer_id, convert(rental_date, date) as Activity_date,
		date_format(convert(rental_date, date), '%m') as Activity_Month, 
		date_format(convert(rental_date, date), '%Y') as Activity_Year
	from sakila.rental
), cte_rentals_count as (
	select Activity_Year, Activity_Month, count(distinct customer_id) as Active_customers
	from cte_active_customers
	group by Activity_Year, Activity_Month
), cte_rentals_prev_month as (
	select Activity_year, Activity_month, Active_customers, 
	lag(Active_customers) over (order by Activity_Year, Activity_Month) as Previous_month
	from cte_rentals_count
)
select *,
	(Active_customers - Previous_month) as Difference,
    concat(round((Active_customers - Previous_month)/Active_customers*100), "%") as Percent_Difference
from cte_rentals_prev_month;

-- 4. Retained customers every month.

-- based on the query from previous questions, I'm displaying active customers for each month
with cte_active_customers as (
	select customer_id, convert(rental_date, date) as Activity_date,
		date_format(convert(rental_date, date), '%m') as Activity_Month, 
		date_format(convert(rental_date, date), '%Y') as Activity_Year
	from sakila.rental
)
select distinct 
	customer_id as Active_id, 
	Activity_Year, 
	Activity_Month
from cte_active_customers
order by Active_id, Activity_Year, Activity_Month;

-- FINAL: self join to display customer_id of clients that rented a movie in a given month and also in a previous month. 

with cte_active_customers as (
	select customer_id, convert(rental_date, date) as Activity_date,
		date_format(convert(rental_date, date), '%m') as Activity_Month, 
		date_format(convert(rental_date, date), '%Y') as Activity_Year
	from sakila.rental
), cte_retained_customers as (
	select distinct 
		customer_id as Active_id, 
		Activity_Year, 
		Activity_Month
	from cte_active_customers
	order by Active_id, Activity_Year, Activity_Month
)
select rc1.Active_id, rc1.Activity_year, rc1.Activity_month, rc2.Activity_month as Previous_month
from cte_retained_customers rc1
join cte_retained_customers rc2
on rc1.Activity_year = rc2.Activity_year 
and rc1.Activity_month = rc2.Activity_month+1
and rc1.Active_id = rc2.Active_id 
order by rc1.Active_id, rc1.Activity_year, rc1.Activity_month;
