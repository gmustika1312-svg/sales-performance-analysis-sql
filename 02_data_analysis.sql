
-- 1. RATA-RATA DURASI DARI ORDER SAMPAI PENGIRIMAN
SELECT 
    AVG(shipped_date - order_date) AS avg_shipped_days
FROM orders;

-- 2. Pada saat-saat kapan biasanya penjualan kita ramai?
-- 2A. JUMLAH ORDER TERBANYAK
SELECT
    EXTRACT(MONTH FROM order_date) AS month,
    COUNT(order_id) AS total_order
FROM orders
GROUP BY EXTRACT(MONTH FROM order_date)
ORDER BY total_order DESC;
-- 2B. BULAN DENGAN REVENUE TERBESAR
SELECT
    EXTRACT(MONTH FROM o.order_date) AS month,
    SUM(
        od.unit_price *
        od.quantity *
        (1 - od.discount)
    ) AS total_revenue
FROM orders o
JOIN orders_details od
    ON o.order_id = od.order_id
GROUP BY EXTRACT(MONTH FROM o.order_date)
ORDER BY total_revenue DESC;

-- 3. SHIPPING VENDOR BERDASARKAN SHIPPING RATIO
WITH order_sales AS (
    SELECT
        o.order_id,
        o.shipper_name,
        o.freight_cost,
        SUM(
            od.unit_price *
            od.quantity *
            (1 - od.discount)
        ) AS net_sales
    FROM orders o
    JOIN orders_details od
        ON o.order_id = od.order_id
    GROUP BY
        o.order_id,
        o.shipper_name,
        o.freight_cost
),

shipping_summary AS (
    SELECT
        shipper_name,
        SUM(freight_cost) AS total_freight,
        SUM(net_sales) AS revenue_sales
    FROM order_sales
    GROUP BY shipper_name
)
SELECT
    shipper_name,
    total_freight,
    revenue_sales,
    ROUND(
        total_freight /
        NULLIF(revenue_sales, 0) * 100,
        2
    ) AS shipping_ratio
FROM shipping_summary
ORDER BY shipping_ratio DESC;

-- 4. TOP 5 DAN BOTTOM 5 PRODUCTS
WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category_name,
        SUM(
            od.unit_price *
            od.quantity *
            (1 - od.discount)
        ) AS revenue_sales
    FROM product p
    JOIN orders_details od
        ON p.product_id = od.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category_name
),
ranking AS (
    SELECT
        *,
        RANK() OVER (
            ORDER BY revenue_sales DESC
        ) AS top_product,

        RANK() OVER (
            ORDER BY revenue_sales ASC
        ) AS bottom_product
    FROM product_sales
)
SELECT
    product_id,
    product_name,
    category_name,
    revenue_sales,
    CASE
        WHEN top_product <= 5 THEN 'Top 5'
        WHEN bottom_product <= 5 THEN 'Bottom 5'
    END AS status
FROM ranking
WHERE top_product <= 5
   OR bottom_product <= 5
ORDER BY revenue_sales DESC;

-- 5. GROSS SALES VS NET SALES PER BULAN
WITH performance_sales AS (
    SELECT
        o.order_id,
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(
            od.unit_price *
            od.quantity
        ) AS gross_sales,
        SUM(
            od.unit_price *
            od.quantity *
            (1 - od.discount)
        ) AS net_sales
    FROM orders o
    JOIN orders_details od
        ON o.order_id = od.order_id
    GROUP BY
        o.order_id,
        DATE_TRUNC('month', o.order_date)
)
SELECT
    TO_CHAR(month, 'Mon YYYY') AS month,
    SUM(gross_sales) AS total_gross_sales,
    SUM(net_sales) AS total_net_sales,
    COUNT(order_id) AS total_orders
FROM performance_sales
GROUP BY month
ORDER BY month;

-- 6. PERTUMBUHAN GROSS SALES YEAR-OVER-YEAR
WITH annual_sales AS (
    SELECT
        EXTRACT(YEAR FROM o.order_date) AS year,
        SUM(
            od.unit_price *
            od.quantity
        ) AS gross_sales
    FROM orders o
    JOIN orders_details od
        ON o.order_id = od.order_id
    GROUP BY
        EXTRACT(YEAR FROM o.order_date)
),
growth_sales AS (
    SELECT
        year,
        gross_sales,
        LAG(gross_sales) OVER (
            ORDER BY year
        ) AS prev_sales
    FROM annual_sales
)
SELECT
    year,
    gross_sales,
    prev_sales,
    ROUND(
        (
            (gross_sales - prev_sales) /
            NULLIF(prev_sales, 0)
        ) * 100,
        2
    ) AS growth_percentage
FROM growth_sales
ORDER BY year;

-- 7. KONTRIBUSI PENJUALAN SETIAP EMPLOYEE
WITH employee_sales AS (
    SELECT
        e.employee_id,
        e.employee_name,
        SUM(
            od.unit_price *
            od.quantity *
            (1 - od.discount)
        ) AS revenue_sales
    FROM employees e
    JOIN orders o
        ON e.employee_id = o.employee_id
    JOIN orders_details od
        ON o.order_id = od.order_id
    GROUP BY
        e.employee_id,
        e.employee_name
)
SELECT
    employee_id,
    employee_name,
    revenue_sales,
    ROUND(
        revenue_sales /
        NULLIF(
            SUM(revenue_sales) OVER (),
            0
        ) * 100,
        2
    ) AS contribution_percentage
FROM employee_sales
ORDER BY revenue_sales DESC;

-- 8. KONTRIBUSI CATEGORY TERHADAP TOTAL SALES PER TAHUN
WITH category_sales AS (
    SELECT
        EXTRACT(YEAR FROM o.order_date) AS year,
        p.category_name,
        SUM(
            od.unit_price * od.quantity * (1 - od.discount / 100)
        ) AS revenue_sales
    FROM orders o
    JOIN orders_details od
        ON o.order_id = od.order_id
    JOIN product p
        ON od.product_id = p.product_id
    GROUP BY
        EXTRACT(YEAR FROM o.order_date),
        p.category_name
)

SELECT
    year,
    category_name,
    revenue_sales,
    ROUND(
        revenue_sales /
        NULLIF(
            SUM(revenue_sales) OVER (PARTITION BY year),
            0
        ) * 100,
        2
    ) AS contribution_percentage
FROM category_sales
ORDER BY
    year,
    contribution_percentage DESC;

