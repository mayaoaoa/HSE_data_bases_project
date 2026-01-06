-- Блок 1: Представления

-- 1. Создать представление Returned_Books, в котором будут указаны все возвращённые экземпляры (ISBN и название книги, id экземпляра)
-- с датами выдачи и возврата.
SET search_path TO LR_2;
CREATE OR REPLACE VIEW Returned_Books AS
SELECT bc.id, b.isbn, b.title, p.borrow_date, p.return_date
FROM process p
    JOIN bookcopy bc ON p.bookcopy_id = bc.id
    JOIN book b ON bc.isbn = b.isbn
WHERE p.return_date IS NOT NULL
ORDER BY b.isbn, bc.id;

-- 2. Создать материализованное представление Book_Copies_Count, которое выводит количество экземпляров для каждой книги. Продемонстрировать
-- изменения после REFRESH.
--создание
SET search_path TO LR_2;

DROP MATERIALIZED VIEW IF EXISTS Book_Copies_Count;
CREATE MATERIALIZED VIEW Book_Copies_Count AS
SELECT b.isbn, b.title, COUNT(bc.id) AS bookcopies_count
FROM book b
    LEFT JOIN bookcopy bc ON b.isbn = bc.isbn
GROUP BY b.isbn, b.title
ORDER BY bookcopies_count DESC;

--изначально
SELECT * FROM Book_Copies_Count;

--изменения
INSERT INTO bookcopy (id, isbn, current_status) VALUES
(6, '978-5-389-06256-6', TRUE),
(7, '978-5-04-117893-2', TRUE),
(8, '978-5-04-117893-2', FALSE);

-- без REFRESH
SELECT * FROM Book_Copies_Count;

-- после REFRESH
REFRESH MATERIALIZED VIEW Book_Copies_Count;
SELECT * FROM Book_Copies_Count;

-- 3. Создать материализованное представление Genre_Popularity, содержащее количество выдач по жанрам (за всё время или за выбранный период).
SET search_path TO LR_2;

DROP MATERIALIZED VIEW IF EXISTS Genre_Popularity;
CREATE MATERIALIZED VIEW Genre_Popularity AS
SELECT b.genre, COUNT(p.id) AS total_borrows
FROM book b
    LEFT JOIN bookcopy bc ON b.isbn = bc.isbn
    LEFT JOIN process p ON bc.id = p.bookcopy_id
GROUP BY b.genre;

-- Блок 2: CTE

-- 4. С помощью одного CTE определить для каждой книги суммарное число дней нахождения “на руках” (с учётом только возвращённых экземпляров).
SET search_path TO LR_2;
WITH borrowed_books_period AS (
    SELECT bc.id, b.isbn, b.title, (p.return_date - p.borrow_date) AS borrow_period
    FROM process p
        JOIN bookcopy bc ON p.bookcopy_id = bc.id
        JOIN book b ON bc.isbn = b.isbn
    WHERE p.return_date IS NOT NULL
)

SELECT isbn, title, SUM(borrow_period) AS total_borrow_period
FROM borrowed_books_period
GROUP BY isbn, title;


-- 5. С помощью нескольких CTE вычислить среднюю продолжительность чтения (в днях) по каждому жанру (с учётом только возвращённых
-- экземпляров). При необходимости значения можно округлить до целого при помощи ROUND.
SET search_path TO LR_2;
WITH borrowed_books_period AS (
    SELECT bc.id, b.isbn, b.title, b.genre, (p.return_date - p.borrow_date) AS borrow_period
    FROM process p
        JOIN bookcopy bc ON p.bookcopy_id = bc.id
        JOIN book b ON bc.isbn = b.isbn
    WHERE p.return_date IS NOT NULL
),
genre_statistics AS (
    SELECT genre, ROUND(AVG(borrow_period), 2) AS avg_borrow_period
    FROM borrowed_books_period
    GROUP BY genre
)

SELECT genre, avg_borrow_period
FROM genre_statistics;


-- 6. С помощью двух CTE (первое – подсчёт выданных экземпляров по сотруднику, второе – подсчёт разных читателей, обслуженных сотрудником)
-- вывести количество выданных книг и число обслуженных читателей по сотруднику.
SET search_path TO LR_2;
WITH employee_books AS (
    SELECT e.id AS employee_id, e.full_name, COUNT(p.id) AS bookcopies_count
    FROM employee e LEFT JOIN process p ON e.id = p.employee_id
    GROUP BY e.id, e.full_name
),
employee_readers AS (
    SELECT e.id AS employee_id, e.full_name, COUNT(DISTINCT p.reader_id) AS readers_count
    FROM employee e LEFT JOIN process p ON e.id = p.employee_id
    GROUP BY e.id, e.full_name
)

SELECT eb.employee_id, eb.full_name, eb.bookcopies_count, er.readers_count
FROM employee_books eb JOIN employee_readers er ON eb.employee_id = er.employee_id;



-- Блок 3: Оконные функции
-- Задания этого блока можно выполнять как при помощи обычных запросов, так и с использованием представлений и CTE для упрощения структуры запросов и
-- повышения читаемости.

-- 7. Для каждого читателя вывести номер его читательского билета, ФИО, среднее время возврата книг (в днях), общее среднее по всем читателям и
-- разницу. Учитывать необходимо только завершённые выдачи, в которых экземпляры были успешно возвращены.
SET search_path TO LR_2;
WITH reader_statistics AS (
    SELECT r.id AS reader_id, r.full_name, (p.return_date - p.borrow_date) AS borrow_period
    FROM reader r JOIN process p ON r.id = p.reader_id
    WHERE p.return_date IS NOT NULL
),
reader_avg AS (
    SELECT reader_id, full_name, ROUND(AVG(borrow_period), 2) AS avg_borrow_period, ROUND(AVG(AVG(borrow_period)) OVER (), 2) AS overall_avg_borrow_period
    FROM reader_statistics
    GROUP BY reader_id, full_name
)

SELECT reader_id, full_name, avg_borrow_period, overall_avg_borrow_period, (avg_borrow_period - overall_avg_borrow_period) AS difference
FROM reader_avg;


-- 8. Вывести рейтинг книг по количеству выдач за всё время с использованием RANK и DENSE_RANK.
SET search_path TO LR_2;
WITH book_statistics AS (
    SELECT  b.isbn, b.title, COUNT(p.id) AS borrows_count
    FROM book b
        LEFT JOIN bookcopy bc ON b.isbn = bc.isbn
        LEFT JOIN process p ON bc.id = p.bookcopy_id
    GROUP BY b.isbn, b.title
)

SELECT isbn, title, borrows_count, RANK() OVER (ORDER BY borrows_count DESC) AS rank_position, DENSE_RANK() OVER (ORDER BY borrows_count DESC) AS dense_rank_position
FROM book_statistics;


-- 9. Найти топ-10% читателей по активности (количество выданных книг) с помощью PERCENT_RANK или CUME_DIST, а также NTILE.
SET search_path TO LR_2;
WITH reader_statistics AS (
    SELECT
        r.id AS reader_id, r.full_name, COUNT(p.id) AS bookcopies_count, PERCENT_RANK() OVER (ORDER BY COUNT(p.id) DESC) AS percent_rank,
        NTILE(10) OVER (ORDER BY COUNT(p.id) DESC) AS ntile_group
    FROM reader r LEFT JOIN Process p ON r.id = p.reader_id
    GROUP BY r.id, r.full_name
)

SELECT reader_id, full_name, bookcopies_count, percent_rank, ntile_group
FROM reader_statistics
WHERE percent_rank <= 0.1 AND ntile_group = 1;


-- 10. Для каждой книги определить ФИО первого и последнего читателей, которым выдавали данную книгу, и дату выдачи. Выполнять задание
-- необходимо с использованием FIRST_VALUE и LAST_VALUE.
SET search_path TO LR_2;
WITH book_statistics AS (
    SELECT b.isbn, b.title, r.id AS reader_id, r.full_name, p.borrow_date, ROW_NUMBER() OVER (PARTITION BY b.isbn ORDER BY p.borrow_date) AS issuance_order
    FROM book b
        JOIN bookcopy bc ON b.isbn = bc.isbn
        JOIN process p ON bc.id = p.bookcopy_id
        JOIN reader r ON p.reader_id = r.id
    WHERE p.borrow_date IS NOT NULL
)

SELECT DISTINCT ON (isbn)
    isbn, title,
    FIRST_VALUE(full_name) OVER (PARTITION BY isbn ORDER BY borrow_date) AS first_reader,
    FIRST_VALUE(borrow_date) OVER (PARTITION BY isbn ORDER BY borrow_date) AS first_borrow_date,
    LAST_VALUE(full_name) OVER (PARTITION BY isbn ORDER BY borrow_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_reader,
    LAST_VALUE(borrow_date) OVER (PARTITION BY isbn ORDER BY borrow_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_borrow_date
FROM book_statistics
ORDER BY isbn, borrow_date;


-- 11. Найти для каждого читателя дату последней выдачи, предыдущей и следующей относительно каждой операции, а также интервал (в днях)
-- между ними. Определить читателей, у которых между выдачами был перерыв 30 и более дней.
SET search_path TO LR_2;
WITH reader_statistics AS (
    SELECT 
        r.id AS reader_id,
        r.full_name,
        p.borrow_date,
        LAG(p.borrow_date) OVER (PARTITION BY r.id ORDER BY p.borrow_date) AS prev_borrow_date,
        LEAD(p.borrow_date) OVER (PARTITION BY r.id ORDER BY p.borrow_date) AS next_borrow_date,
        (p.borrow_date - LAG(p.borrow_date) OVER (PARTITION BY r.id ORDER BY p.borrow_date)) AS days_since_prev,
        (LEAD(p.borrow_date) OVER (PARTITION BY r.id ORDER BY p.borrow_date) - p.borrow_date) AS days_until_next
    FROM reader r JOIN process p ON r.id = p.reader_id
    WHERE p.borrow_date IS NOT NULL
)

SELECT reader_id, full_name, borrow_date, prev_borrow_date, next_borrow_date, days_since_prev, days_until_next,
    CASE 
        WHEN days_since_prev >= 30 THEN 'Длительный перерыв >= 30 дней'
        WHEN days_until_next >= 30 THEN 'Длительный перерыв >= 30 дней'
        ELSE 'Короткий перерыв'
    END AS status
FROM reader_statistics
ORDER BY reader_id, borrow_date;