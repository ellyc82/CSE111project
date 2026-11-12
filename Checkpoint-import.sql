
-- Checkpoint 2 Import Script

.mode ascii
.separator "|"

DELETE FROM Contains;
DELETE FROM Prepares;
DELETE FROM Payment;
DELETE FROM Orders;
DELETE FROM Product;
DELETE FROM Waiter;
DELETE FROM Chef;
DELETE FROM Manager;
DELETE FROM Customer;

.import data/manager.tbl Manager
.import data/chef.tbl Chef
.import data/waiter.tbl Waiter
.import data/customer.tbl Customer
.import data/product.tbl Product
.import data/orders.tbl Orders
.import data/payment.tbl Payment
.import data/prepares.tbl Prepares
.import data/contains.tbl Contains
