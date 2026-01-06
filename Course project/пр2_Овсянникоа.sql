-- внесение данных

SET search_path TO aviation;

INSERT INTO airports (airport_name, city, country, IATA, phone, email) VALUES
('Пулково', 'Санкт-Петербург', 'Россия', 'LED', '+78123372222', 'info@pulkovo.ru'),
('Шереметьево', 'Москва', 'Россия', 'SVO', '+74957386060', 'info@svo.aero'),
('Домодедово', 'Москва', 'Россия', 'DME', '+74959338666', 'info@dme.ru'),
('Адлер', 'Сочи', 'Россия', 'AER', '+78622410101', 'info@sochi-airport.ru'),
('Кольцово', 'Екатеринбург', 'Россия', 'SVX', '+73432266868', 'info@koltsovo.ru'),
('Толмачёво', 'Новосибирск', 'Россия', 'OVB', '+73832308380', 'info@tolmachevo.ru'),
('Кневичи', 'Владивосток', 'Россия', 'VVO', '+74232266666', 'info@vvo.aero'),
('Аэропорт Пенза имени В. Г. Белинского', 'Пенза', 'Россия', 'PEZ', '+78412453900', 'info@penza.aero');

INSERT INTO airplanes (brand, model, airline, capacity) VALUES
('Airbus', 'A320-200', 'Аэрофлот', 158),
('Boeing', '737-800', 'S7 Airlines', 189),
('Boeing', '777-300', 'Аэрофлот', 402),
('Sukhoi', 'Superjet 100', 'Россия', 98),
('Airbus', 'A321', 'Победа', 230),
('Boeing', '737-500', 'Utair', 132),
('Airbus', 'A319', 'Уральские авиалинии', 144),
('Boeing', '767-300', 'S7 Airlines', 261),
('Embraer', 'E190', 'Utair', 114),
('Airbus', 'A320neo', 'Аэрофлот', 180);

INSERT INTO passengers (last_name, first_name, middle_name, birth_date, gender, phone, email, passport, category) VALUES
('Иванов', 'Иван', 'Иванович', '1990-05-15', 'MALE', '89151234567', 'ivanov@mail.ru', '4501 123456', 'ADULT'),
('Петрова', 'Мария', 'Сергеевна', '1985-08-22', 'FEMALE', '89167654321', 'petrova@gmail.com', '4502 654321', 'ADULT'),
('Сидоров', 'Алексей', 'Петрович', '2005-03-10', 'MALE', '89172345678', 'sidorov@yandex.ru', '4503 234567', 'STUDENT'),
('Козлова', 'Елена', 'Владимировна', '2015-11-30', 'FEMALE', '89183456789', NULL, '4504 345678', 'CHILD'),
('Васильев', 'Дмитрий', 'Александрович', '1950-07-18', 'MALE', '89194567890', 'vasiliev@mail.ru', '4505 456789', 'BENEFICIARY'),
('Смирнова', 'Ольга', 'Игоревна', '1992-12-05', 'FEMALE', '89205678901', 'smirnova@gmail.com', '4506 567890', 'ADULT'),
('Кузнецов', 'Сергей', 'Викторович', '1988-09-14', 'MALE', '89216789012', 'kuznetsov@yandex.ru', '4507 678901', 'ADULT'),
('Морозова', 'Анна', 'Дмитриевна', '2003-02-28', 'FEMALE', '89227890123', 'morozova@mail.ru', '4508 789012', 'STUDENT'),
('Новиков', 'Павел', 'Олегович', '2018-06-20', 'MALE', '89238901234', NULL, '4509 890123', 'CHILD'),
('Лебедева', 'Татьяна', 'Сергеевна', '1965-04-25', 'FEMALE', '89249012345', 'lebedeva@gmail.com', '4510 901234', 'ADULT');

INSERT INTO flights (flight_number, departure_time, arrival_time, departure_airport_id, arrival_airport_id, airplane_id, status) VALUES
('SU-1441', '2025-12-15 08:00:00', '2025-12-15 10:30:00', 1, 2, 1, 'SCHEDULED'),  -- LED -> SVO
('S7-2105', '2025-12-16 14:20:00', '2025-12-16 19:45:00', 2, 6, 2, 'SCHEDULED'),  -- SVO -> OVB
('UT-432', '2025-12-17 11:10:00', '2025-12-17 14:30:00', 3, 4, 6, 'SCHEDULED'),  -- DME -> AER
('U6-789', '2025-12-18 16:45:00', '2025-12-18 21:15:00', 5, 7, 7, 'SCHEDULED'),  -- SVX -> VVO
('DP-101', '2025-12-19 09:30:00', '2025-12-19 10:45:00', 2, 1, 5, 'SCHEDULED'),  -- SVO -> LED
('SU-2567', '2025-12-20 13:15:00', '2025-12-20 18:40:00', 1, 7, 3, 'SCHEDULED'),  -- LED -> VVO
('S7-3050', '2025-12-21 07:45:00', '2025-12-21 09:20:00', 6, 2, 8, 'SCHEDULED'),  -- OVB -> SVO
('UT-567', '2025-12-22 18:30:00', '2025-12-22 20:05:00', 4, 3, 9, 'IN_PROGRESS'),  -- AER -> DME
('FV-6345', '2025-12-23 12:00:00', '2025-12-23 15:30:00', 7, 5, 4, 'SCHEDULED'),  -- VVO -> SVX
('U6-889', '2025-12-24 10:15:00', '2025-12-24 11:45:00', 8, 2, 4, 'SCHEDULED');  -- PEZ -> SVO

INSERT INTO aircraft_structure (flight_id, seat_number, class, status, price) VALUES
-- рейс 1 (LED -> SVO) - seat_id: 1-10
(1, '1A', 'FIRST', 'AVAILABLE', 75000.00),
(1, '1B', 'FIRST', 'AVAILABLE', 75000.00),
(1, '10C', 'BUSINESS', 'AVAILABLE', 38000.00),
(1, '10D', 'BUSINESS', 'AVAILABLE', 38000.00),
(1, '15A', 'ECONOMY_PLUS', 'AVAILABLE', 22000.00),
(1, '15B', 'ECONOMY_PLUS', 'AVAILABLE', 22000.00),
(1, '20C', 'ECONOMY', 'AVAILABLE', 8000.00),
(1, '20D', 'ECONOMY', 'AVAILABLE', 8000.00),
(1, '25E', 'ECONOMY', 'AVAILABLE', 7000.00),
(1, '25F', 'ECONOMY', 'AVAILABLE', 9000.00),

-- рейс 2 (SVO -> OVB) - seat_id: 11-16
(2, '1A', 'FIRST', 'AVAILABLE', 105000.00),
(2, '1B', 'FIRST', 'AVAILABLE', 95000.00),
(2, '12C', 'BUSINESS', 'AVAILABLE', 62000.00),
(2, '12D', 'BUSINESS', 'AVAILABLE', 62000.00),
(2, '18A', 'ECONOMY_PLUS', 'AVAILABLE', 35000.00),
(2, '18B', 'ECONOMY_PLUS', 'AVAILABLE', 35000.00),

-- рейс 3 (DME -> AER) - seat_id: 17-20
(3, '2A', 'BUSINESS', 'AVAILABLE', 46000.00),
(3, '2B', 'BUSINESS', 'AVAILABLE', 46000.00),
(3, '14C', 'ECONOMY_PLUS', 'AVAILABLE', 17000.00),
(3, '14D', 'ECONOMY_PLUS', 'AVAILABLE', 17000.00),

-- рейс 4 (SVX -> VVO) - seat_id: 21-22
(4, '3A', 'FIRST', 'AVAILABLE', 100000.00),
(4, '3B', 'FIRST', 'AVAILABLE', 100000.00),

-- рейс 5 (SVO -> LED) - seat_id: 23-24
(5, '5A', 'ECONOMY', 'AVAILABLE', 7000.00),
(5, '5B', 'ECONOMY', 'AVAILABLE', 7000.00);

-- билет 1: место 1A на рейсе 1 имеет seat_id = 1
INSERT INTO tickets (ticket_number, passenger_id, flight_id, seat_id, status) VALUES
('SU-1441-20251215-1A', 1, 1, 1, 'PURCHASED');  -- Иванов покупает место 1A на рейс 1

-- билет 2: место 1A на рейсе 2 имеет seat_id = 11
INSERT INTO tickets (ticket_number, passenger_id, flight_id, seat_id, status) VALUES
('S7-2105-20251216-1A', 2, 2, 11, 'PURCHASED');  -- Петрова покупает место 1A на рейс 2

-- билет 3: место 12C на рейсе 2 имеет seat_id = 13
INSERT INTO tickets (ticket_number, passenger_id, flight_id, seat_id, status) VALUES
('S7-2105-20251216-12C', 3, 2, 13, 'PURCHASED');  -- Сидоров покупает место 12C на рейс 2

-- билет 4: пместо 18A на рейсе 2 имеет seat_id = 15
INSERT INTO tickets (ticket_number, passenger_id, flight_id, seat_id, status) VALUES
('S7-2105-20251216-18A', 4, 2, 15, 'PURCHASED');  -- Козлова покупает место 18A на рейс 2

-- билет 5: место 2A на рейсе 3 имеет seat_id = 17
INSERT INTO tickets (ticket_number, passenger_id, flight_id, seat_id, status) VALUES
('UT-432-20251217-2A', 5, 3, 17, 'PURCHASED');  -- Васильев покупает место 2A на рейс 3

-- билет 6: место 3A на рейсе 4 имеет seat_id = 21
INSERT INTO tickets (ticket_number, passenger_id, flight_id, seat_id, status) VALUES
('U6-789-20251218-3A', 6, 4, 21, 'PURCHASED');  -- Смирнова покупает место 3A на рейс 4


-- проверка работы триггеров и ограничений

-- 1. попытка покупки второго билета на тот же рейс (ограничение unique_passenger_flight)
-- SET search_path TO aviation;
-- INSERT INTO tickets (ticket_number, passenger_id, flight_id, seat_id, status) VALUES
-- ('test1', 1, 1, 2, 'PURCHASED');  -- error: Иванов уже купил билет на рейс 1

-- 2. попытка покупки билета на уже занятое место (триггер check_duplicate_seat)
-- SET search_path TO aviation;
-- INSERT INTO tickets (ticket_number, passenger_id, flight_id, seat_id, status) VALUES
-- ('test2', 7, 2, 11, 'PURCHASED');  -- error: место 1A на рейсе 2 уже занято Петровой

-- 3. попытка создания рейса с одинаковыми аэропортами (ограничение different_airports_check)
-- SET search_path TO aviation;
-- INSERT INTO flights (flight_number, departure_time, arrival_time, departure_airport_id, arrival_airport_id, airplane_id, status) VALUES
-- ('test3', '2024-03-25 10:00:00', '2024-03-25 12:00:00', 1, 1, 1, 'SCHEDULED');  -- error: одинаковые аэропорты

-- 4. проверка работы (триггер update_aircraft_structure)
-- SET search_path TO aviation;
-- INSERT INTO tickets (ticket_number, passenger_id, flight_id, seat_id, status) VALUES
-- ('DP-101-20251219-5A', 7, 5, 23, 'PURCHASED');  -- Кузнецов покупает место 5A на рейс 5

-- SELECT a.seat_number, a.status, a.passenger_id, p.last_name, p.first_name
-- FROM aircraft_structure a 
--     LEFT JOIN passengers p ON a.passenger_id = p.passenger_id
-- WHERE a.flight_id = 5;
