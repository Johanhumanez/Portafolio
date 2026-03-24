CREATE DATABASE olist_project;
USE olist_project;

CREATE TABLE orders (
order_id VARCHAR(50) PRIMARY KEY,
customer_id VARCHAR(50),
order_status VARCHAR(20),
order_purchase_timestamp DATETIME,
order_approved_at DATETIME,
order_delivered_carrier_date DATETIME,
order_delivered_customer_date DATETIME,
order_estimated_delivery_date DATETIME
);

SELECT COUNT(*)FROM orders;

CREATE TABLE order_items(
order_id VARCHAR (50),
order_item_id INT,
product_id VARCHAR (50),
seller_id VARCHAR(50),
shipping_limit_date DATETIME,
price DECIMAL (10,2),
freight_value DECIMAL (10,2),

-- Combinación de order_id + order_item_id
PRIMARY KEY (order_id,order_item_id),
-- creación de clave foranea: el order_id de la tabla order_items, debe existir previamente en la tabla orders.
FOREIGN KEY (order_id) REFERENCES orders(order_id) 
);

select count(*) from order_items

SELECT COUNT(DISTINCT order_id) FROM order_items;

SELECT COUNT(*) FROM orders;

SELECT 
    SUM(price) AS total_revenue,
    SUM(freight_value) AS total_freight
FROM order_items;

-- # de ordenes por status

select order_status, count(order_status) from orders
group by order_status;

-- Revenue por mes
SELECT 
    DATE_FORMAT(O.order_purchase_timestamp, '%Y-%m') AS year_month_,
    SUM(oi.price) AS monthly_revenue
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY year_month_
ORDER BY 1;

-- Creación de tabla customers

CREATE TABLE customers (
customer_id VARCHAR(50) PRIMARY KEY,
customer_unique_id VARCHAR (50),
customer_zip_code_prefix INT,
customer_city VARCHAR (100),
customer_state VARCHAR(5)
);

-- Llave foranea customer_id

SELECT count(*) FROM customers;
ALTER TABLE orders
ADD CONSTRAINT fk_orders_customers
FOREIGN KEY(customer_id)
REFERENCES customers(customer_id);

SELECT 
C.customer_state,
SUM(OI.price) AS revenue
FROM orders O
JOIN customers C ON O.customer_id = C.customer_id
JOIN order_items OI ON O.order_id = OI.order_id
WHERE O.order_status = 'delivered'
GROUP BY C.customer_state
ORDER BY revenue DESC;


CREATE TABLE products (
product_id VARCHAR(50) PRIMARY KEY,
product_category_name VARCHAR(100),
product_name_lenght INT,
product_description_lenght INT,
product_photos_qty INT,
product_weight_g INT,
product_length_cm INT,
product_height_cm INT,
product_width_cm INT
);

SELECT COUNT(*) FROM products
SELECT * FROM products
truncate table products;

SHOW VARIABLES LIKE 'local_infile';

SET GLOBAL local_infile = 1;



LOAD DATA LOCAL INFILE 'C:/Users/johan/OneDrive/Documentos/Documentos Johan/CURSOS Y DIPLOMADOS/Portafolio/E-Commerce/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Conectar products con order_items

ALTER TABLE order_items
ADD CONSTRAINT fk_orderitems_products
FOREIGN KEY (product_id)
REFERENCES products(product_id);

-- CREAMOS TABLA sellers

CREATE TABLE sellers(
	seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR (100),
    seller_state VARCHAR (5)
);

-- Cargamos datos a tabla sellers
LOAD DATA LOCAL INFILE 'C:/Users/johan/OneDrive/Documentos/Documentos Johan/CURSOS Y DIPLOMADOS/Portafolio/E-Commerce/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select count(*) from sellers;


-- Conectamos sellers con order_items

ALTER TABLE order_items
ADD CONSTRAINT fk_orderitems_sellers
FOREIGN KEY (seller_id)
REFERENCES sellers(seller_id);

-- Creamos tabla order_payments

CREATE TABLE order_payments(
	order_id VARCHAR(50),
	payment_sequential INT,
	payment_type VARCHAR(50),
	payment_installments INT,
	payment_value DECIMAL(10,2),
	PRIMARY KEY (order_id,payment_sequential),
	FOREIGN KEY(order_id) REFERENCES orders(order_id)
);

-- Cargamos datos a tabla order_payments
LOAD DATA LOCAL INFILE 'C:/Users/johan/OneDrive/Documentos/Documentos Johan/CURSOS Y DIPLOMADOS/Portafolio/E-Commerce/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select count(*) from order_payments

select sum(price) AS total_items_revenue
from order_items

select sum(payment_value) AS total_payment_value
from order_payments


select 
	sum(price),
    sum(freight_value),
    sum(price+freight_value)
FROM order_items;

-- Calculo Total revenue (delivered solamente) y ticket promedio

SELECT 
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    SUM(oi.price + oi.freight_value) AS total_revenue,
    ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id),2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

-- Clientes con mas de 1 compra

SELECT 
	COUNT(*) AS total_customers,
	SUM(CASE WHEN order_count >1 then 1 else 0 END) AS repeat_customers
FROM (
SELECT c.customer_unique_id, COUNT(o.order_id) AS order_count
FROM orders o
INNER JOIN 
customers c
ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id)t;

-- Calculo de porcentaje de clientes con mas de una compra

SELECT 
	ROUND(
		SUM(CASE WHEN order_count >1 then 1 else 0 END)*100.0/COUNT(*),2) AS repeat_rate_percentaje
FROM (
	SELECT c.customer_unique_id, COUNT(o.order_id) AS order_count
	FROM orders o
	INNER JOIN 
	customers c
	ON o.customer_id = c.customer_id
	WHERE o.order_status = 'delivered'
	GROUP BY c.customer_unique_id)t;
    
-- Calculo de total de clientes y revenue por tipo de cliente
SELECT   
	customer_type,count(distinct customer_unique_id) AS customers,sum(total_revenue) AS revenue
FROM (
SELECT 
	c.customer_unique_id, CASE 
								WHEN COUNT(o.order_id)>1 THEN 'Repeat' 
								ELSE 'One-time'
					END AS customer_type,
                    SUM(oi.price+oi.freight_value) AS total_revenue
FROM orders o

INNER JOIN customers c
ON o.customer_id = c.customer_id
INNER JOIN order_items oi
ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id)t
GROUP BY customer_type;


-- Ticket promedio por tipo de cliente
SELECT   
	customer_type,ROUND(sum(total_revenue)/count(distinct customer_unique_id),2) AS avg_revenue_per_customer
FROM (
SELECT 
	c.customer_unique_id, CASE 
								WHEN COUNT(DISTINCT o.order_id)>1 THEN 'Repeat' 
								ELSE 'One-time'
					END AS customer_type,
                    SUM(oi.price+oi.freight_value) AS total_revenue
FROM orders o

INNER JOIN customers c
ON o.customer_id = c.customer_id
INNER JOIN order_items oi
ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id)t
GROUP BY customer_type;

-- Tiempo promedio entre primera y segunda compra

SELECT 
	ROUND(AVG(DATEDIFF(second_order_date,first_order_date)),2) AS avg_days_between_orders
FROM(

SELECT 
	c.customer_unique_id,
    MIN(o.order_purchase_timestamp) AS first_order_date,
    MAX(o.order_purchase_timestamp) AS second_order_date
FROM orders o
INNER JOIN customers c
	ON o.customer_id=c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT o.order_id)>1
)t;

-- Categoría con mas repeat
-- Donde el repeat genera mas revenue
-- Donde casi no existe
SELECT   
    t.product_category_name,
    COUNT(DISTINCT t.customer_unique_id) AS total_customers,
    SUM(CASE WHEN t.order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(
        SUM(CASE WHEN t.order_count > 1 THEN 1 ELSE 0 END) 
        * 100.0 / COUNT(DISTINCT t.customer_unique_id),
        2
    ) AS repeat_rate_percentage
FROM (
    SELECT 
        c.customer_unique_id,
        p.product_category_name,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, p.product_category_name
) t
GROUP BY t.product_category_name
HAVING COUNT(DISTINCT t.customer_unique_id)>=500
ORDER BY repeat_rate_percentage DESC;

-- La categoría Electrodomésticos presenta un repeat rate significativamente superior al promedio (7.27% vs 3%), lo que sugiere potencial estratégico en campañas de cross-selling y retención focalizada.
    
-- Revenue total y ticket promedio para electrodomesticos

SELECT 
	p.product_category_name,
    SUM(oi.price+oi.freight_value) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price+oi.freight_value)/COUNT(DISTINCT o.order_id),2) AS avg_order_value
FROM orders o
INNER JOIN order_items oi
	ON o.order_id = oi.order_id
INNER JOIN products p
	ON p.product_id = oi.product_id
WHERE o.order_status = 'delivered' AND p.product_category_name LIKE '%eletro%'
GROUP BY p.product_category_name

-- Crear tabla product_category_name_translation

CREATE TABLE product_category_name_translation (
	product_category_name VARCHAR(255) PRIMARY KEY,
    product_category_name_english VARCHAR (255)
);

-- Cargamos datos a tabla product_category_name
SET GLOBAL local_infile = 1
SHOW VARIABLES LIKE 'local_infile';
LOAD DATA LOCAL INFILE 'C:/Users/johan/OneDrive/Documentos/Documentos Johan/CURSOS Y DIPLOMADOS/Portafolio/E-Commerce/product_category_name_translation.csv'
INTO TABLE product_category_name_translation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- Crear tabla order_views

CREATE TABLE order_reviews (
	review_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- Cargamos datos a la tabla order_reviews

LOAD DATA LOCAL INFILE 'C:/Users/johan/OneDrive/Documentos/Documentos Johan/CURSOS Y DIPLOMADOS/Portafolio/E-Commerce/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE  1 ROWS;

SELECT * FROM order_reviews

-- Crear tabla geolocalización 
CREATE TABLE geolocation (
	geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL (10,8),
    geolocation_lng DECIMAL(11,8),
    geolocation_city VARCHAR(255),
    geolocation_state VARCHAR (10)
);

-- Cargamos datos a la tabla geolocation
LOAD DATA LOCAL INFILE 'C:/Users/johan/OneDrive/Documentos/Documentos Johan/CURSOS Y DIPLOMADOS/Portafolio/E-Commerce/olist_geolocation_dataset.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE  1 ROWS;

select * from geolocation;

show databases


    
