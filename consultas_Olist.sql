-- ==========================================
-- 1. Analisis Financiero
-- ==========================================

-- Distribucion y Ticket Promedio por Metodo de Pago

SELECT payment_type,
    COUNT(order_id) as total_orders,
    ROUND(SUM(payment_value)::numeric,2) as total_income,
    ROUND(AVG(payment_value)::numeric,2) as avg_ticket,
    ROUND(COUNT(order_id)::numeric 
	/ (SELECT COUNT(order_id) FROM order_payments) * 100,2) as pct_orders

FROM order_payments
GROUP BY payment_type
ORDER BY total_income DESC;

-- Analisis del Uso de Cuotas

SELECT payment_installments as total_cuotas,
    COUNT(order_id) as total_orders,
    ROUND(SUM(payment_value)::numeric, 2) AS total_generado,
    ROUND(AVG(payment_value)::numeric, 2) AS ticket_promedio

FROM order_payments
WHERE payment_type = 'credit_card'
GROUP BY payment_installments
ORDER BY total_generado DESC;

-- Evolucion mensual

SELECT 
    TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS mes,
    COUNT(DISTINCT o.order_id) AS total_pedidos,
    ROUND(SUM(op.payment_value)::numeric, 2) AS ingresos_totales

FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM')
ORDER BY ingresos_totales DESC;

-- Ventas por dia de la semana

SELECT 
    TRIM(TO_CHAR(order_purchase_timestamp, 'Day')) AS dia_semana,
    EXTRACT(ISODOW FROM order_purchase_timestamp) AS num_dia,
    COUNT(order_id) AS total_pedidos

FROM orders
WHERE order_status = 'delivered'
GROUP BY dia_semana, num_dia
ORDER BY num_dia ASC;

-- Comportamiento por hora

SELECT 
    EXTRACT(HOUR FROM order_purchase_timestamp) AS hora_del_dia,
    COUNT(order_id) AS total_pedidos
FROM orders
WHERE order_status = 'delivered'
GROUP BY EXTRACT(HOUR FROM order_purchase_timestamp)
ORDER BY hora_del_dia ASC;

-- ==========================================
-- 2. Analisis Geografico
-- ==========================================

-- Ingresos, Volumen y Ticket Promedio por Estado

SELECT c.customer_state,
    COUNT(DISTINCT o.order_id) as total_pedidos,
    ROUND(SUM(op.payment_value)::numeric, 2) as ingresos_totales,
    ROUND(SUM(op.payment_value)::numeric / COUNT(DISTINCT o.order_id), 2) as avg_ticket

FROM customers c

JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments op ON o.order_id = op.order_id

WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY ingresos_totales DESC
LIMIT 10;

-- Costo Promedio de Envio (Flete) por Estado

SELECT 
    c.customer_state,
    COUNT(oi.order_item_id) AS total_productos_enviados,
    ROUND(AVG(oi.freight_value)::numeric, 2) AS costo_envio_promedio,
    ROUND(MAX(oi.freight_value)::numeric, 2) AS envio_mas_caro

FROM customers c

JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_productos_enviados DESC;

-- ==========================================
-- 3. Analisis de Rendimiento y Rentabilidad
-- ==========================================

-- Top Categorías por Ingresos y Volumen

SELECT 
	p.product_category_name,
	COUNT(o.order_id) as total_orders,
	ROUND(SUM(oi.price)::numeric,2) as ingreso_total_categoria	

FROM products p

JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY ingreso_total_categoria DESC
LIMIT 10;

-- Distribución de las reseñas

SELECT 
    review_score,
    COUNT(review_id) AS total_reseñas,
    ROUND((COUNT(review_id)::numeric / (SELECT COUNT(review_id) FROM order_reviews)) * 100, 2) AS porcentaje

FROM order_reviews

GROUP BY review_score
ORDER BY review_score DESC;

-- Impacto de las Demoras en la Satisfacción

SELECT 
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Atrasado'
        ELSE 'A tiempo / Adelantado'
    END AS estado_entrega,
    COUNT(r.review_id) AS total_reseñas,
    ROUND(AVG(r.review_score)::numeric, 2) AS puntaje_promedio

FROM orders o

JOIN order_reviews r ON o.order_id = r.order_id

WHERE 
    o.order_status = 'delivered' 
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY estado_entrega;

