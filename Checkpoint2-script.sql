-- ============================================================================
-- CSE 111 Fall 2026: Project Checkpoint 2 Script
-- Project Title: Restaurant Management Database
-- Team Members: Anamaria Rodriguez, Michelle Cheung
-- File: Checkpoint2-script.sql
-- ============================================================================

-- ============================================================================
-- SCHEMA MODIFICATIONS SINCE CHECKPOINT 1
-- ============================================================================
-- 1. Base Tables: None. The nine tables (Customer, Manager, Chef, Waiter,
--    Product, Orders, Payment, Prepares, Contains) remained unchanged.
-- 2. View Added: v_order_summary, created in Statement 31, joins each order
--    to its customer, waiter, and payment.
-- 3. Trigger Integration: trg_payment_completes_order (Statement 33) and
--    trg_order_cascade_delete (Statement 34) were added to keep order data
--    consistent when payments are recorded and orders are deleted.
-- 4. Re-runnable: data-modification statements use INSERT OR REPLACE and
--    absolute values, and DROP ... IF EXISTS precedes each CREATE VIEW/TRIGGER,
--    so this script runs cleanly more than once on the same database.
-- ============================================================================

-- ============================================================================
-- MEMBER CONTRIBUTIONS SUMMARY (GROUPED AT THE TOP)
-- ============================================================================
-- SECTION 1: SIMPLE STATEMENTS
-- Statement 01: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 02: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 03: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 04: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 05: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 06: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 07: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 08: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 09: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 10: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
--
-- SECTION 2: INTERMEDIATE STATEMENTS
-- Statement 11: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 12: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 13: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 14: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 15: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 16: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 17: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 18: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 19: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 20: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 21: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
--
-- SECTION 3: COMPLEX STATEMENTS
-- Statement 22: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 23: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 24: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 25: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 26: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 27: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 28: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 29: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 30: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 31: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 32: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 33: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- Statement 34: Anamaria Rodriguez: 50%, Michelle Cheung: 50%
-- ============================================================================

PRAGMA foreign_keys = ON;
.headers on
.mode column


-- ============================================================================
-- SECTION 1: SIMPLE STATEMENTS (Statements 1 to 10)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Statement 01: Menu Items by Price
-- Explanation: List every menu item with its price, most expensive first.
-- ----------------------------------------------------------------------------

SELECT product_name, price
FROM Product
ORDER BY price DESC;

-- ----------------------------------------------------------------------------
-- Statement 02: Pizza Menu Items (Pattern Matching)
-- Explanation: Find all pizza items on the menu using a LIKE pattern on the
--              product name.
-- ----------------------------------------------------------------------------



SELECT product_id, product_name, price
FROM Product
WHERE product_name LIKE '%Pizza%';

-- ----------------------------------------------------------------------------
-- Statement 03: Recent Orders Filter
-- Explanation: Show orders placed on or after November 1, 2026, newest first.
-- ----------------------------------------------------------------------------
SELECT order_id, order_time, order_status
FROM Orders
WHERE order_time >= '2026-11-01'
ORDER BY order_time DESC;

-- ----------------------------------------------------------------------------
-- Statement 04: Aggregate Payment Metrics
-- Explanation: Compute the number of payments, total collected, average,
--              smallest, and largest payment amount.
-- ----------------------------------------------------------------------------
SELECT
    COUNT(*) AS num_payments,
    SUM(amount) AS total_collected,
    ROUND(AVG(amount), 2) AS avg_payment,
    MIN(amount) AS smallest_payment,
    MAX(amount) AS largest_payment
FROM Payment;

-- ----------------------------------------------------------------------------
-- Statement 05: Distinct Payment Methods
-- Explanation: List the unique payment methods that customers have used.
-- ----------------------------------------------------------------------------
SELECT DISTINCT method
FROM Payment
ORDER BY method;

-- ----------------------------------------------------------------------------
-- Statement 06: Mid-Priced Menu Items (BETWEEN)
-- Explanation: Find menu items priced between $10 and $20, cheapest first.
-- ----------------------------------------------------------------------------
SELECT product_name, price
FROM Product
WHERE price BETWEEN 10 AND 20
ORDER BY price ASC, product_name ASC;

-- ----------------------------------------------------------------------------
-- Statement 07: Insert New Customer
-- Explanation: Register a new customer, Frank Ortiz, in the Customer table
--              (single-row INSERT).
-- ----------------------------------------------------------------------------
INSERT OR REPLACE INTO Customer (customer_id, name, phone)
VALUES (6, 'Frank Ortiz', '209-555-0206');

-- ----------------------------------------------------------------------------
-- Statement 08: Update Customer Phone Number
-- Explanation: Change Frank Ortiz's phone number after he reports a new one
--              (single-row UPDATE).
-- ----------------------------------------------------------------------------
UPDATE Customer
SET phone = '209-555-0299'
WHERE customer_id = 6;

-- ----------------------------------------------------------------------------
-- Statement 09: Insert New Menu Item
-- Explanation: Add a new beverage, Sparkling Water, to the Product table
--              (single-row INSERT).
-- ----------------------------------------------------------------------------
INSERT OR REPLACE INTO Product (product_id, product_name, price)
VALUES (22, 'Sparkling Water', 3.50);

-- ----------------------------------------------------------------------------
-- Statement 10: Delete Customer Account
-- Explanation: Remove Frank Ortiz's account, as if he asked to be deleted
--              (single-row DELETE).
-- ----------------------------------------------------------------------------




DELETE FROM Customer
WHERE customer_id = 6;


-- ============================================================================
-- SECTION 2: INTERMEDIATE STATEMENTS (Statements 11 to 21)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Statement 11: Orders with Customer and Waiter (Multi-Table Inner Join)
-- Explanation: List every order with the customer who placed it and the
--              waiter who served it.
-- ----------------------------------------------------------------------------


SELECT
    O.order_id,
    O.order_time,
    C.name AS customer,
    W.name AS waiter,
    O.order_status
FROM Orders O
JOIN Customer C ON O.customer_id = C.customer_id
JOIN Waiter W ON O.waiter_id = W.waiter_id
ORDER BY O.order_time;
-- ----------------------------------------------------------------------------
-- Statement 12: Chefs and Their Managers (Inner Join)
-- Explanation: Join each chef to the manager they report to.
-- ----------------------------------------------------------------------------
SELECT
    CH.name AS chef,
    CH.specialty,
    M.name AS manager
FROM Chef CH
JOIN Manager M ON CH.manager_id = M.manager_id
ORDER BY M.name, CH.name;

-- ----------------------------------------------------------------------------
-- Statement 13: Customer Order Counts (LEFT OUTER JOIN)
-- Explanation: Count the orders placed by every customer, keeping customers
--              who have never ordered.
-- ----------------------------------------------------------------------------
SELECT
    C.customer_id,
    C.name,
    COUNT(O.order_id) AS orders_placed
FROM Customer C
LEFT JOIN Orders O ON O.customer_id = C.customer_id
GROUP BY C.customer_id, C.name
ORDER BY orders_placed DESC, C.name;

-- ----------------------------------------------------------------------------
-- Statement 14: Payment Method Summary (GROUP BY & HAVING)
-- Explanation: Summarize payments by method, keeping only methods that were
--              used at least 3 times.
-- ----------------------------------------------------------------------------




SELECT
    method,
    COUNT(*) AS num_payments,
    ROUND(SUM(amount), 2) AS total_amount
FROM Payment
GROUP BY method
HAVING COUNT(*) >= 3
ORDER BY total_amount DESC;

-- ----------------------------------------------------------------------------
-- Statement 15: Order Item Counts and Menu Subtotals
-- Explanation: Compute the number of items and the menu-price subtotal for
--              every order that has line items.
-- ----------------------------------------------------------------------------

SELECT
    CT.order_id,
    SUM(CT.quantity) AS items,
    ROUND(SUM(CT.quantity * P.price), 2) AS menu_subtotal
FROM Contains CT
JOIN Product P ON CT.product_id = P.product_id
GROUP BY CT.order_id
ORDER BY CT.order_id;

-- ----------------------------------------------------------------------------
-- Statement 16: Above-Average Priced Items (Scalar Subquery)
-- Explanation: Find menu items whose price is higher than the average price
--              of the whole menu.
-- ----------------------------------------------------------------------------
SELECT product_name, price
FROM Product
WHERE price > (SELECT AVG(price) FROM Product)
ORDER BY price DESC;

-- ----------------------------------------------------------------------------
-- Statement 17: Chef Workload (LEFT JOIN with Aggregation)
-- Explanation: Count how many orders each chef has prepared, keeping chefs
--              who have prepared none.
-- ----------------------------------------------------------------------------
SELECT
    CH.chef_id,
    CH.name,
    CH.specialty,
    COUNT(PR.order_id) AS orders_prepared
FROM Chef CH
LEFT JOIN Prepares PR ON PR.chef_id = CH.chef_id
GROUP BY CH.chef_id, CH.name, CH.specialty
ORDER BY orders_prepared DESC, CH.name;

-- ----------------------------------------------------------------------------
-- Statement 18: Waiter Performance (Multi-Table LEFT JOIN)
-- Explanation: Report each waiter's number of orders served and the total
--              payments collected on those orders.
-- ----------------------------------------------------------------------------
SELECT
    W.name AS waiter,
    COUNT(O.order_id) AS orders_served,
    COALESCE(SUM(P.amount), 0) AS revenue
FROM Waiter W
LEFT JOIN Orders O ON O.waiter_id = W.waiter_id
LEFT JOIN Payment P ON P.order_id = O.order_id
GROUP BY W.waiter_id, W.name
ORDER BY revenue DESC;

-- ----------------------------------------------------------------------------
-- Statement 19: Units Sold per Menu Item
-- Explanation: List total units sold for every menu item, best sellers first,
--              showing 0 for items never ordered.
-- ----------------------------------------------------------------------------
SELECT
    P.product_name,
    COALESCE(SUM(CT.quantity), 0) AS units_sold
FROM Product P
LEFT JOIN Contains CT ON CT.product_id = P.product_id
GROUP BY P.product_id, P.product_name
ORDER BY units_sold DESC, P.product_name;

-- ----------------------------------------------------------------------------
-- Statement 20: Conditional Price Increase (Conditional UPDATE)
-- Explanation: Apply a 10% price increase to the three items priced under $5
--              (Lemonade, Minestrone Soup, Sparkling Water).
-- ----------------------------------------------------------------------------
UPDATE Product
SET price = ROUND(CASE product_id
                      WHEN 6  THEN 3.00
                      WHEN 16 THEN 4.00
                      WHEN 22 THEN 3.50
                  END * 1.10, 2)
WHERE product_id IN (6, 16, 22);

-- ----------------------------------------------------------------------------
-- Statement 21: Daily Revenue (Join with GROUP BY on Date)
-- Explanation: Total the number of paid orders and the revenue collected for
--              each calendar day.
-- ----------------------------------------------------------------------------
SELECT
    DATE(O.order_time) AS order_date,
    COUNT(*) AS paid_orders,
    ROUND(SUM(P.amount), 2) AS daily_revenue
FROM Orders O
JOIN Payment P ON P.order_id = O.order_id
GROUP BY DATE(O.order_time)
ORDER BY order_date;


-- ============================================================================
-- SECTION 3: COMPLEX STATEMENTS (Statements 22 to 34)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Statement 22: Credit Card Customers (Correlated Subquery with EXISTS)
-- Explanation: Find customers who have paid at least one order by credit
--              card.
-- ----------------------------------------------------------------------------
SELECT C.customer_id, C.name
FROM Customer C
WHERE EXISTS (
    SELECT 1
    FROM Orders O
    JOIN Payment P ON P.order_id = O.order_id
    WHERE O.customer_id = C.customer_id
      AND P.method = 'Credit Card'
);

-- ----------------------------------------------------------------------------
-- Statement 23: Never-Ordered Menu Items (Correlated Subquery with NOT EXISTS)
-- Explanation: Find menu items that have never appeared on any order.
-- ----------------------------------------------------------------------------
SELECT P.product_id, P.product_name, P.price
FROM Product P
WHERE NOT EXISTS (
    SELECT 1
    FROM Contains CT
    WHERE CT.product_id = P.product_id
)
ORDER BY P.product_id;

-- ----------------------------------------------------------------------------
-- Statement 24: Combined Staff Roster (UNION)
-- Explanation: Build one staff roster of managers, chefs, and waiters,
--              labeled by role, using the UNION operator.
-- ----------------------------------------------------------------------------
SELECT name, 'Manager' AS role FROM Manager
UNION
SELECT name, 'Chef' AS role FROM Chef
UNION
SELECT name, 'Waiter' AS role FROM Waiter
ORDER BY role, name;

-- ----------------------------------------------------------------------------
-- Statement 25: Customers Who Paid by Card and Cash (INTERSECT)
-- Explanation: Find customers who have paid with both a credit card and cash
--              using the INTERSECT operator.
-- ----------------------------------------------------------------------------
SELECT C.name
FROM Customer C
JOIN Orders O ON O.customer_id = C.customer_id
JOIN Payment P ON P.order_id = O.order_id
WHERE P.method = 'Credit Card'
INTERSECT
SELECT C.name
FROM Customer C
JOIN Orders O ON O.customer_id = C.customer_id
JOIN Payment P ON P.order_id = O.order_id
WHERE P.method = 'Cash';

-- ----------------------------------------------------------------------------
-- Statement 26: Customers Who Never Paid Cash (EXCEPT)
-- Explanation: Find customers who have placed orders but have never paid in
--              cash using the EXCEPT operator.
-- ----------------------------------------------------------------------------
SELECT C.name
FROM Customer C
JOIN Orders O ON O.customer_id = C.customer_id
EXCEPT
SELECT C.name
FROM Customer C
JOIN Orders O ON O.customer_id = C.customer_id
JOIN Payment P ON P.order_id = O.order_id
WHERE P.method = 'Cash';

-- ----------------------------------------------------------------------------
-- Statement 27: Above-Average Customer Spending (CTE)
-- Explanation: Use a Common Table Expression to total each customer's
--              spending, then keep only customers who spent more than the
--              average.
-- ----------------------------------------------------------------------------
WITH CustomerSpend AS (
    SELECT C.customer_id, C.name, SUM(P.amount) AS total_spent
    FROM Customer C
    JOIN Orders O ON O.customer_id = C.customer_id
    JOIN Payment P ON P.order_id = O.order_id
    GROUP BY C.customer_id, C.name
)
SELECT name, ROUND(total_spent, 2) AS total_spent
FROM CustomerSpend
WHERE total_spent > (SELECT AVG(total_spent) FROM CustomerSpend)
ORDER BY total_spent DESC;

-- ----------------------------------------------------------------------------
-- Statement 28: Most Recent Order per Customer (Window Function ROW_NUMBER)
-- Explanation: Use ROW_NUMBER() partitioned by customer to return each
--              customer's single most recent order.
-- ----------------------------------------------------------------------------
WITH Ranked AS (
    SELECT
        O.order_id,
        O.customer_id,
        O.order_time,
        O.order_status,
        ROW_NUMBER() OVER (
            PARTITION BY O.customer_id
            ORDER BY O.order_time DESC
        ) AS rn
    FROM Orders O
)
SELECT C.name AS customer, R.order_id, R.order_time, R.order_status
FROM Ranked R
JOIN Customer C ON C.customer_id = R.customer_id
WHERE R.rn = 1
ORDER BY R.order_time DESC;

-- ----------------------------------------------------------------------------
-- Statement 29: Menu Price Ranking (Window Function DENSE_RANK)
-- Explanation: Rank menu items by price with DENSE_RANK() so tied prices
--              share a rank, and show the top 6 ranks.
-- ----------------------------------------------------------------------------
SELECT price_rank, product_name, price
FROM (
    SELECT
        product_name,
        price,
        DENSE_RANK() OVER (ORDER BY price DESC) AS price_rank
    FROM Product
)
WHERE price_rank <= 6
ORDER BY price_rank, product_name;

-- ----------------------------------------------------------------------------
-- Statement 30: Payment Size Buckets (CASE Expression)
-- Explanation: Classify each payment as Small (under $25), Medium (under
--              $75), or Large using a CASE expression.
-- ----------------------------------------------------------------------------
SELECT
    payment_id,
    order_id,
    amount,
    method,
    CASE
        WHEN amount < 25 THEN 'Small'
        WHEN amount < 75 THEN 'Medium'
        ELSE 'Large'
    END AS payment_size
FROM Payment
ORDER BY amount DESC;

-- ----------------------------------------------------------------------------
-- Statement 31: DDL View Creation for Order Summary
-- Explanation: Create a view that joins each order to its customer, waiter,
--              and payment (if one exists).
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_order_summary;

CREATE VIEW v_order_summary AS
SELECT
    O.order_id,
    O.order_time,
    O.order_status,
    C.name AS customer_name,
    W.name AS waiter_name,
    P.amount AS amount_paid,
    P.method AS payment_method
FROM Orders O
JOIN Customer C ON C.customer_id = O.customer_id
LEFT JOIN Waiter W ON W.waiter_id = O.waiter_id
LEFT JOIN Payment P ON P.order_id = O.order_id;

-- ----------------------------------------------------------------------------
-- Statement 32: Query Against Order Summary View
-- Explanation: Query the v_order_summary view for completed orders paid at
--              $100 or more, largest first.
-- ----------------------------------------------------------------------------
SELECT order_id, order_time, customer_name, waiter_name, amount_paid, payment_method
FROM v_order_summary
WHERE order_status = 'Completed' AND amount_paid >= 100
ORDER BY amount_paid DESC;

-- ----------------------------------------------------------------------------
-- Statement 33: Auto-Complete Order Trigger
-- Explanation: Create a trigger that marks an order 'Completed' automatically
--              as soon as its payment is inserted.
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_payment_completes_order;

CREATE TRIGGER trg_payment_completes_order
AFTER INSERT ON Payment
FOR EACH ROW
BEGIN
    UPDATE Orders
    SET order_status = 'Completed'
    WHERE order_id = NEW.order_id;
END;

-- ----------------------------------------------------------------------------
-- Statement 34: Cascade Delete Trigger (Multi-Action)
-- Explanation: Create a trigger that removes an order's line items, chef
--              assignments, and payment whenever that order is deleted.
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_order_cascade_delete;

CREATE TRIGGER trg_order_cascade_delete
BEFORE DELETE ON Orders
FOR EACH ROW
BEGIN
    DELETE FROM Contains WHERE order_id = OLD.order_id;
    DELETE FROM Prepares WHERE order_id = OLD.order_id;
    DELETE FROM Payment  WHERE order_id = OLD.order_id;
END;