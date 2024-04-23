-- Question 2ai

--Select the columns(product id, product name and to get the num_times_in_successful_orders we count the id column in the products table, this is to get the total number of items in the product table)
select p.id as product_id,
	   p.name as product_name,
	   count(p.id) as num_times_in_successful_orders
from
--Join all 5 tables together because not all tables are directly connected to each other.
		alt_school.products p
inner join alt_school.line_items li on p.id = li.item_id
inner join alt_school.orders o on li.order_id = o.order_id
inner join alt_school.customers c on o.customer_id = c.customer_id
inner join alt_school.events e on e.customer_id = c.customer_id
--Use the where clause to filter to get the total orders that were successful 
where o.status = 'success'
and e.event_data ->> 'event_type' = 'add_to_cart'
group by p.id
order by num_times_in_successful_orders desc
limit 1


--Question 2aii

--select the stated columns which is the customer_id, location and total_sepnd columns(the get the total_spend column, multiply the price column from the product table with the item id column in the events table, the item_id column has the varchar data type, so we convert it an integer)
select c.customer_id as customer_id,
	   c.location as location,
	   sum(p.price * (e.event_data ->> 'item_id')::BIGINT) as "total_spend"
--join all the tables 
from alt_school.customers c 
inner join alt_school.events e on c.customer_id = e.customer_id
inner join alt_school.products p on (e.event_data ->> 'item_id')::int = p.id
group by 1, 2
order by total_spend desc
limit 5


--Question 2bi

--Define a CTE called `Event`. select the columns below from the `alt_school.events` table. extract data from a JSON column named `event_data` and casts them to appropriate data types.
with Event as (
select 
	event_id
	,customer_id
	,(event_data ->> 'item_id')::bigint as "item_id",
	(event_data->> 'quantity')::bigint as "quantity"
	,event_data->> 'timestamp' as "timestamp"
	,event_data->> 'event_type' as "event_type"
	,event_timestamp
from alt_school.events
)
--count the number of checkouts  and assign a rank to each location based on the number of checkout events grouping by the location 
cte as (
select 
	location
	,count(Event.event_type) as checkout_count
	,dense_rank() over(order by count(Event.event_type) desc) as rank	
---joining the needed tables
from Event
inner join alt_school.customers as c		on c.customer_id=Event.customer_id
inner join alt_school.orders as o			on o.customer_id=c.customer_id
--adding the filter to get the successful checkouts
where event_type = 'add_to_cart' and status = 'success'
group by location
)
--here in the main query, select the location and check_out count from the cte above and orders the results by the rank
select 
	location
	,checkout_count
from cte
order by rank;

--Question 2bii

--Define a CTE called `Event`. select the columns below from the `alt_school.events` table. extract data from a JSON column named `event_data` and casts them to appropriate data types.
with Event as (
select	
	event_id
	,customer_id
	,(event_data ->> 'item_id')::bigint as "item_id",
	(event_data->> 'quantity')::bigint as "quantity"
	,event_data->> 'timestamp' as "timestamp"
	,event_data->> 'event_type' as "event_type"
	,event_timestamp
from alt_school.events
)
--here in the main query we select the stated columns and filter, we exclude rows where the event_type is either visit or checkout and where status is cancelled, these will give us the customers who abandoned their cart and then count the number of events that occured after the abandonement.
select 
	o.customer_id
	,count(event_type) as num_events	
from alt_school.orders as o
inner join Event on Event.customer_id=o.customer_id
where (event_type <> 'visit' and event_type <> 'checkout') and status = 'cancelled'
group by o.customer_id
order by 2 desc;


--Question 2biii

--Define a CTE called `Event`. select the columns below from the `alt_school.events` table. extract data from a JSON column named `event_data` and casts them to appropriate data types.
with Event as (
select 
	event_id
	,customer_id
	,(event_data ->> 'item_id')::bigint as "item_id",
	(event_data->> 'quantity')::bigint as "quantity"
	,event_data->> 'timestamp' as "timestamp"
	,event_data->> 'event_type' as "event_type"
	,event_timestamp
from alt_school.events 
)
--Define another CTE named visit. It calculates the total visit count for each customer based on different statuses (cancelled, failed, success). The sum(case ... end) expression counts visits with those conditions. It groups the data by customer_id and status.
,visit as (
select 
	o.customer_id
	,sum(case 
		when event_type = 'visit' and status = 'cancelled' then 1
		when event_type = 'visit' and status = 'failed' then 1
		when event_type = 'visit' and status = 'success' then 1
		else 0
	end) as visit_count
	,status
from alt_school.orders as o
inner join Eventon Event.customer_id=o.customer_id
group by o.customer_id,status	
)
--Select the average visit count across all customers. It calculates the average of `visit_count` from the `visit` CTE. The `cast` function converts the result to a decimal with precision 10 and scale 2.
select 
	cast(avg(visit_count) as decimal (10,2)) as average_visits
from visit;