-- Checkpoint 2 Script
.headers on
CREATE TABLE Customer ( 
    customer_id INT PRIMARY KEY, 
    name VARCHAR(100) NOT NULL, 
    phone VARCHAR(20) 
); 


CREATE TABLE Manager ( 
    manager_id INT PRIMARY KEY, 
    name VARCHAR(100) NOT NULL 

); 

CREATE TABLE Chef ( 
    chef_id INT PRIMARY KEY, 
    name VARCHAR(100) NOT NULL, 
    specialty VARCHAR(100), 
    manager_id INT 
); 


CREATE TABLE Waiter ( 
    waiter_id INT PRIMARY KEY, 
    name VARCHAR(100) NOT NULL, 
    phone VARCHAR(20), 
    manager_id INT 

); 


CREATE TABLE Product ( 
    product_id INT PRIMARY KEY, 
    product_name VARCHAR(100) NOT NULL, 
    price DECIMAL(10,2) NOT NULL
);


CREATE TABLE Orders ( 
    order_id INT PRIMARY KEY, 
    order_time DATETIME NOT NULL, 
    order_status VARCHAR(30), 
    customer_id INT NOT NULL, 
    waiter_id INT 

);

CREATE TABLE Payment ( 
    payment_id INT PRIMARY KEY, 
    amount DECIMAL(10,2) NOT NULL, 
    method VARCHAR(30), 
    order_id INT NOT NULL UNIQUE 

); 

CREATE TABLE Prepares ( 
    chef_id  INT, 
    order_id INT, 
    PRIMARY KEY (chef_id, order_id) 
); 

 
CREATE TABLE Contains ( 
    order_id INT, 
    product_id INT, 
    quantity INT NOT NULL DEFAULT 1, 
    PRIMARY KEY (order_id, product_id) 
); 