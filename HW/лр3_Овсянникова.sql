-- Блок 1: Базовые SELECT и сортировка
-- 1. Вывести только названия книг и их ISBN.
SET search_path TO LR_2;
SELECT title AS "Название книги", isbn FROM book;

-- 2. Вывести список всех авторов без дубликатов.
SET search_path TO LR_2;
SELECT DISTINCT full_name FROM author;

-- 3. Вывести все книги, у которых год издания позже 1995-го, и при этом переименовать столбцы. Если у Вас нет таких книг, то выберете любой другой год.
SET search_path TO LR_2;
SELECT title AS "Название книги", publication_year AS "Год издания" FROM book
WHERE publication_year > 1995;

-- 4. Вывести список всех книг по возрастанию года издания.
SET search_path TO LR_2;
SELECT title AS "Название книги", publication_year AS "Год издания" FROM book
ORDER BY publication_year ASC;

-- 5. Вывести книги, отсортированные сначала по году издания (убывание), а затем по названию (возрастание).
SET search_path TO LR_2;
SELECT title AS "Название книги", publication_year AS "Год издания" FROM book
ORDER BY publication_year DESC, title ASC;

-- 6. Вывести книги, упорядоченный по длине их названия (убывание).
SET search_path TO LR_2;
SELECT title AS "Название книги" FROM book
ORDER BY length(title) DESC;

-- 7. Вывести вторую самую старую книгу (через LIMIT и OFFSET).
SET search_path TO LR_2;
SELECT title AS "Название книги", publication_year AS "Год издания" FROM book
ORDER BY publication_year ASC
LIMIT 1 OFFSET 1;

-- 8. Написать любой запрос с LIKE или SIMILAR TO на Ваше усмотрение.
SET search_path TO LR_2;
SELECT title AS "Название книги", publication_year AS "Год издания" FROM book
WHERE text(publication_year) LIKE '181_' OR text(publication_year) LIKE '19%';


-- Блок 2: Работа со строками, фильтрацией и JOIN
-- 9. Вывести ФИО читателя в сокращённом виде (Иванов И.И.). Для обрезки имени и отчества используйте функцию LEFT. Если у Вас одно общее поле
-- ФИО, то небольшая подсказка: дополнительно используйте функцию split_part.
SET search_path TO LR_2;
SELECT
    split_part(full_name, ' ', 1) || ' ' ||
    LEFT(split_part(full_name, ' ', 2), 1) || '.' ||
    LEFT(split_part(full_name, ' ', 3), 1) || '.' AS "ФИО"
FROM reader;

-- 10. Вывести все книги и соответствующих авторов, включая книги без авторов (если такие есть).
SET search_path TO LR_2;
SELECT b.title, b.publication_year, COALESCE(a.full_name, 'Автор не указан') AS author
FROM book b
    LEFT JOIN book_x_author bxa ON b.isbn = bxa.isbn
    LEFT JOIN author a ON bxa.author_id = a.id;

-- 11. Вывести экземпляры (книга + номер экземпляра), выданные за определенный период. Должно быть 2 варианта: через сравнения и при помощи BETWEEN.
-- 1
SET search_path TO LR_2;
SELECT b.title, bc.id AS "id экземпляра", p.borrow_date AS "Дата выдачи"
FROM book b
    LEFT JOIN bookcopy bc ON b.isbn = bc.isbn
    LEFT JOIN process p ON p.bookcopy_id = bc.id
WHERE EXTRACT(MONTH FROM p.borrow_date) >= 2;

-- 2
SET search_path TO LR_2;
SELECT b.title, bc.id AS "id экземпляра", p.borrow_date AS "Дата выдачи"
FROM book b
    LEFT JOIN bookcopy bc ON b.isbn = bc.isbn
    LEFT JOIN process p ON p.bookcopy_id = bc.id
WHERE p.borrow_date BETWEEN '2024-01-15' AND '2024-02-01';

-- 12. Вывести книги определённых жанров на Ваше усмотрение (используйте IN)
SET search_path TO LR_2;
SELECT title, genre FROM book
WHERE genre IN ('Роман', 'Роман-эпопея');

-- 13. Вывести все экземпляры, которые на текущий момент не возвращены (дата возврата NULL)
SET search_path TO LR_2;
SELECT bc.id, p.borrow_date, p.return_date
FROM bookcopy bc JOIN process p ON p.bookcopy_id = bc.id
WHERE p.return_date IS NULL;

-- 14. Вывести всех читателей, чьи ФИО содержат "Иван" или "Александр" (если таких нет, то возьмите другие имена). Если у Вас имя – отдельный столбец,
-- то выведите ФИО всех авторов, фамилии которых заканчиваются на “ин” или “ой” (если таких нет, то возьмите другие окончания).
SET search_path TO LR_2;
SELECT full_name FROM reader
WHERE full_name LIKE ('%Павел%') OR full_name LIKE ('%Александр%');

-- 15. Вывести список всех книг (не экземпляров) и читателей, которые их брали.
SET search_path TO LR_2;
SELECT b.title AS "Название книги", r.full_name AS "Читатель"
FROM bookcopy bc
    LEFT JOIN book b ON bc.isbn = b.isbn
    LEFT JOIN process p ON bc.id = p.bookcopy_id
    LEFT JOIN reader r ON r.id = p.reader_id
WHERE p.reader_id IS NOT NULL;


-- Блок 3: Агрегация, CASE и COALESCE
-- 16. Вывести общее количество экземпляров книг в библиотеке.
SET search_path TO LR_2;
SELECT COUNT(id) FROM bookcopy;

-- 17. Вывести авторов, у которых 2 или более книги.
SET search_path TO LR_2;
SELECT a.full_name AS "Автор", COUNT(DISTINCT bxa.isbn) AS "Количество книг"
FROM author a LEFT JOIN book_x_author bxa on a.id = bxa.author_id
GROUP BY a.full_name
HAVING COUNT(DISTINCT bxa.isbn) >= 2;

-- 18. Вывести ФИО читателей и их категории по количеству взятых ими книг: 0 – “Новый читатель”, 1 – “Редкий читатель”, 2 – “Средний читатель”, 3 и более
-- – “Частый читатель”. Если Вам не хватает данных, то добавьте их.
SET search_path TO LR_2;
SELECT r.id AS "id читателя", r.full_name AS "Читатель", COUNT(p.id) AS "Взято книг",
    CASE 
        WHEN COUNT(p.id) = 0 THEN 'Новый читатель'
        WHEN COUNT(p.id) = 1 THEN 'Редкий читатель'
        WHEN COUNT(p.id) = 2 THEN 'Средний читатель'
        ELSE 'Частый читатель'
    END AS "Категория читателя"
FROM reader r LEFT JOIN process p ON r.id = p.reader_id
GROUP BY r.id, r.full_name;

-- 19. Вывести ФИО сотрудника и количество выданных им книг. Используйте LEFT JOIN и COALESCE.
SET search_path TO LR_2;
SELECT e.full_name AS "Сотрудник", COALESCE(COUNT(p.bookcopy_id), 0) AS "Количество выданных книг"
FROM employee e LEFT JOIN process p ON e.id = p.employee_id
GROUP BY e.full_name;

-- 20. Вывести ФИО читателя, который взял наибольшее количество книг, и количество выданных ему книг.
SET search_path TO LR_2;
SELECT r.full_name AS "Читатель", COUNT(p.id) AS "Взято книг"
FROM reader r LEFT JOIN process p ON r.id = p.reader_id
GROUP BY r.full_name
ORDER BY COUNT(p.id) DESC LIMIT 1;