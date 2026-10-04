-- 1. CREATE TABLE
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id VARCHAR(50),
    employee_id INT,
    order_date DATE,
    required_date DATE,
    shipped_date DATE,
    shipper_name VARCHAR(100),
    freight_cost NUMERIC(10,2)
);

CREATE TABLE orders_details (
    order_id INT,
    product_id INT,
    unit_price NUMERIC(10,2),
    quantity INT,
    discount DECIMAL(4,2),
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100),
    title VARCHAR(100),
    city VARCHAR(50),
    country VARCHAR(50)
);

CREATE TABLE product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    quantity_per_unit VARCHAR(100),
    discontinued INT,
    category_name VARCHAR(30)
);

-- 2. CEK TABEL
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- 3. CEK ISI TABEL
SELECT * FROM orders;
SELECT * FROM orders_details;
SELECT * FROM employees;
SELECT * FROM product;

-- 4. CEK JUMLAH DATA
SELECT COUNT(*) AS total_orders
FROM orders;
SELECT COUNT(*) AS total_order_details
FROM orders_details;
SELECT COUNT(*) AS total_employees
FROM employees;
SELECT COUNT(*) AS total_products
FROM product;

-- 5. CEK MISSING VALUE
--- TABLE ORDERS
SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE employee_id IS NULL) AS null_employee_id,
    COUNT(*) FILTER (WHERE order_date IS NULL) AS null_order_date,
    COUNT(*) FILTER (WHERE required_date IS NULL) AS null_required_date,
    COUNT(*) FILTER (WHERE shipped_date IS NULL) AS null_shipped_date,
    COUNT(*) FILTER (WHERE shipper_name IS NULL) AS null_shipper_name,
    COUNT(*) FILTER (WHERE freight_cost IS NULL) AS null_freight_cost
FROM orders;
--- TABLE ORDER_DETAILS
SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE unit_price IS NULL) AS null_unit_price,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS null_quantity,
    COUNT(*) FILTER (WHERE discount IS NULL) AS null_discount
FROM orders_details;
-- TABLE EMPLOYEES
SELECT
    COUNT(*) FILTER (WHERE employee_id IS NULL) AS null_employee_id,
    COUNT(*) FILTER (WHERE employee_name IS NULL) AS null_employee_name,
    COUNT(*) FILTER (WHERE title IS NULL) AS null_title,
    COUNT(*) FILTER (WHERE city IS NULL) AS null_city,
    COUNT(*) FILTER (WHERE country IS NULL) AS null_country
FROM employees;
-- TABEL PRODUCTS
SELECT
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE product_name IS NULL) AS null_product_name,
    COUNT(*) FILTER (WHERE quantity_per_unit IS NULL) AS null_quantity_per_unit,
    COUNT(*) FILTER (WHERE discontinued IS NULL) AS null_discontinued,
    COUNT(*) FILTER (WHERE category_name IS NULL) AS null_category_name
FROM product;

-- 6. CHECK DUPLICATE
-- order_id pada orders
SELECT
    'orders' AS table_name,
    order_id::TEXT AS identifier,
    COUNT(*) AS total
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;
-- Kombinasi order_id + product_id
SELECT
    'orders_details' AS table_name,
    CONCAT(order_id, ' - ', product_id) AS identifier,
    COUNT(*) AS total
FROM orders_details
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;
-- employee_id pada employees
SELECT
    'employees' AS table_name,
    employee_id::TEXT AS identifier,
    COUNT(*) AS total
FROM employees
GROUP BY employee_id
HAVING COUNT(*) > 1;
-- Duplicate product_id pada product
SELECT
    'product' AS table_name,
    product_id::TEXT AS identifier,
    COUNT(*) AS total
FROM product
GROUP BY product_id
HAVING COUNT(*) > 1;

-- 7. VALIDASI DATA
SELECT *
FROM orders_details
WHERE quantity <= 0;
SELECT *
FROM orders_details
WHERE unit_price < 0;
SELECT *
FROM orders_details
WHERE discount < 0
   OR discount > 1;
SELECT *
FROM orders
WHERE shipped_date < order_date;
