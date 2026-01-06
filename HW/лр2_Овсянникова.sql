DROP SCHEMA IF EXISTS LR_2 CASCADE;
CREATE SCHEMA LR_2;

SET search_path TO LR_2;

-- создание таблиц
DROP TABLE IF EXISTS Book;
CREATE TABLE Book
(
    isbn VARCHAR(50) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    publication_year INT NOT NULL, -- год первого издания
    publication_office VARCHAR(255) NOT NULL,
    genre VARCHAR(255) NOT NULL
);  

DROP TABLE IF EXISTS Author;
CREATE TABLE Author
(
    id INT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL
);

DROP TABLE IF EXISTS Book_x_Author; -- для связи M:N
CREATE TABLE Book_x_Author (
    isbn VARCHAR(50) NOT NULL,
    author_id INT NOT NULL,
    PRIMARY KEY (isbn, author_id),
    FOREIGN KEY (isbn) REFERENCES Book(isbn) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES Author(id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS BookCopy;
CREATE TABLE BookCopy (
    id INT PRIMARY KEY,
    isbn VARCHAR(50) NOT NULL,
    current_status BOOLEAN NOT NULL, -- TRUE - доступна, FALSE - выдана
    FOREIGN KEY (isbn) REFERENCES Book(isbn) ON DELETE CASCADE
);

DROP TABLE IF EXISTS Employee;
CREATE TABLE Employee (
    id INT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL
);

DROP TABLE IF EXISTS Reader;
CREATE TABLE Reader (
    id INT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20)
);

DROP TABLE IF EXISTS Process;
CREATE TABLE Process (
    id INT PRIMARY KEY,
    bookcopy_id INT NOT NULL,
    employee_id INT NOT NULL,
    reader_id INT NOT NULL,
    borrow_date DATE NOT NULL CHECK (borrow_date <= CURRENT_DATE),
    return_date DATE NULL,
    FOREIGN KEY (bookcopy_id) REFERENCES BookCopy(id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES Employee(id) ON DELETE CASCADE,
    FOREIGN KEY (reader_id) REFERENCES Reader(id) ON DELETE CASCADE,
    CHECK (return_date IS NULL OR return_date >= borrow_date)
);

-----------
-----------

-- добавление атрибута (может быть NULL)
ALTER TABLE LR_2.Book 
ADD COLUMN description TEXT;


-- создание типа ENUM для жанров
CREATE TYPE genre_enum AS ENUM (
    'Роман-эпопея', 
    'Фэнтези', 
    'Роман'
);

-- добавление новых значений в ENUM
ALTER TYPE genre_enum ADD VALUE 'Учебник';

-- изменение типа атрибута genre на созданный ENUM
ALTER TABLE LR_2.Book 
ALTER COLUMN genre TYPE genre_enum 
USING genre::genre_enum;


-- добавление ограничений
ALTER TABLE LR_2.Reader 
ADD CONSTRAINT phone_check 
CHECK (
    phone IS NULL
    OR phone ~ '^8[0-9]{10}$'
    OR phone ~ '^\+7[0-9]{10}$'
);

-----------
-----------

-- вставка данных в таблицу Author
INSERT INTO Author (id, full_name) VALUES
(1, 'Лев Николаевич Толстой'),
(2, 'Джоан Кэтлин Роулинг'),
(3, 'Джейн Остин'),
(4, 'Атанасян Левон Сергеевич'),
(5, 'Бутузов Валентин Федорович');


-- вставка данных в таблицу Book
INSERT INTO Book (isbn, title, publication_year, publication_office, genre, description) VALUES
('978-5-389-06256-6', 'Война и мир', 1867, 'Азбука', 'Роман-эпопея', '«Война и мир» Л. Н. Толстого — книга на все времена'),
('978-5-389-07790-4', 'Гарри Поттер и Орден Феникса', 2003, 'Росмэн', 'Фэнтези', NULL), -- description может быть NULL
('978-5-04-117893-2', 'Гордость и предубеждение', 1813, 'Эксмо', 'Роман', 'Один из лучших романов о любви всех времен и народов'),
('978-5-09-102538-5', 'Геометрия 7-9 классы. Базовый уровень', 1978, 'Просвещение', 'Учебник', NULL),
('978-5-17-148495-8', 'Сэндитон', 1817, 'АСТ', 'Роман', NULL);


-- -- проверка ограничений
-- INSERT INTO Book (isbn, title, publication_year, publication_office, genre) VALUES
-- ('978-5-17-095176-5', 'Гранатовый браслет', 2000, 'АСТ', 'error genre'); -- жанр не из ENUM-а, выдает ошибку

-- вставка данных в таблицу Book_x_Author (связь M:N)
INSERT INTO Book_x_Author (isbn, author_id) VALUES
('978-5-389-06256-6', 1), -- Война и мир - Толстой
('978-5-389-07790-4', 2), -- Гарри Поттер и Орден Феникса - Роулинг
('978-5-04-117893-2', 3), -- Гордость и предубеждение - Джейн Остин
('978-5-09-102538-5', 4), -- Геометрия 7-9 классы. Базовый уровень - Атанасян
('978-5-09-102538-5', 5), -- Геометрия 7-9 классы. Базовый уровень - Бутузов (демонстрирует M:N)
('978-5-17-148495-8', 3); -- Сэндитон - Джейн Остин (демонстрирует M:N)


-- вставка данных в таблицу BookCopy
INSERT INTO BookCopy (id, isbn, current_status) VALUES
(1, '978-5-389-06256-6', TRUE),  -- (1я) Война и мир - доступна
(2, '978-5-389-06256-6', FALSE), -- (2я) Война и мир - недоступна
(3, '978-5-389-07790-4', TRUE),  -- (1я) Гарри Поттер и Орден Феникса - доступна
(4, '978-5-09-102538-5', FALSE), -- (1я) Геометрия 7-9 классы. Базовый уровень - доступна
(5, '978-5-09-102538-5', FALSE);  -- (2я) Геометрия 7-9 классы. Базовый уровень - недоступна


-- вставка данных в таблицу Employee
INSERT INTO Employee (id, full_name) VALUES
(1, 'Иванова Мария Петровна'),
(2, 'Петров Алексей Владимирович'),
(3, 'Сидорова Амелия Ивановна'),
(4, 'Лапин Дмитрий Сергеевич'),
(5, 'Герц Анна Андреевна');


-- вставка данных в таблицу Reader
INSERT INTO Reader (id, full_name, phone) VALUES
(1, 'Меркин Павел Игоревич', '89151234567'),
(2, 'Левина Диана Сергеевна', '+79162345678'),
(3, 'Прохоров Антон Дмитриевич', '89031112233'),
(4, 'Орлова Виктория Александровна', NULL); -- телефон может быть NULL

INSERT INTO Reader (id, full_name) VALUES
(5, 'Керчиенко Олеся Дмитриевна'); -- телефон может быть NULL и так


-- -- проверка ограничений
-- INSERT INTO Reader (id, full_name, phone) VALUES
-- (6, 'Тест1', '8123');  -- короткий телефон, выдает ошибку

-- -- проверка ограничений
-- INSERT INTO Reader (id, full_name, phone) VALUES 
-- (7, 'Тест2', '19234578282');  -- телефон не начинается с 8 или +7, выдает ошибку


-- вставка данных в таблицу Process
INSERT INTO Process (id, bookcopy_id, employee_id, reader_id, borrow_date, return_date) VALUES
(1, 1, 1, 1, '2024-01-15', '2024-03-25'), -- книга выдана, возвращена //1я война и мир
(2, 2, 2, 2, '2024-01-10', '2024-01-25'), -- книга выдана, возвращена //2я война и мир
(3, 2, 5, 3, '2024-02-01', NULL),         -- та же книга другому читателю, не возвращена //2я война и мир
(4, 4, 3, 2, '2024-01-25', '2024-02-20'), -- книга выдана, возвращена //1я геометрия, 2-му читателю
(5, 5, 4, 5, '2024-02-10', NULL);         -- книга выдана, не возвращена //2я геометрия


-- -- проверка ограничений
-- INSERT INTO Process (id, bookcopy_id, employee_id, reader_id, borrow_date, return_date) VALUES
-- (6, 3, 1, 4, '2026-01-15', NULL); -- дата выдачи раньше, чем "сегодня", выдает ошибку

-- -- проверка ограничений
-- INSERT INTO Process (id, bookcopy_id, employee_id, reader_id, borrow_date, return_date) VALUES
-- (7, 3, 1, 4, '2024-01-10', '2023-01-25'); -- дата возврата раньше, чем дата выдачи, выдает ошибку