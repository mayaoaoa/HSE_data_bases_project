-- 3: триггеры и функции

-- 1. Функции – минимум 2 функции
-- Минимум 2 пользовательская функция;
-- Функция должна принимать параметры и возвращать результат;
-- Функция может использоваться для расчёта вычисляемых полей или вспомогательных значений, применяемых в запросах, CTE или представлениях

-- функция 1: расчет итоговой цены билета со скидками
SET search_path TO aviation;
CREATE OR REPLACE FUNCTION calculate_final_price(
    base_price DECIMAL,
    passenger_category passenger_category,
    birth_date DATE
) RETURNS DECIMAL AS $$
DECLARE
    final_price DECIMAL;
BEGIN
    final_price := base_price;
    
    CASE passenger_category
        WHEN 'STUDENT' THEN final_price := final_price * 0.8;    -- 20%
        WHEN 'CHILD' THEN final_price := final_price * 0.5;      -- 50%
        WHEN 'BENEFICIARY' THEN final_price := final_price * 0.3; -- 70%
        ELSE NULL; 
    END CASE;
    
    -- дополнительная скидка для пассажиров старше 60 лет
    IF EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) >= 60 THEN
        final_price := final_price * 0.85; -- 15%
    END IF;
    
    RETURN ROUND(final_price, 2);
END;
$$ LANGUAGE plpgsql;


-- пример расчета
SET search_path TO aviation;
SELECT calculate_final_price(10000, 'STUDENT', '2005-03-10');    -- 8000
SELECT calculate_final_price(10000, 'CHILD', '2015-06-18');      -- 5000  
SELECT calculate_final_price(10000, 'ADULT', '1972-07-01');      -- 8500
SELECT calculate_final_price(10000, 'BENEFICIARY', '1942-12-12'); -- 2550 (70% + 15%)

-- пример использования
SET search_path TO aviation;
SELECT 
    p.last_name,
    p.birth_date,
    p.category,
    a.price AS base_price,
    calculate_final_price(a.price, p.category, p.birth_date) AS final_price
FROM passengers p
JOIN tickets t ON p.passenger_id = t.passenger_id
JOIN aircraft_structure a ON t.seat_id = a.seat_id;


-- функция 2: покупка билета по номеру рейса и месту (вместо seat_id) и автоматическое формирвоание ticket_number (номер рейса + дата слитно + номер места)
SET search_path TO aviation;
CREATE OR REPLACE FUNCTION buy_ticket(
    p_flight_number VARCHAR(20),
    p_departure_date DATE,
    p_seat_number VARCHAR(3),
    p_passenger_id INTEGER
) RETURNS TABLE (
    ticket_number VARCHAR(50),
    final_price DECIMAL(10,2),
    message TEXT
) AS $$
DECLARE
    v_flight_id INTEGER;
    v_seat_id INTEGER;
    v_base_price DECIMAL;
    v_departure_time TIMESTAMP;
    v_category passenger_category;
    v_birth_date DATE;
    v_final_price DECIMAL;
    v_ticket_number VARCHAR(50);
BEGIN
    SELECT f.flight_id, f.departure_time 
    INTO v_flight_id, v_departure_time
    FROM flights f
    WHERE f.flight_number = p_flight_number
        AND DATE(f.departure_time) = p_departure_date
        AND f.status = 'SCHEDULED'
        AND f.departure_time > CURRENT_TIMESTAMP;
    
    IF v_flight_id IS NULL THEN
        RETURN QUERY SELECT 
            NULL::VARCHAR(50),
            NULL::DECIMAL,
            'Ошибка: рейс не найден, завершен или уже вылетел';
        RETURN;
    END IF;
    
    SELECT a.seat_id, a.price 
    INTO v_seat_id, v_base_price
    FROM aircraft_structure a
    WHERE a.flight_id = v_flight_id 
        AND a.seat_number = p_seat_number
        AND a.status = 'AVAILABLE';
    
    IF v_seat_id IS NULL THEN
        RETURN QUERY SELECT 
            NULL::VARCHAR(50),
            NULL::DECIMAL,
            'Ошибка: место не найдено или занято';
        RETURN;
    END IF;
    
    -- данные пассажира для скидки
    SELECT category, birth_date 
    INTO v_category, v_birth_date
    FROM passengers 
    WHERE passenger_id = p_passenger_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT 
            NULL::VARCHAR(50),
            NULL::DECIMAL,
            'Ошибка: пассажир не найден';
        RETURN;
    END IF;
    
    v_final_price := calculate_final_price(v_base_price, v_category, v_birth_date);
    
    v_ticket_number := p_flight_number || '-' || TO_CHAR(v_departure_time, 'YYYYMMDD') || '-' || p_seat_number;
    
    INSERT INTO tickets (ticket_number, passenger_id, flight_id, seat_id, status)
    VALUES (v_ticket_number, p_passenger_id, v_flight_id, v_seat_id, 'PURCHASED')
    RETURNING tickets.ticket_number INTO v_ticket_number;
    
    RETURN QUERY SELECT 
        v_ticket_number,
        v_final_price,
        'Билет успешно куплен!';
    
EXCEPTION
    WHEN others THEN
        RETURN QUERY SELECT 
            NULL::VARCHAR(50),
            NULL::DECIMAL,
            'Ошибка покупки: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- пример использования
SET search_path TO aviation;
SELECT * FROM buy_ticket('U6-789', '2025-12-18', '3B', 5);

-- просмотр всех купленных билетов
SET search_path TO aviation;
SELECT 
    t.ticket_number,
    p.last_name,
    f.flight_number,
    a.seat_number,
    t.status
FROM tickets t
JOIN passengers p ON t.passenger_id = p.passenger_id
JOIN flights f ON t.flight_id = f.flight_id
JOIN aircraft_structure a ON t.seat_id = a.seat_id
ORDER BY t.ticket_id DESC;


-- 2. Триггеры – минимум 2 триггера
-- Необходимо реализовать триггеры, реагирующие на разные события: INSERT, UPDATE или DELETE;
-- Триггер должен выполнять осмысленное действие (например, поддерживать целостность данных, обновлять связанные записи, рассчитывать значения)

-- триггер 1: невозможность покупки билетов на завершенные/в полёте/отмененные рейсы
SET search_path TO aviation;
CREATE OR REPLACE FUNCTION check_flight_status()
RETURNS TRIGGER AS $$
DECLARE
    v_flight_status flight_status;
    v_departure_time TIMESTAMP;
BEGIN
    SELECT status, departure_time INTO v_flight_status, v_departure_time
    FROM flights 
    WHERE flight_id = NEW.flight_id;
    
    IF v_flight_status IN ('COMPLETED', 'CANCELLED', 'IN_PROGRESS') THEN
        RAISE EXCEPTION 'Нельзя купить билет на % рейс', 
            CASE v_flight_status 
                WHEN 'COMPLETED' THEN 'завершенный' 
                WHEN 'CANCELLED' THEN 'отмененный' 
                WHEN 'IN_PROGRESS' THEN 'находящийся в полёте' 
            END;
    END IF;
    
    IF v_departure_time < CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'Нельзя купить билет на рейс, который уже вылетел';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_flight_status_trigger BEFORE INSERT OR UPDATE ON tickets
FOR EACH ROW EXECUTE FUNCTION check_flight_status();

-- тест триггера
SET search_path TO aviation;
UPDATE flights 
SET status = 'CANCELLED' 
WHERE flight_number = 'S7-2105' AND DATE(departure_time) = '2025-12-16';

-- попытка купить билет
INSERT INTO tickets (ticket_number, passenger_id, flight_id, seat_id, status) 
VALUES ('TEST-CANCELLED-001', 2,  2, 16, 'PURCHASED'); -- seat_id 18B



-- триггер 2: автоматическое применение скидки при покупке билета
SET search_path TO aviation;
CREATE OR REPLACE FUNCTION apply_discount()
RETURNS TRIGGER AS $$
DECLARE
    v_base_price DECIMAL;
    v_final_price DECIMAL;
    v_category passenger_category;
    v_birth_date DATE;
BEGIN
    SELECT price INTO v_base_price
    FROM aircraft_structure 
    WHERE seat_id = NEW.seat_id;
    
    SELECT category, birth_date
    INTO v_category, v_birth_date
    FROM passengers 
    WHERE passenger_id = NEW.passenger_id;
    
    v_final_price := calculate_final_price(v_base_price, v_category, v_birth_date);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER apply_discount_trigger AFTER INSERT ON tickets
FOR EACH ROW WHEN (NEW.status = 'PURCHASED') EXECUTE FUNCTION apply_discount();

-- тест триггера

-- просто взрослый
SET search_path TO aviation;
INSERT INTO aircraft_structure (flight_id, seat_number, class, status, price) VALUES
(5, '14E', 'ECONOMY', 'AVAILABLE', 12000);
SELECT * FROM buy_ticket('DP-101', '2025-12-19', '14E', 6);

-- льготник + возраст
SET search_path TO aviation;
INSERT INTO aircraft_structure (flight_id, seat_number, class, status, price) VALUES
(5, '14B', 'ECONOMY', 'AVAILABLE', 12000);
SELECT * FROM buy_ticket('DP-101', '2025-12-19', '14B', 5);
