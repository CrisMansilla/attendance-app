ALTER DATABASE attendance SET timezone TO 'America/Santiago';

-- Create the 'student' table
CREATE TABLE student (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    value INTEGER NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    day_of_week INTEGER NOT NULL
);

-- Create the 'attendance' table
CREATE TABLE attendance (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES student(id) ON DELETE CASCADE,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create the 'lesson_log' table
CREATE TABLE lesson_log (
    id SERIAL PRIMARY KEY,
    student_id INTEGER references student(id) on delete cascade,
    attendance_id INTEGER REFERENCES attendance(id) ON DELETE cascade,
    lesson_content VARCHAR(250) NOT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create the 'Repertoire' table
CREATE TABLE repertoire (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES student(id) ON DELETE CASCADE,
    piece_name VARCHAR(100) NOT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- PROCEDURES

CREATE PROCEDURE add_student(p_name VARCHAR, p_value INTEGER, p_dow INTEGER)
LANGUAGE SQL
BEGIN ATOMIC
    INSERT INTO student (name, value, day_of_week)
   VALUES (p_name, p_value, p_dow);
END;

create procedure edit_student(p_id integer, p_nom varchar, p_val integer, p_dow integer)
LANGUAGE SQL
BEGIN ATOMIC
    update student 
	set 
		name = p_nom,
		value = p_val,
		day_of_week = p_dow
	where
		id = p_id;
END;

CREATE PROCEDURE mark_attendance(p_student_id INTEGER)
LANGUAGE SQL
BEGIN ATOMIC
    INSERT INTO attendance (student_id) VALUES (p_student_id);
END;

CREATE PROCEDURE add_lesson_log(p_at_id INTEGER, p_lesson_content VARCHAR)
LANGUAGE PLPGSQL as
$$
DECLARE
	p_student_id INTEGER;
BEGIN    
    SELECT student_id INTO p_student_id FROM attendance WHERE id = p_at_id;
    INSERT INTO lesson_log (student_id, lesson_content, attendance_id) VALUES (p_student_id, p_lesson_content, p_at_id);
END
$$;

CREATE PROCEDURE add_repertoire(p_student_id INTEGER, p_piece_name VARCHAR)
LANGUAGE SQL
BEGIN ATOMIC
    INSERT INTO repertoire (student_id, piece_name) VALUES (p_student_id, p_piece_name);
END;

CREATE OR REPLACE FUNCTION get_student_repertoire(p_student_id INTEGER)
RETURNS TABLE (piece_name VARCHAR, date TIMESTAMP)
LANGUAGE SQL
AS $$
    SELECT piece_name, date FROM repertoire 
    WHERE student_id = p_student_id 
    ORDER BY date ASC;
$$;

CREATE OR REPLACE FUNCTION check_students()
RETURNS TABLE (aidi INT, nombre TEXT, valor_clase integer)
LANGUAGE SQL
AS $$
  SELECT id as aidi,name as nombre, value as valor_clase FROM student;
$$;

CREATE OR REPLACE FUNCTION get_student_lesson_log(p_student_id INTEGER)
RETURNS TABLE (nombre varchar, actividades VARCHAR, fecha varchar)
LANGUAGE SQL
AS $$
    SELECT 
		s.name as nombre,
		l.lesson_content as actividades,
		to_char(l.date, 'DD/MM/YYYY') as fecha
	FROM lesson_log l
	inner join student s on s.id = l.student_id 
    WHERE l.student_id = p_student_id 
    ORDER BY l.date DESC;
$$;

CREATE OR REPLACE FUNCTION get_monthly_attendance(p_month INTEGER, p_year INTEGER)
RETURNS TABLE (nombre VARCHAR, asistencia INTEGER, pago INTEGER)
LANGUAGE SQL
AS $$
    SELECT 
    s.name as nombre,
    COUNT(a.student_id) as asistencia,
    (s.value * COUNT(a.student_id)) as pago
    FROM attendance a
    INNER JOIN student s ON a.student_id = s.id
    WHERE 
    EXTRACT(MONTH from date) = p_month AND 
    EXTRACT(YEAR FROM date) = p_year
    GROUP BY s.id, s.name  
    ;
$$;

CREATE OR REPLACE FUNCTION check_attendance_list()
RETURNS table (aidi integer, nombre varchar)
LANGUAGE SQL
AS $$
    select
        s.id as aidi,
        s.name as nombre
    from student s
    where 
	s.day_of_week = (select extract(DOW from NOW())) and
    s.id not in (select student_id from attendance where to_char(date, 'DD/MM/YYYY') = to_char(NOW(), 'DD/MM/YYYY'));
$$;

CREATE OR REPLACE FUNCTION check_attendance_student(p_id integer, p_mes integer, p_anio integer)
RETURNS table (nombre varchar, dia_asistencia varchar)
LANGUAGE SQL
AS $$
    select
        s.name as nombre,
        to_char(a.date, 'DD/MM/YYYY') AS dia_asistencia
    from student s
	inner join attendance a on s.id = a.student_id
    where 
	a.student_id = p_id and
    p_mes = EXTRACT(MONTH FROM a.date) and
	p_anio = EXTRACT(YEAR FROM a.date);
$$;

create or replace function check_unadded_logs()
returns table (nombre varchar, fecha varchar, at_aidi integer)
language sql
as $$
select 
	s.name as nombre,
	to_char(a.date, 'DD/MM/YYYY') as fecha,
	a.id as at_aidi
from attendance a
inner join student s on a.student_id = s.id
where a.id not in (select attendance_id from lesson_log )
$$;

CREATE OR REPLACE FUNCTION check_student(p_id integer)
RETURNS table (nombre varchar, aidi integer, valor_clase integer)
LANGUAGE SQL
AS $$
    select
        s.name as nombre,
        s.id as aidi,
		s.value as valor_clase
    from student s
    where 
	s.id = p_id;
$$;