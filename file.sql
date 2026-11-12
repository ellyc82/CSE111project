-- ============================================================================
-- CSE 111 - Checkpoint 2 Script
-- Restaurant Management Database
-- Team members: <FILL IN NAMES>
-- Run with:  sqlite3 Checkpoint2-dbase.sqlite3
--            .read Checkpoint2-script.sql
-- ============================================================================
.headers on
.mode column

-- ============================================================================
-- SCHEMA MODIFICATIONS SINCE CHECKPOINT 1
-- None to the base tables or their columns (Customer, Manager, Chef, Waiter,
-- Product, Orders, Payment, Prepares, Contains).
-- This script additionally creates one VIEW (v_order_summary, Q34) and two
-- TRIGGERS (trg_payment_completes_order, trg_order_cascade_delete, Q36-Q37).
-- ============================================================================


-- ############################################################################
-- PART 1: SIMPLE STATEMENTS (Q1 - Q11)
-- ############################################################################

-- Q1: Lists every menu item with its price, most expensive first.
SELECT product_name, price
FROM Product
ORDER BY price DESC;

-- Q2: Finds all pizza items on the menu using pattern matching on the name.
SELECT product_id, product_name, price
FROM Product
WHERE product_name LIKE '%Pizza%';

-- Q3: Shows orders placed on or after November 6, newest first.
SELECT order_id, order_time, order_status
FROM Orders
WHERE order_time >= '2026-11-06'
ORDER BY order_time DESC;

-- Q4: Computes scalar aggregates (count, total, average, min, max) over all payments.
SELECT COUNT(*)                AS num_payments,
       SUM(amount)             AS total_collected,
       ROUND(AVG(amount), 2)   AS avg_payment,
       MIN(amount)             AS smallest_payment,
       MAX(amount)             AS largest_payment
FROM Payment;

-- Q5: Lists the distinct payment methods customers have used.
SELECT DISTINCT method
FROM Payment
ORDER BY method;

-- Q6: Finds mid-priced menu items (between $10 and $20), cheapest first.
SELECT product_name, price
FROM Product
WHERE price BETWEEN 10 AND 20
ORDER BY price ASC, product_name ASC;

-- Q7: Registers a new customer, Frank Ortiz (single-row INSERT).
INSERT INTO Customer (customer_id, name, phone)
VALUES (6, 'Frank Ortiz', '209-555-0206');

-- Q8: Updates Frank Ortiz's phone number after he reports a new one (single-row UPDATE).
UPDATE Customer
SET phone = '209-555-0299'
WHERE customer_id = 6;

-- Q9: Adds a new beverage, Sparkling Water, to the menu (single-row INSERT).
INSERT INTO Product (product_id, product_name, price)
VALUES (22, 'Sparkling Water', 3.50);

-- Q10: Removes Frank Ortiz's account, as if he asked to be deleted (single-row DELETE).
DELETE FROM Customer
WHERE customer_id = 6;

-- Q11: Retrieves the three most recent orders.
SELECT order_id, order_time, order_status, customer_id, waiter_id
FROM Orders
ORDER BY order_time DESC
LIMIT 3;


-- ############################################################################
-- PART 2: INTERMEDIATE STATEMENTS (Q12 - Q22)
-- ############################################################################

-- Q12: Inner-joins Orders with Customer and Waiter to list who ordered and who served each order.
SELECT o.order_id,
       o.order_time,
       c.name AS customer,
       w.name AS waiter,
       o.order_status
FROM Orders o
JOIN Customer c ON o.customer_id = c.customer_id
JOIN Waiter   w ON o.waiter_id   = w.waiter_id
ORDER BY o.order_time;

-- Q13: Joins each chef to the manager they report to.
SELECT ch.name AS chef, ch.specialty, m.name AS manager
FROM Chef ch
JOIN Manager m ON ch.manager_id = m.manager_id
ORDER BY m.name, ch.name;

-- Q14: Left-joins Customer to Orders so customers with zero orders still appear, with their order counts.
SELECT c.customer_id, c.name, COUNT(o.order_id) AS orders_placed
FROM Customer c
LEFT JOIN Orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY orders_placed DESC, c.name;

-- Q15: Summarizes payments by method, keeping only methods used at least 3 times (GROUP BY + HAVING).
SELECT method,
       COUNT(*)              AS num_payments,
       ROUND(SUM(amount), 2) AS total_amount
FROM Payment
GROUP BY method
HAVING COUNT(*) >= 3
ORDER BY total_amount DESC;

-- Q16: Computes the number of items and menu-price subtotal for every order that has line items.
SELECT ct.order_id,
       SUM(ct.quantity)                      AS items,
       ROUND(SUM(ct.quantity * p.price), 2)  AS menu_subtotal
FROM Contains ct
JOIN Product p ON ct.product_id = p.product_id
GROUP BY ct.order_id
ORDER BY ct.order_id;

-- Q17: Uses a scalar subquery to find menu items priced above the menu average.
SELECT product_name, price
FROM Product
WHERE price > (SELECT AVG(price) FROM Product)
ORDER BY price DESC;

-- Q18: Counts how many orders each chef has prepared (LEFT JOIN keeps chefs with none).
SELECT ch.chef_id, ch.name, ch.specialty, COUNT(pr.order_id) AS orders_prepared
FROM Chef ch
LEFT JOIN Prepares pr ON pr.chef_id = ch.chef_id
GROUP BY ch.chef_id, ch.name, ch.specialty
ORDER BY orders_prepared DESC, ch.name;

-- Q19: Reports each waiter's number of orders and total payments collected on those orders.
SELECT w.name AS waiter,
       COUNT(o.order_id)               AS orders_served,
       COALESCE(SUM(p.amount), 0)      AS revenue
FROM Waiter w
LEFT JOIN Orders  o ON o.waiter_id = w.waiter_id
LEFT JOIN Payment p ON p.order_id  = o.order_id
GROUP BY w.waiter_id, w.name
ORDER BY revenue DESC;

-- Q20: Lists total units sold for every menu item, best sellers first (LEFT JOIN keeps items never ordered, at 0).
SELECT p.product_name, COALESCE(SUM(ct.quantity), 0) AS units_sold
FROM Product p
LEFT JOIN Contains ct ON ct.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC, p.product_name;

-- Q21: Conditional UPDATE that raises the price of every item under $5 by 10%.
UPDATE Product
SET price = ROUND(price * 1.10, 2)
WHERE price < 5;

-- Q22: Totals the number of paid orders and revenue for each calendar day.
SELECT date(o.order_time)   AS order_date,
       COUNT(*)             AS paid_orders,
       ROUND(SUM(p.amount), 2) AS daily_revenue
FROM Orders o
JOIN Payment p ON p.order_id = o.order_id
GROUP BY date(o.order_time)
ORDER BY order_date;


-- ############################################################################
-- PART 3: COMPLEX STATEMENTS (Q23 - Q37)
-- ############################################################################

-- Q23: Uses EXISTS to find customers who have paid at least one order by credit card.
SELECT c.customer_id, c.name
FROM Customer c
WHERE EXISTS (SELECT 1
              FROM Orders o
              JOIN Payment p ON p.order_id = o.order_id
              WHERE o.customer_id = c.customer_id
                AND p.method = 'Credit Card');

-- Q24: Uses NOT EXISTS to find menu items that have never appeared on any order.
SELECT p.product_id, p.product_name, p.price
FROM Product p
WHERE NOT EXISTS (SELECT 1
                  FROM Contains ct
                  WHERE ct.product_id = p.product_id)
ORDER BY p.product_id;

-- Q25: Uses NOT EXISTS to find registered customers who have never placed an order.
SELECT c.customer_id, c.name, c.phone
FROM Customer c
WHERE NOT EXISTS (SELECT 1
                  FROM Orders o
                  WHERE o.customer_id = c.customer_id);

-- Q26: Uses UNION to build one combined staff roster (managers, chefs, and waiters) with a role label.
SELECT name, 'Manager' AS role FROM Manager
UNION
SELECT name, 'Chef'    AS role FROM Chef
UNION
SELECT name, 'Waiter'  AS role FROM Waiter
ORDER BY role, name;

-- Q27: Uses INTERSECT to find customers who have paid with both a credit card and cash.
SELECT c.name
FROM Customer c
JOIN Orders  o ON o.customer_id = c.customer_id
JOIN Payment p ON p.order_id    = o.order_id
WHERE p.method = 'Credit Card'
INTERSECT
SELECT c.name
FROM Customer c
JOIN Orders  o ON o.customer_id = c.customer_id
JOIN Payment p ON p.order_id    = o.order_id
WHERE p.method = 'Cash';

-- Q28: Uses EXCEPT to find customers who have placed orders but have never paid in cash.
SELECT c.name
FROM Customer c
JOIN Orders o ON o.customer_id = c.customer_id
EXCEPT
SELECT c.name
FROM Customer c
JOIN Orders  o ON o.customer_id = c.customer_id
JOIN Payment p ON p.order_id    = o.order_id
WHERE p.method = 'Cash';

-- Q29: Uses a CTE to total each customer's spending, then keeps only customers who spent above the average.
WITH customer_spend AS (
    SELECT c.customer_id, c.name, SUM(p.amount) AS total_spent
    FROM Customer c
    JOIN Orders  o ON o.customer_id = c.customer_id
    JOIN Payment p ON p.order_id    = o.order_id
    GROUP BY c.customer_id, c.name
)
SELECT name, ROUND(total_spent, 2) AS total_spent
FROM customer_spend
WHERE total_spent > (SELECT AVG(total_spent) FROM customer_spend)
ORDER BY total_spent DESC;

-- Q30: Uses ROW_NUMBER() to return each customer's single most recent order.
WITH ranked AS (
    SELECT o.order_id, o.customer_id, o.order_time, o.order_status,
           ROW_NUMBER() OVER (PARTITION BY o.customer_id
                              ORDER BY o.order_time DESC) AS rn
    FROM Orders o
)
SELECT c.name AS customer, r.order_id, r.order_time, r.order_status
FROM ranked r
JOIN Customer c ON c.customer_id = r.customer_id
WHERE r.rn = 1
ORDER BY r.order_time DESC;

-- Q31: Uses DENSE_RANK() to rank menu items by price (tied prices share a rank) and shows the top 6 ranks.
SELECT price_rank, product_name, price
FROM (
    SELECT product_name, price,
           DENSE_RANK() OVER (ORDER BY price DESC) AS price_rank
    FROM Product
)
WHERE price_rank <= 6
ORDER BY price_rank, product_name;

-- Q32: Uses a windowed SUM() to show cumulative revenue in the order payments were received.
SELECT o.order_id,
       o.order_time,
       p.amount,
       ROUND(SUM(p.amount) OVER (ORDER BY o.order_time), 2) AS running_revenue
FROM Orders o
JOIN Payment p ON p.order_id = o.order_id
ORDER BY o.order_time;

-- Q33: Uses a CASE expression to bucket each payment as Small (< $25), Medium (< $75), or Large.
SELECT p.payment_id,
       p.order_id,
       p.amount,
       p.method,
       CASE
           WHEN p.amount < 25 THEN 'Small'
           WHEN p.amount < 75 THEN 'Medium'
           ELSE 'Large'
       END AS payment_size
FROM Payment p
ORDER BY p.amount DESC;

-- Q34: Creates a reusable view that joins each order to its customer, waiter, and payment (if any).
CREATE VIEW IF NOT EXISTS v_order_summary AS
SELECT o.order_id,
       o.order_time,
       o.order_status,
       c.name   AS customer_name,
       w.name   AS waiter_name,
       p.amount AS amount_paid,
       p.method AS payment_method
FROM Orders o
JOIN Customer c ON c.customer_id = o.customer_id
LEFT JOIN Waiter  w ON w.waiter_id = o.waiter_id
LEFT JOIN Payment p ON p.order_id  = o.order_id;

-- Q35: Queries the view for completed orders paid at $100 or more, largest first.
SELECT order_id, order_time, customer_name, waiter_name, amount_paid, payment_method
FROM v_order_summary
WHERE order_status = 'Completed' AND amount_paid >= 100
ORDER BY amount_paid DESC;

-- Q36: Creates a trigger that automatically marks an order 'Completed' as soon as its payment is inserted.
CREATE TRIGGER IF NOT EXISTS trg_payment_completes_order
AFTER INSERT ON Payment
BEGIN
    UPDATE Orders
    SET order_status = 'Completed'
    WHERE order_id = NEW.order_id;
END;

-- Q37: Creates a multi-action trigger that deletes an order's line items, chef assignments, and payment when the order is deleted.
CREATE TRIGGER IF NOT EXISTS trg_order_cascade_delete
BEFORE DELETE ON Orders
BEGIN
    DELETE FROM Contains WHERE order_id = OLD.order_id;
    DELETE FROM Prepares WHERE order_id = OLD.order_id;
    DELETE FROM Payment  WHERE order_id = OLD.order_id;
END;

-- ############################################################################
-- PART 4: TRIGGER DEMONSTRATIONS (Q38 - Q45)
-- Data modifications and checks that exercise the triggers created in Q36-Q37.
-- ############################################################################

-- Q38: Adds the items for in-progress order 12 (one carbonara and one tiramisu) with a multi-row INSERT.
INSERT INTO Contains (order_id, product_id, quantity)
VALUES (12, 4, 1),
       (12, 5, 1);

-- Q39: Assigns the pasta chef (Mei Lin) and dessert chef (Amelie Dubois) to order 12.
INSERT INTO Prepares (chef_id, order_id)
VALUES (2, 12),
       (4, 12);

-- Q40: Records order 12's payment; the Q36 trigger should flip that order from 'Preparing' to 'Completed'.
INSERT INTO Payment (payment_id, amount, method, order_id)
VALUES (12, 20.50, 'Credit Card', 12);

-- Q41: Confirms the trigger fired by showing the three newest orders through the view.
SELECT order_id, order_time, order_status, customer_name, amount_paid, payment_method
FROM v_order_summary
ORDER BY order_time DESC
LIMIT 3;

-- Q42: Creates a cancelled order (13) with one line item so the cascade-delete trigger can be demonstrated.
INSERT INTO Orders (order_id, order_time, order_status, customer_id, waiter_id)
VALUES (13, '2026-11-12 18:05:10', 'Cancelled', 3, 1);

-- Q43: Adds a single line item (one cheese pizza) to cancelled order 13.
INSERT INTO Contains (order_id, product_id, quantity)
VALUES (13, 10, 1);

-- Q44: Deletes cancelled order 13; the Q37 trigger should also remove its line item.
DELETE FROM Orders
WHERE order_id = 13 AND order_status = 'Cancelled';

-- Q45: Verifies the cascade by counting leftover rows for order 13 across Orders and Contains (both should be 0).
SELECT (SELECT COUNT(*) FROM Orders   WHERE order_id = 13) AS orders_rows,
       (SELECT COUNT(*) FROM Contains WHERE order_id = 13) AS contains_rows;
-- ============================================================================
-- CSE 111 - Checkpoint 2 Script
-- Restaurant Management Database
-- Team members: <FILL IN NAMES>
-- Run with:  sqlite3 Checkpoint2-dbase.sqlite3
--            .read Checkpoint2-script.sql
-- ============================================================================
.headers on
.mode column

-- ============================================================================
-- SCHEMA MODIFICATIONS SINCE CHECKPOINT 1
-- None to the base tables or their columns (Customer, Manager, Chef, Waiter,
-- Product, Orders, Payment, Prepares, Contains).
-- This script additionally creates one VIEW (v_order_summary, Q34) and two
-- TRIGGERS (trg_payment_completes_order, trg_order_cascade_delete, Q36-Q37).
-- ============================================================================


-- ############################################################################
-- PART 1: SIMPLE STATEMENTS (Q1 - Q11)
-- ############################################################################

-- Q1: Lists every menu item with its price, most expensive first.
SELECT product_name, price
FROM Product
ORDER BY price DESC;

-- Q2: Finds all pizza items on the menu using pattern matching on the name.
SELECT product_id, product_name, price
FROM Product
WHERE product_name LIKE '%Pizza%';

-- Q3: Shows orders placed on or after November 6, newest first.
SELECT order_id, order_time, order_status
FROM Orders
WHERE order_time >= '2026-11-06'
ORDER BY order_time DESC;

-- Q4: Computes scalar aggregates (count, total, average, min, max) over all payments.
SELECT COUNT(*)                AS num_payments,
       SUM(amount)             AS total_collected,
       ROUND(AVG(amount), 2)   AS avg_payment,
       MIN(amount)             AS smallest_payment,
       MAX(amount)             AS largest_payment
FROM Payment;

-- Q5: Lists the distinct payment methods customers have used.
SELECT DISTINCT method
FROM Payment
ORDER BY method;

-- Q6: Finds mid-priced menu items (between $10 and $20), cheapest first.
SELECT product_name, price
FROM Product
WHERE price BETWEEN 10 AND 20
ORDER BY price ASC, product_name ASC;

-- Q7: Registers a new customer, Frank Ortiz (single-row INSERT).
INSERT INTO Customer (customer_id, name, phone)
VALUES (6, 'Frank Ortiz', '209-555-0206');

-- Q8: Updates Frank Ortiz's phone number after he reports a new one (single-row UPDATE).
UPDATE Customer
SET phone = '209-555-0299'
WHERE customer_id = 6;

-- Q9: Adds a new beverage, Sparkling Water, to the menu (single-row INSERT).
INSERT INTO Product (product_id, product_name, price)
VALUES (22, 'Sparkling Water', 3.50);

-- Q10: Removes Frank Ortiz's account, as if he asked to be deleted (single-row DELETE).
DELETE FROM Customer
WHERE customer_id = 6;

-- Q11: Retrieves the three most recent orders.
SELECT order_id, order_time, order_status, customer_id, waiter_id
FROM Orders
ORDER BY order_time DESC
LIMIT 3;


-- ############################################################################
-- PART 2: INTERMEDIATE STATEMENTS (Q12 - Q22)
-- ############################################################################

-- Q12: Inner-joins Orders with Customer and Waiter to list who ordered and who served each order.
SELECT o.order_id,
       o.order_time,
       c.name AS customer,
       w.name AS waiter,
       o.order_status
FROM Orders o
JOIN Customer c ON o.customer_id = c.customer_id
JOIN Waiter   w ON o.waiter_id   = w.waiter_id
ORDER BY o.order_time;

-- Q13: Joins each chef to the manager they report to.
SELECT ch.name AS chef, ch.specialty, m.name AS manager
FROM Chef ch
JOIN Manager m ON ch.manager_id = m.manager_id
ORDER BY m.name, ch.name;

-- Q14: Left-joins Customer to Orders so customers with zero orders still appear, with their order counts.
SELECT c.customer_id, c.name, COUNT(o.order_id) AS orders_placed
FROM Customer c
LEFT JOIN Orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY orders_placed DESC, c.name;

-- Q15: Summarizes payments by method, keeping only methods used at least 3 times (GROUP BY + HAVING).
SELECT method,
       COUNT(*)              AS num_payments,
       ROUND(SUM(amount), 2) AS total_amount
FROM Payment
GROUP BY method
HAVING COUNT(*) >= 3
ORDER BY total_amount DESC;

-- Q16: Computes the number of items and menu-price subtotal for every order that has line items.
SELECT ct.order_id,
       SUM(ct.quantity)                      AS items,
       ROUND(SUM(ct.quantity * p.price), 2)  AS menu_subtotal
FROM Contains ct
JOIN Product p ON ct.product_id = p.product_id
GROUP BY ct.order_id
ORDER BY ct.order_id;

-- Q17: Uses a scalar subquery to find menu items priced above the menu average.
SELECT product_name, price
FROM Product
WHERE price > (SELECT AVG(price) FROM Product)
ORDER BY price DESC;

-- Q18: Counts how many orders each chef has prepared (LEFT JOIN keeps chefs with none).
SELECT ch.chef_id, ch.name, ch.specialty, COUNT(pr.order_id) AS orders_prepared
FROM Chef ch
LEFT JOIN Prepares pr ON pr.chef_id = ch.chef_id
GROUP BY ch.chef_id, ch.name, ch.specialty
ORDER BY orders_prepared DESC, ch.name;

-- Q19: Reports each waiter's number of orders and total payments collected on those orders.
SELECT w.name AS waiter,
       COUNT(o.order_id)               AS orders_served,
       COALESCE(SUM(p.amount), 0)      AS revenue
FROM Waiter w
LEFT JOIN Orders  o ON o.waiter_id = w.waiter_id
LEFT JOIN Payment p ON p.order_id  = o.order_id
GROUP BY w.waiter_id, w.name
ORDER BY revenue DESC;

-- Q20: Lists total units sold for every menu item, best sellers first (LEFT JOIN keeps items never ordered, at 0).
SELECT p.product_name, COALESCE(SUM(ct.quantity), 0) AS units_sold
FROM Product p
LEFT JOIN Contains ct ON ct.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC, p.product_name;

-- Q21: Conditional UPDATE that raises the price of every item under $5 by 10%.
UPDATE Product
SET price = ROUND(price * 1.10, 2)
WHERE price < 5;

-- Q22: Totals the number of paid orders and revenue for each calendar day.
SELECT date(o.order_time)   AS order_date,
       COUNT(*)             AS paid_orders,
       ROUND(SUM(p.amount), 2) AS daily_revenue
FROM Orders o
JOIN Payment p ON p.order_id = o.order_id
GROUP BY date(o.order_time)
ORDER BY order_date;


-- ############################################################################
-- PART 3: COMPLEX STATEMENTS (Q23 - Q37)
-- ############################################################################

-- Q23: Uses EXISTS to find customers who have paid at least one order by credit card.
SELECT c.customer_id, c.name
FROM Customer c
WHERE EXISTS (SELECT 1
              FROM Orders o
              JOIN Payment p ON p.order_id = o.order_id
              WHERE o.customer_id = c.customer_id
                AND p.method = 'Credit Card');

-- Q24: Uses NOT EXISTS to find menu items that have never appeared on any order.
SELECT p.product_id, p.product_name, p.price
FROM Product p
WHERE NOT EXISTS (SELECT 1
                  FROM Contains ct
                  WHERE ct.product_id = p.product_id)
ORDER BY p.product_id;

-- Q25: Uses NOT EXISTS to find registered customers who have never placed an order.
SELECT c.customer_id, c.name, c.phone
FROM Customer c
WHERE NOT EXISTS (SELECT 1
                  FROM Orders o
                  WHERE o.customer_id = c.customer_id);

-- Q26: Uses UNION to build one combined staff roster (managers, chefs, and waiters) with a role label.
SELECT name, 'Manager' AS role FROM Manager
UNION
SELECT name, 'Chef'    AS role FROM Chef
UNION
SELECT name, 'Waiter'  AS role FROM Waiter
ORDER BY role, name;

-- Q27: Uses INTERSECT to find customers who have paid with both a credit card and cash.
SELECT c.name
FROM Customer c
JOIN Orders  o ON o.customer_id = c.customer_id
JOIN Payment p ON p.order_id    = o.order_id
WHERE p.method = 'Credit Card'
INTERSECT
SELECT c.name
FROM Customer c
JOIN Orders  o ON o.customer_id = c.customer_id
JOIN Payment p ON p.order_id    = o.order_id
WHERE p.method = 'Cash';

-- Q28: Uses EXCEPT to find customers who have placed orders but have never paid in cash.
SELECT c.name
FROM Customer c
JOIN Orders o ON o.customer_id = c.customer_id
EXCEPT
SELECT c.name
FROM Customer c
JOIN Orders  o ON o.customer_id = c.customer_id
JOIN Payment p ON p.order_id    = o.order_id
WHERE p.method = 'Cash';

-- Q29: Uses a CTE to total each customer's spending, then keeps only customers who spent above the average.
WITH customer_spend AS (
    SELECT c.customer_id, c.name, SUM(p.amount) AS total_spent
    FROM Customer c
    JOIN Orders  o ON o.customer_id = c.customer_id
    JOIN Payment p ON p.order_id    = o.order_id
    GROUP BY c.customer_id, c.name
)
SELECT name, ROUND(total_spent, 2) AS total_spent
FROM customer_spend
WHERE total_spent > (SELECT AVG(total_spent) FROM customer_spend)
ORDER BY total_spent DESC;

-- Q30: Uses ROW_NUMBER() to return each customer's single most recent order.
WITH ranked AS (
    SELECT o.order_id, o.customer_id, o.order_time, o.order_status,
           ROW_NUMBER() OVER (PARTITION BY o.customer_id
                              ORDER BY o.order_time DESC) AS rn
    FROM Orders o
)
SELECT c.name AS customer, r.order_id, r.order_time, r.order_status
FROM ranked r
JOIN Customer c ON c.customer_id = r.customer_id
WHERE r.rn = 1
ORDER BY r.order_time DESC;

-- Q31: Uses DENSE_RANK() to rank menu items by price (tied prices share a rank) and shows the top 6 ranks.
SELECT price_rank, product_name, price
FROM (
    SELECT product_name, price,
           DENSE_RANK() OVER (ORDER BY price DESC) AS price_rank
    FROM Product
)
WHERE price_rank <= 6
ORDER BY price_rank, product_name;

-- Q32: Uses a windowed SUM() to show cumulative revenue in the order payments were received.
SELECT o.order_id,
       o.order_time,
       p.amount,
       ROUND(SUM(p.amount) OVER (ORDER BY o.order_time), 2) AS running_revenue
FROM Orders o
JOIN Payment p ON p.order_id = o.order_id
ORDER BY o.order_time;

-- Q33: Uses a CASE expression to bucket each payment as Small (< $25), Medium (< $75), or Large.
SELECT p.payment_id,
       p.order_id,
       p.amount,
       p.method,
       CASE
           WHEN p.amount < 25 THEN 'Small'
           WHEN p.amount < 75 THEN 'Medium'
           ELSE 'Large'
       END AS payment_size
FROM Payment p
ORDER BY p.amount DESC;

-- Q34: Creates a reusable view that joins each order to its customer, waiter, and payment (if any).
CREATE VIEW IF NOT EXISTS v_order_summary AS
SELECT o.order_id,
       o.order_time,
       o.order_status,
       c.name   AS customer_name,
       w.name   AS waiter_name,
       p.amount AS amount_paid,
       p.method AS payment_method
FROM Orders o
JOIN Customer c ON c.customer_id = o.customer_id
LEFT JOIN Waiter  w ON w.waiter_id = o.waiter_id
LEFT JOIN Payment p ON p.order_id  = o.order_id;

-- Q35: Queries the view for completed orders paid at $100 or more, largest first.
SELECT order_id, order_time, customer_name, waiter_name, amount_paid, payment_method
FROM v_order_summary
WHERE order_status = 'Completed' AND amount_paid >= 100
ORDER BY amount_paid DESC;

-- Q36: Creates a trigger that automatically marks an order 'Completed' as soon as its payment is inserted.
CREATE TRIGGER IF NOT EXISTS trg_payment_completes_order
AFTER INSERT ON Payment
BEGIN
    UPDATE Orders
    SET order_status = 'Completed'
    WHERE order_id = NEW.order_id;
END;

-- Q37: Creates a multi-action trigger that deletes an order's line items, chef assignments, and payment when the order is deleted.
CREATE TRIGGER IF NOT EXISTS trg_order_cascade_delete
BEFORE DELETE ON Orders
BEGIN
    DELETE FROM Contains WHERE order_id = OLD.order_id;
    DELETE FROM Prepares WHERE order_id = OLD.order_id;
    DELETE FROM Payment  WHERE order_id = OLD.order_id;
END;

-- ############################################################################
-- PART 4: TRIGGER DEMONSTRATIONS (Q38 - Q45)
-- Data modifications and checks that exercise the triggers created in Q36-Q37.
-- ############################################################################

-- Q38: Adds the items for in-progress order 12 (one carbonara and one tiramisu) with a multi-row INSERT.
INSERT INTO Contains (order_id, product_id, quantity)
VALUES (12, 4, 1),
       (12, 5, 1);

-- Q39: Assigns the pasta chef (Mei Lin) and dessert chef (Amelie Dubois) to order 12.
INSERT INTO Prepares (chef_id, order_id)
VALUES (2, 12),
       (4, 12);

-- Q40: Records order 12's payment; the Q36 trigger should flip that order from 'Preparing' to 'Completed'.
INSERT INTO Payment (payment_id, amount, method, order_id)
VALUES (12, 20.50, 'Credit Card', 12);

-- Q41: Confirms the trigger fired by showing the three newest orders through the view.
SELECT order_id, order_time, order_status, customer_name, amount_paid, payment_method
FROM v_order_summary
ORDER BY order_time DESC
LIMIT 3;

-- Q42: Creates a cancelled order (13) with one line item so the cascade-delete trigger can be demonstrated.
INSERT INTO Orders (order_id, order_time, order_status, customer_id, waiter_id)
VALUES (13, '2026-11-12 18:05:10', 'Cancelled', 3, 1);

-- Q43: Adds a single line item (one cheese pizza) to cancelled order 13.
INSERT INTO Contains (order_id, product_id, quantity)
VALUES (13, 10, 1);

-- Q44: Deletes cancelled order 13; the Q37 trigger should also remove its line item.
DELETE FROM Orders
WHERE order_id = 13 AND order_status = 'Cancelled';

-- Q45: Verifies the cascade by counting leftover rows for order 13 across Orders and Contains (both should be 0).
SELECT (SELECT COUNT(*) FROM Orders   WHERE order_id = 13) AS orders_rows,
       (SELECT COUNT(*) FROM Contains WHERE order_id = 13) AS contains_rows;
