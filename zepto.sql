create database zepto;
use zepto;

-- What is the total sales revenue by day?

SELECT 
    DATE(orders.orderdatetime) AS sales_date,
    SUM(products.priceperunit * orders.quantity) AS sales
FROM
    orders
        JOIN
    products USING (productid)
GROUP BY DATE(orders.orderdatetime)
ORDER BY DATE(orders.orderdatetime);

-- What is the total sales revenue by dayname?

SELECT 
    DAYNAME(orders.orderdatetime) AS sales_date,
    SUM(products.priceperunit * orders.quantity) AS sales
FROM
    orders
        JOIN
    products USING (productid)
GROUP BY DAYOFWEEK(orders.orderdatetime) , DAYNAME(orders.orderdatetime)
ORDER BY DAYOFWEEK(orders.orderdatetime) , DAYNAME(orders.orderdatetime);

SELECT 
    MONTHNAME(orders.orderdatetime) AS sales_date,
    SUM(products.priceperunit * orders.quantity) AS sales
FROM
    orders
        JOIN
    products USING (productid)
GROUP BY MONTH(orders.orderdatetime) , MONTHNAME(orders.orderdatetime)
ORDER BY MONTH(orders.orderdatetime) , MONTHNAME(orders.orderdatetime);

-- Which top 5 product categories generate the highest revenue?

SELECT 
    products.category,
    SUM(products.priceperunit * orders.quantity) AS revenue
FROM
    orders
        JOIN
    products USING (productid)
GROUP BY products.category
ORDER BY revenue DESC LIMIT 5;

-- Which brands are most popular in terms and revenue?

SELECT 
    products.brand,
    SUM(orders.quantity) AS total_qty_sold,
    SUM(products.priceperunit * orders.quantity) AS revenue
FROM
    orders
        JOIN
    products USING (productid)
GROUP BY products.brand
ORDER BY revenue DESC LIMIT 5;

-- What are the top 10 best-selling products?

SELECT 
    products.productname, SUM(orders.quantity) AS total_qty_sold
FROM
    orders
        JOIN
    products USING (productid)
GROUP BY products.productname
ORDER BY total_qty_sold DESC
LIMIT 10;

SELECT 
    p.ProductName,
    SUM(p.PricePerUnit * o.Quantity) AS total_revenue
FROM
    products p
        JOIN
    orders o ON p.ProductID = o.ProductID
GROUP BY p.ProductName
ORDER BY total_revenue DESC
LIMIT 10;

-- Average order value (AOV) per customer, per store, per location.

SELECT orders.CustomerID,
    round(SUM(orders.Quantity * products.PricePerUnit) / COUNT(DISTINCT orders.OrderID),0)AS AOV
FROM orders 
JOIN products using(productid)
GROUP BY orders.CustomerID
ORDER BY AOV DESC;

SELECT orders.CustomerID,
    round(SUM(orders.Quantity * products.PricePerUnit) / COUNT(DISTINCT orders.OrderID),0)AS AOV
FROM orders 
JOIN products using(productid)
GROUP BY orders.CustomerID
ORDER BY AOV DESC;

SELECT orders.StoreID, dark_warehouses.storename,
    round(SUM(orders.Quantity * products.PricePerUnit) / COUNT(DISTINCT orders.OrderID),0)AS AOV
FROM orders JOIN products using(productid)
join dark_warehouses using(storeid)
GROUP BY orders.StoreID, dark_warehouses.storename
ORDER BY AOV DESC;

SELECT dark_warehouses.location,
    round(SUM(orders.Quantity * products.PricePerUnit) / COUNT(DISTINCT orders.OrderID),0)AS AOV
FROM orders JOIN products using(productid)
join dark_warehouses using(storeid)
GROUP BY dark_warehouses.location
ORDER BY AOV DESC;

-- Revenue contribution by each store/dark warehouse.

SELECT orders.StoreID, dark_warehouses.storename, dark_warehouses.location,
SUM(orders.Quantity * products.PricePerUnit) AS  revenue,
ROUND(SUM(orders.Quantity * products.PricePerUnit) * 100.0 / 
          (SELECT SUM(orders.Quantity * products.PricePerUnit) 
           FROM orders JOIN products using(productid)), 2) AS revenue_percentage
FROM orders JOIN products using(productid)
join dark_warehouses using(storeid)
GROUP BY orders.StoreID, dark_warehouses.storename, dark_warehouses.location
ORDER BY revenue DESC;

-- Trend of orders by hour of the day (peak order times).

select count(orderid) as total_count, hour(orderdatetime) as order_hours
from orders
group by hour(orderdatetime)
order by total_count desc;

-- How many unique customers placed orders?

select count(distinct customerid) 
from orders;

-- What is the average order frequency per customer?
-- aof = total_order/ unique customer 

select count(orderid) / count(distinct customerid) as aof
from orders;

-- Which customers are high-value (top 10 customers by spending)

select customerid, sum(totalamount) as total
from orders
group by customerid
order by total desc limit 10;

-- What percentage of orders were delivered late (ActualDeliveryTime > ExpectedDeliveryTime)?

select orderid, minute(ExpectedDeliveryTime) as expected, minute(ActualDeliveryTime) as actual,
case
 when (ExpectedDeliveryTime < ActualDeliveryTime) then 'late'
 when (ExpectedDeliveryTime > ActualDeliveryTime) then 'before_time'
 else 'on time'
 end as status
from orders;

select 
round(sum(case when(ActualDeliveryTime > ExpectedDeliveryTime) then 1 else 0 end)
/ count(*) * 100,2) as late_percentage
from orders;

-- Average delivery time per order (difference between PickupTime and DeliveryEndTime).

select 
    round(avg(timestampdiff(minute, PickupTime, DeliveryEndTime)), 2) as avg_delivery_time_minutes
from delivery;

-- What percentage of orders were delivered late (ActualDeliveryTime > ExpectedDeliveryTime)?

SELECT 
    ROUND(SUM(CASE
                WHEN (Pickuptime > DeliveryEndTime) THEN 1
                ELSE 0
            END) / COUNT(*) * 100,
            2) AS latedelivery
FROM
    delivery;

-- second highest price

select max(priceperunit)
from products
where priceperunit < (select max(priceperunit) from products);

select priceperunit p
from products order by p desc;

-- Average delivery distance per store.

select orders.StoreID, dark_warehouses.StoreName, 
round(avg(delivery.DistanceTraveled),2)as avg_dist_travelled
from dark_warehouses join orders using(storeid)
join delivery using(orderId)
group by orders.StoreID, dark_warehouses.StoreName
order by avg_dist_travelled desc;

-- top 5 delivery partners completed the most deliveries?

SELECT 
    deliverypartnername, COUNT(deliveryid) AS total_deliveries
FROM
    delivery
GROUP BY deliverypartnername
ORDER BY total_deliveries DESC
LIMIT 5;

-- On-time delivery percentage by partner and by store.

with a as(select orders.StoreID, delivery.deliverypartnername, dark_warehouses.Location,
case when ExpectedDeliveryTime < ActualDeliveryTime then 'late'
	else 'on time' end as status
from delivery join orders using(orderid)
join dark_warehouses using(storeid))
select StoreID, deliverypartnername, Location, 
round(100 * sum(case when status = 'on time' then 1 else 0 end)/ count(*),2) as ontime_percent
from a
group by StoreID, deliverypartnername, Location
order by ontime_percent desc;

-- Which products are below reorder level (low stock)?

select products.productname, inventory.ReorderLevel, inventory.StockQuantity,
case 
	when inventory.ReorderLevel > inventory.StockQuantity then 'below' 
	else 'above' 
	end as status 
from inventory join products using(productid)
where inventory.ReorderLevel > inventory.StockQuantity;

-- How does inventory vs sales trend look over time?

select date_format(orders.OrderDateTime, '%Y-%m') as months,
sum(orders.TotalAmount) as total_sales,
sum(inventory.StockQuantity) as total_inventory
from orders join inventory
using(storeid)
group by months;

-- cumulative sum of price

select orderid, totalamount, 
sum(totalamount) over (order by orderid) as running_total
from orders; 

select orderid, totalamount, 
round(avg(totalamount) over (order by orderid),1) as running_total
from orders; 

-- Find the total revenue per month using orders (use TotalAmount).

select monthname(orderdatetime) as months, sum(totalamount) as revenue
from orders
group by months;

-- List the top 5 product categories by revenue.

select p.Category, sum(o.totalamount) as revenue
from products p join orders o using(productid)
group by p.Category
order by revenue desc limit 5;

-- Which brands contributed more than 5% of total sales revenue?

select p.brand, sum(o.totalamount) as revenue,
sum(o.TotalAmount) * 100 / (select sum(TotalAmount) from orders) as rev_percent
from products p join orders o using(productid)
group by p.brand
having rev_percent > 5
order by rev_percent desc;

-- Find the average order value (AOV) for each store.
-- total rev/ no of orders placed

select dark_warehouses.storename, 
round(sum(orders.TotalAmount) / count(orders.orderid),2) as aov
from dark_warehouses join orders using(storeid)
group by dark_warehouses.storename
order by aov desc;

-- Which store has the highest sales per square capacity 
-- (TotalRevenue ÷ StoreCapacity)

select dark_warehouses.storename, 
round(sum(orders.totalamount)/dark_warehouses.storecapacity ,2) as sq_capacity
from dark_warehouses join orders  using(storeid)
group by dark_warehouses.storename, dark_warehouses.storecapacity
order by sq_capacity desc limit 1;

-- Show the top 3 performing stores by revenue.

select dw.storeid, dw.storename,
sum(o.totalamount) as revenue
from dark_warehouses dw join orders o using(storeid)
group by dw.storeid, dw.storename
order by revenue desc limit 3;

-- Which location has the highest number of unique customers

select dw.location, count(distinct o.customerid) as unique_customer
from dark_warehouses dw join orders o using(storeid)
group by dw.location
order by unique_customer desc limit 1;

-- Calculate the average delivery duration per partner
-- (DeliveryEndTime - PickupTime)

select deliverypartnername, 
round(avg(timestampdiff(minute, PickupTime, DeliveryEndTime)),2) as avg_duration
from delivery
group by deliverypartnername
order by avg_duration desc;

-- Find the top 3 delivery partners by on-time delivery percentage.

with a as(select d.deliverypartnername,
case
	when (o.ExpectedDeliveryTime < o.ActualDeliveryTime) then 'late'
    else 'ontime' 
    end as status_time
from delivery d join orders o using(orderId))

select deliverypartnername,
round(100 * sum(case when status_time = 'ontime' then 1 else 0 end) / count(*),2) as ontime_percent
from a
group by deliverypartnername
order by ontime_percent desc limit 3;

-- Which store has the longest average delivery distance?

select o.storeid, dw.storename, round(avg(d.DistanceTraveled),2) as longest_avg_deliver
from delivery d join orders o using(orderid)
join dark_warehouses dw using(storeid)
group by o.storeid, dw.storename
order by longest_avg_deliver desc limit 1;

-- List all products that are below reorder level.

select p.productname, i.StockQuantity, i.ReorderLevel, 
(i.ReorderLevel - i.StockQuantity) as shortage_units
from inventory i join products p using(productid)
where i.StockQuantity < i.ReorderLevel
order by shortage_units desc;

-- Which categories need the most frequent restocking (count of low-stock products)?

select p.Category, count(*) as most_frequent_restocking
from inventory i join products p using(productid)
where i.StockQuantity < i.ReorderLevel
group by p.Category
order by most_frequent_restocking desc;

-- Find the total stock quantity available per store.

select dw.storename, sum(i.stockquantity) as total_stock_quantity
from dark_warehouses dw join inventory i using(storeid)
group by dw.storename;

-- What is the return rate per category?
-- (count(returnid) / count(orderid)) *100 

select p.category, count(r.ReturnID) as total_returns, count(o.OrderID) as total_orders,
round((count(r.returnid) / count(o.orderid)*100),2) as return_rate
from products p join orders o using(productid)
left join returns r using(productid, orderid)
group by p.Category
order by return_rate desc;

-- Which store has the highest total refund amount?

select dw.storename, dw.location, sum(r.refundamount) as total_refund
from dark_warehouses dw join returns r using(storeid)
group by dw.StoreName, dw.location
order by total_refund desc;

-- List the top 5 most returned products

select p.productname, count(r.returnid) as total
from products p join returns r using(productid)
group by p.productname
order by total desc limit 5;

-- For each store, show revenue, total orders, average delivery time, and return rate in one query.

select dw.storename, sum(o.totalamount) as revenue, count(o.orderid) as total_orders,
round(avg(timestampdiff(minute, o.ExpectedDeliveryTime, o.ActualDeliveryTime)),2) as avg_deliver_time,
round((count(r.returnid) / count(o.orderid)*100),2) as return_rate
from dark_warehouses dw join orders o using(storeid)
left join returns r using(OrderID)
group by dw.storename
order by revenue desc;

-- Find the correlation between order value and delivery time(are big orders slower?)

select o.orderid, o.totalamount, 
timestampdiff(minute, d.PickupTime, d.DeliveryEndTime) as deliverytime
from orders o join delivery d using(orderid);

-- Which customers placed more than 5 orders but also have the highest return rate?

select o.customerid, count(distinct o.orderid) as order_count, count(r.returnid) as total_returns,
(count(r.returnid) / count(distinct o.orderid)) * 100 as return_rate
from orders o left join returns r using(customerid, orderid)
group by o.customerid
having order_count > 5;

-- Compare sales vs inventory trend per month (are we selling faster than stock is updated?)

select monthname(o.OrderDateTime) as months, 
sum(o.totalamount) as sales, sum(i.stockquantity) as inventory
from orders o join inventory i using(storeid, productid)
group by month(o.OrderDateTime), monthname(o.orderdatetime)
order by month(o.OrderDateTime);

-- Find the top 3 products by revenue in each category

with a as(select p.category, p.ProductName, sum(o.totalamount) as rev,
dense_rank() over(partition by p.category order by sum(o.totalamount) desc) as dnk
from products p join orders o using(productid)
group by p.category, p.ProductName)
select * from a
where dnk <= 3
order by category, rev desc;

-- Rank customers based on their total spending

with a as(select customerid, sum(totalamount) as total_spent
from orders
group by CustomerID)
select customerid, total_spent,
dense_rank() over(order by customerid) as dnk
from a
order by dnk;

-- Calculate running total (cumulative sales) over time

with a as(select date(OrderDateTime) as dates, sum(totalamount) as rev
from orders
group by date(OrderDateTime)
order by date(OrderDateTime))
select dates, rev,
sum(rev) over(order by dates) as running_total 
from a;

-- Calculate running total (cumulative sales) over month

with a as(select OrderDateTime, sum(totalamount) as rev
from orders
group by orderDateTime)
select orderdatetime, rev,
sum(rev) over(partition by month(orderdatetime) order by orderdatetime) as running_total 
from a;









