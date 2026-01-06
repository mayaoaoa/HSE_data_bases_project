-- 1: создание таблиц, ограничений и триггеров

DROP SCHEMA IF EXISTS aviation CASCADE;
CREATE SCHEMA aviation;

SET search_path TO aviation;


-- создание ENUM
CREATE TYPE passenger_gender AS ENUM ('MALE', 'FEMALE');
CREATE TYPE passenger_category AS ENUM ('ADULT', 'CHILD', 'STUDENT', 'BENEFICIARY');
CREATE TYPE airline_type AS ENUM ('Аэрофлот', 'Россия', 'S7 Airlines', 'Победа', 'Utair', 'Уральские авиалинии');
CREATE TYPE flight_status AS ENUM ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');
CREATE TYPE seat_class AS ENUM ('ECONOMY','ECONOMY_PLUS', 'BUSINESS', 'FIRST');
CREATE TYPE seat_status AS ENUM ('AVAILABLE', 'BOOKED');
CREATE TYPE ticket_status AS ENUM ('PURCHASED', 'RETURNED', 'NO_SHOW');


-- пассажиры
CREATE TABLE passengers (
    passenger_id SERIAL PRIMARY KEY,
    last_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    birth_date DATE NOT NULL,
    gender passenger_gender NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    passport VARCHAR(11) NOT NULL, -- "xxxx xxxxxx"
    category passenger_category NOT NULL,

    CONSTRAINT birth_date_check CHECK (birth_date <= CURRENT_DATE),
    CONSTRAINT passenger_phone_check CHECK (phone ~ '^8[0-9]{10}$' OR phone ~ '^\+7[0-9]{10}$'),
    CONSTRAINT passenger_email_check CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT unique_passport UNIQUE (passport),
    CONSTRAINT passport_check CHECK (passport ~ '^[0-9]{4} [0-9]{6}$')
);


-- самолеты
CREATE TABLE airplanes (
    airplane_id SERIAL PRIMARY KEY,
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    airline airline_type NOT NULL,
    capacity INTEGER NOT NULL CHECK (capacity > 0)
);


-- аэропорты
CREATE TABLE airports (
    airport_id SERIAL PRIMARY KEY,
    airport_name VARCHAR(200) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    IATA VARCHAR(3) UNIQUE NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    
    CONSTRAINT iata_check CHECK (IATA ~ '^[A-Z]{3}$'),
    CONSTRAINT airport_phone_check CHECK (phone IS NULL OR phone ~ '^8[0-9]{10}$' OR phone ~ '^\+7[0-9]{10}$'),
    CONSTRAINT airport_email_check CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);


-- рейсы
CREATE TABLE flights (
    flight_id SERIAL PRIMARY KEY,
    flight_number VARCHAR(20) NOT NULL,
    departure_time TIMESTAMP NOT NULL,
    arrival_time TIMESTAMP NOT NULL,
    departure_airport_id INTEGER NOT NULL REFERENCES airports(airport_id),
    arrival_airport_id INTEGER NOT NULL REFERENCES airports(airport_id),
    airplane_id INTEGER NOT NULL REFERENCES airplanes(airplane_id),
    status flight_status NOT NULL DEFAULT 'SCHEDULED',

    CONSTRAINT arrival_departure_check CHECK (arrival_time > departure_time),
    CONSTRAINT unique_flight_departure UNIQUE (flight_number, departure_time),
    CONSTRAINT different_airports_check CHECK (departure_airport_id != arrival_airport_id)
);


-- структура самолета
CREATE TABLE aircraft_structure (
    seat_id SERIAL PRIMARY KEY,
    flight_id INTEGER NOT NULL REFERENCES flights(flight_id) ON DELETE CASCADE,
    seat_number VARCHAR(3) NOT NULL,
    class seat_class NOT NULL,
    status seat_status NOT NULL DEFAULT 'AVAILABLE',
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    passenger_id INTEGER REFERENCES passengers(passenger_id) ON DELETE SET NULL,

    CONSTRAINT unique_seat UNIQUE (flight_id, seat_number),
    CONSTRAINT seat_number_check CHECK (seat_number ~ '^[1-9][0-9]*[A-K]$')
);


-- билеты
CREATE TABLE tickets (
    ticket_id SERIAL PRIMARY KEY,
    ticket_number VARCHAR(50) UNIQUE NOT NULL,
    passenger_id INTEGER NOT NULL REFERENCES passengers(passenger_id),
    flight_id INTEGER NOT NULL REFERENCES flights(flight_id),
    seat_id INTEGER NOT NULL REFERENCES aircraft_structure(seat_id),
    status ticket_status NOT NULL DEFAULT 'PURCHASED',

    CONSTRAINT unique_passenger_flight UNIQUE (passenger_id, flight_id)
);


-- триггер: проверка соответствия билета и рейса
CREATE FUNCTION ticket_check() RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT flight_id FROM aircraft_structure WHERE seat_id = NEW.seat_id) IS DISTINCT FROM NEW.flight_id THEN
        RAISE EXCEPTION 'Несоответствие билета и рейса';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ticket_check_trigger BEFORE INSERT OR UPDATE ON tickets 
FOR EACH ROW EXECUTE FUNCTION ticket_check();


-- триггер: проверка единственности продажи места на рейсе
CREATE FUNCTION check_availible_seat() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM tickets t
        JOIN aircraft_structure a ON t.seat_id = a.seat_id
        WHERE a.flight_id = (SELECT flight_id FROM aircraft_structure WHERE seat_id = NEW.seat_id)
        AND a.seat_id = NEW.seat_id
        AND t.status = 'PURCHASED'
        AND t.ticket_id != COALESCE(NEW.ticket_id, 0)
    ) THEN
        RAISE EXCEPTION 'На это место уже продан билет';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_availible_seat_trigger BEFORE INSERT OR UPDATE ON tickets 
FOR EACH ROW EXECUTE FUNCTION check_availible_seat();


-- триггер: при вставке билета он проставляет нужный passenger_id в aircraft_structure и меняет status на BOOKED
CREATE FUNCTION update_aircraft_structure() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM aircraft_structure 
        WHERE seat_id = NEW.seat_id 
        AND status = 'BOOKED'
    ) THEN
        RAISE EXCEPTION 'Место уже занято';
    END IF;
    
    UPDATE aircraft_structure
    SET 
        passenger_id = NEW.passenger_id,
        status = 'BOOKED'
    WHERE seat_id = NEW.seat_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_seat_status AFTER INSERT ON tickets 
FOR EACH ROW EXECUTE FUNCTION update_aircraft_structure();