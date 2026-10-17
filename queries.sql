-- Project 2: analysis queries for cafe_sales.db
-- Each query answers one business question. Export results to Excel / Google Sheets for charts.

-- Q1. Total revenue, orders and average order value
SELECT ROUND(SUM(oi.quantity * oi.unit_price), 2)            AS total_revenue,
       COUNT(DISTINCT o.order_id)                            AS total_orders,
       ROUND(SUM(oi.quantity * oi.unit_price) * 1.0
             / COUNT(DISTINCT o.order_id), 2)                AS avg_order_value
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id;

-- Q2. Monthly revenue trend (line chart)
SELECT strftime('%Y-%m', o.ordered_at)                       AS month,
       ROUND(SUM(oi.quantity * oi.unit_price), 2)            AS revenue,
       COUNT(DISTINCT o.order_id)                            AS orders
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY month
ORDER BY month;

-- Q3. Top 10 products by revenue (bar chart)
SELECT p.name, c.name AS category,
       SUM(oi.quantity)                                      AS units_sold,
       ROUND(SUM(oi.quantity * oi.unit_price), 2)            AS revenue
FROM order_items oi
JOIN products p   ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
GROUP BY p.product_id
ORDER BY revenue DESC
LIMIT 10;

-- Q4. Profit by category: which categories earn the most margin? (column chart)
SELECT c.name AS category,
       ROUND(SUM(oi.quantity * oi.unit_price), 2)                         AS revenue,
       ROUND(SUM(oi.quantity * (oi.unit_price - p.unit_cost)), 2)         AS profit,
       ROUND(100.0 * SUM(oi.quantity * (oi.unit_price - p.unit_cost))
             / SUM(oi.quantity * oi.unit_price), 1)                       AS margin_pct
FROM order_items oi
JOIN products p   ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
GROUP BY c.category_id
ORDER BY profit DESC;

-- Q5. Peak hours: when is the cafe busiest? (column chart)
SELECT CAST(strftime('%H', ordered_at) AS INTEGER)           AS hour_of_day,
       COUNT(*)                                              AS orders
FROM orders
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- Q6. Sales by day of week (0 = Sunday)
SELECT CASE strftime('%w', o.ordered_at)
         WHEN '1' THEN 'Mon' WHEN '2' THEN 'Tue' WHEN '3' THEN 'Wed'
         WHEN '4' THEN 'Thu' WHEN '5' THEN 'Fri' WHEN '6' THEN 'Sat' END AS weekday,
       ROUND(SUM(oi.quantity * oi.unit_price), 2)            AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY strftime('%w', o.ordered_at)
ORDER BY strftime('%w', o.ordered_at);

-- Q7. Payment method share (pie or bar chart)
SELECT pm.name AS payment_method,
       COUNT(*)                                              AS orders,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 1) AS share_pct
FROM orders o
JOIN payment_methods pm ON pm.payment_id = o.payment_id
GROUP BY pm.payment_id
ORDER BY orders DESC;

-- Q8. Spending by customer type
SELECT cu.customer_type,
       COUNT(DISTINCT cu.customer_id)                        AS customers,
       ROUND(SUM(oi.quantity * oi.unit_price), 2)            AS revenue,
       ROUND(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT cu.customer_id), 2) AS revenue_per_customer
FROM customers cu
JOIN orders o       ON o.customer_id = cu.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY cu.customer_type
ORDER BY revenue DESC;

-- Q9. Top 10 customers (loyalty program candidates)
SELECT cu.full_name, cu.customer_type,
       COUNT(DISTINCT o.order_id)                            AS orders,
       ROUND(SUM(oi.quantity * oi.unit_price), 2)            AS total_spent
FROM customers cu
JOIN orders o       ON o.customer_id = cu.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY cu.customer_id
ORDER BY total_spent DESC
LIMIT 10;

-- Q10. Products that are frequently bought together (top pairs)
SELECT a.name AS product_a, b.name AS product_b, COUNT(*) AS times_together
FROM order_items x
JOIN order_items y ON y.order_id = x.order_id AND x.product_id < y.product_id
JOIN products a ON a.product_id = x.product_id
JOIN products b ON b.product_id = y.product_id
GROUP BY x.product_id, y.product_id
ORDER BY times_together DESC
LIMIT 10;

-- Q11. Products with no sales in the last 30 days of data (menu review)
SELECT p.name
FROM products p
WHERE p.product_id NOT IN (
    SELECT oi.product_id
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.ordered_at >= date((SELECT MAX(ordered_at) FROM orders), '-30 days')
);
