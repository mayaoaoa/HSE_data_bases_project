-- 2: SQL-запросы

-- 1. Простые выборки (SELECT) – минимум 2 запроса
--     использование фильтрации (WHERE);
--     использование сортировки (ORDER BY);
--     использование  ограничения количества строк (LIMIT, OFFSET)

-- 5-му пассажиру, купившему билет через нашу систему будет подарено бонусами 55% стоимости его билета
SET search_path TO aviation;
SELECT 
    t.ticket_id,
    p.last_name || ' ' || p.first_name AS passenger,
    p.passport,
    t.ticket_number,
    '55% кешбека бонусами!' AS discount_info
FROM aviation.tickets t
JOIN aviation.passengers p ON t.passenger_id = p.passenger_id
WHERE t.status = 'PURCHASED'
ORDER BY t.ticket_id
LIMIT 1 OFFSET 4;

-- 2 самых старших пассажира мужского пола, отсортированных по возрасту
SET search_path TO aviation;
SELECT 
    last_name || ' ' || first_name AS passenger,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) AS age
FROM passengers
WHERE gender = 'MALE'
ORDER BY birth_date ASC
LIMIT 2;


-- 2. Соединения таблиц (JOIN) – минимум 3 запроса
--     демонстрация объединения данных из двух и более таблиц;
--     использование разных типов JOIN (INNER, LEFT/RIGHT

-- информация обо всех купленных билетах
SET search_path TO aviation;
SELECT 
    t.ticket_number,
    p.last_name || ' ' || p.first_name AS passenger,
    f.flight_number,
    dep.city || ' (' || dep.IATA || ')' AS departure,
    f.departure_time,
    arr.city || ' (' || arr.IATA || ')' AS arrival,
    f.arrival_time,
    a.seat_number,
    a.class,
    a.price
FROM tickets t
    INNER JOIN passengers p ON t.passenger_id = p.passenger_id
    INNER JOIN flights f ON t.flight_id = f.flight_id
    INNER JOIN airports dep ON f.departure_airport_id = dep.airport_id
    INNER JOIN airports arr ON f.arrival_airport_id = arr.airport_id
    INNER JOIN aircraft_structure a ON t.seat_id = a.seat_id
WHERE t.status = 'PURCHASED'
ORDER BY f.departure_time;

-- все самолеты с информацией о рейсах, на которые они назначены (включая самолеты без рейсов)
SET search_path TO aviation;
SELECT 
    ap.brand || ' ' || ap.model AS airplane,
    ap.airline,
    ap.capacity,
    COUNT(f.flight_id) AS scheduled_flights,
    STRING_AGG(f.flight_number, ', ') AS flight_numbers
FROM airplanes ap
    LEFT JOIN flights f ON ap.airplane_id = f.airplane_id 
        AND f.status = 'SCHEDULED'
        AND f.departure_time >= CURRENT_DATE
GROUP BY ap.airplane_id
ORDER BY scheduled_flights DESC, airplane;

-- все пассажиры со всеми их билетами (включая тех, у кого нет билетов)
SET search_path TO aviation;
SELECT 
    p.passenger_id,
    p.last_name || ' ' || p.first_name AS passenger,
    p.passport,
    STRING_AGG(t.ticket_number, ', ') AS tickets
FROM tickets t
    RIGHT JOIN passengers p ON t.passenger_id = p.passenger_id
    LEFT JOIN flights f ON t.flight_id = f.flight_id
GROUP BY p.passenger_id
ORDER BY passenger_id;


-- 3. Группировка и агрегирование – минимум 2 запроса
--     использование SUM, COUNT, AVG, MIN, MAX и др.;
--     фильтрация агрегированных результатов (HAVING)

-- топ 3 самых дешевых цен билетов на рейсы в ближайшую неделю с количеством билетов по каждой цене
SET search_path TO aviation;
SELECT 
    a.price,
    COUNT(*) AS available_tickets_count,
    STRING_AGG(DISTINCT f.flight_number, ', ') AS flight_number,
    STRING_AGG(DISTINCT dep.city || ' (' || dep.IATA || ')' || ' → ' || arr.city || ' (' || arr.IATA || ')', ', ') AS route,
    MIN(f.departure_time) AS nearest_departure_time
FROM flights f
    JOIN aircraft_structure a ON f.flight_id = a.flight_id
    JOIN airports dep ON f.departure_airport_id = dep.airport_id
    JOIN airports arr ON f.arrival_airport_id = arr.airport_id
WHERE 
    a.status = 'AVAILABLE'
    AND f.departure_time BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
    AND f.status = 'SCHEDULED'
GROUP BY a.price
ORDER BY a.price ASC
LIMIT 3;

-- топ 3 самых дешевых цен направлений на рейсы в ближайшую неделю с количеством билетов по каждой цене
SET search_path TO aviation;
SELECT 
    a.price,
    COUNT(*) AS available_tickets_count,
    f.flight_number,
    dep.city || ' (' || dep.IATA || ')' || ' → ' || arr.city || ' (' || arr.IATA || ')' AS route,
    f.departure_time
FROM flights f
    JOIN aircraft_structure a ON f.flight_id = a.flight_id
    JOIN airports dep ON f.departure_airport_id = dep.airport_id
    JOIN airports arr ON f.arrival_airport_id = arr.airport_id
WHERE 
    a.status = 'AVAILABLE'
    AND f.departure_time BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
    AND f.status = 'SCHEDULED'
GROUP BY a.price, f.flight_id, f.flight_number, dep.city, dep.IATA, arr.city, arr.IATA, f.departure_time
ORDER BY a.price ASC, f.departure_time
LIMIT 3;

-- вывод авиакомпаний и средней стоимости билетов у них по классам, где средняя цена выше 50000 рублей
SET search_path TO aviation;
SELECT 
    ap.airline,
    a.class,
    ROUND(AVG(a.price), 2) AS avg_price
FROM aircraft_structure a
    JOIN flights f ON a.flight_id = f.flight_id
    JOIN airplanes ap ON f.airplane_id = ap.airplane_id
GROUP BY ap.airline, a.class
HAVING AVG(a.price) > 50000
ORDER BY ap.airline, avg_price DESC;


-- 4. Оконные функции – минимум 2 запроса
--     использование аналитических функций (ROW_NUMBER, RANK, SUM/COUNT OVER и др.);
--     разделение на группы и упорядочивание

-- самая дорогая и средняя цена на билет в каждом рейсе с разбивкой по классам обслуживания
SET search_path TO aviation;
WITH flight_class_stats AS (
    SELECT 
        f.flight_id,
        f.flight_number,
        a.class,
        dep.city || ' (' || dep.IATA || ')' || ' → ' || arr.city || ' (' || arr.IATA || ')' AS route,
        MAX(a.price) AS max_price_in_class,
        ROUND(AVG(a.price), 2) AS avg_price_in_class
    FROM flights f
        JOIN aircraft_structure a ON f.flight_id = a.flight_id
        JOIN airports dep ON f.departure_airport_id = dep.airport_id
        JOIN airports arr ON f.arrival_airport_id = arr.airport_id
    GROUP BY f.flight_id, f.flight_number, a.class, dep.city, dep.IATA, arr.city, arr.IATA
)
SELECT 
    flight_number,
    class,
    route,
    avg_price_in_class,
    MAX(max_price_in_class) OVER (PARTITION BY flight_id) AS max_price_in_flight
FROM flight_class_stats
ORDER BY flight_number, avg_price_in_class DESC;

-- рейтинг пассажиров по сумме потраченных денег
SET search_path TO aviation;
SELECT 
    p.last_name || ' ' || p.first_name AS passenger,
    COUNT(t.ticket_id) AS tickets_count,
    COALESCE(SUM(a.price), 0) AS total_spent,
    ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(a.price), 0) DESC),
    RANK() OVER (ORDER BY COALESCE(SUM(a.price), 0) DESC),
    ROUND(COALESCE(SUM(a.price), 0) * 100.0 / NULLIF(SUM(COALESCE(SUM(a.price), 0)) OVER (), 0), 1) AS percent 
    -- доля от общей суммы трат в группе
FROM passengers p
    LEFT JOIN tickets t ON p.passenger_id = t.passenger_id AND t.status = 'PURCHASED'
    LEFT JOIN aircraft_structure a ON t.seat_id = a.seat_id
GROUP BY p.passenger_id
HAVING COALESCE(SUM(a.price), 0) > 0  -- только те, кто что-то потратил
ORDER BY total_spent DESC;


-- 5. CTE (WITH) – минимум 1 запрос
--     построение временных результирующих наборов;
--     возможность использования многоуровневых CTE

-- поиск самых дорогих билетов в рейсе
SET search_path TO aviation;
WITH 
expensive_seats AS (
    SELECT 
        flight_id,
        MAX(price) AS max_price
    FROM aircraft_structure
    GROUP BY flight_id
),
flight_info AS (
    SELECT 
        f.flight_number,
        es.max_price,
        dep.city || ' (' || dep.IATA || ')' || ' → ' || arr.city || ' (' || arr.IATA || ')' AS route
    FROM expensive_seats es
        JOIN flights f ON es.flight_id = f.flight_id
        JOIN airports dep ON f.departure_airport_id = dep.airport_id
        JOIN airports arr ON f.arrival_airport_id = arr.airport_id
)
SELECT 
    flight_number,
    route,
    max_price
FROM flight_info
ORDER BY max_price DESC;


-- 6. Представления (VIEW) – минимум 2 представления
--     формирование сводных или отчетных данных;
--     использование разных типов представлений

-- простое: доступные места на ближайшие рейсы (2 дня)
SET search_path TO aviation;
CREATE OR REPLACE VIEW available_tickets AS
SELECT 
    f.flight_number,
    f.departure_time::date AS flight_date,
    dep.city || ' (' || dep.IATA || ')' || ' → ' || arr.city || ' (' || arr.IATA || ')' AS route,
    a.seat_number,
    a.class,
    a.price,
    f.status AS flight_status
FROM flights f
    JOIN aircraft_structure a ON f.flight_id = a.flight_id
    JOIN airports dep ON f.departure_airport_id = dep.airport_id
    JOIN airports arr ON f.arrival_airport_id = arr.airport_id
WHERE a.status = 'AVAILABLE'
    AND f.departure_time >= CURRENT_DATE
    AND f.departure_time <= CURRENT_DATE + INTERVAL '2 days'
    AND f.status = 'SCHEDULED'
ORDER BY f.departure_time, a.price DESC;

-- материализованное: статистика по авиакомпаниям
SET search_path TO aviation;
CREATE MATERIALIZED VIEW airline_stats AS
SELECT 
    airline,
    COUNT(DISTINCT airplane_id) AS planes_count,
    SUM(capacity) AS total_capacity,
    ROUND(AVG(capacity),2) AS avg_capacity
FROM airplanes
GROUP BY airline;

-- добавление данных
-- SET search_path TO aviation;
-- INSERT INTO airplanes (brand, model, airline, capacity) VALUES
-- ('Airbus', 'A350', 'Аэрофлот', 325);
-- REFRESH MATERIALIZED VIEW airline_stats;