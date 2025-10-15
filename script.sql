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

CREATE PROCEDURE disable_student(p_id INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE student
    SET active = false
    WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION get_student_repertoire(p_student_id INTEGER)
RETURNS TABLE (nombre VARCHAR, fecha VARCHAR, pieza VARCHAR)
LANGUAGE SQL
AS $$
    SELECT 
        s.name as nombre,
        r.piece_name as pieza,
        to_char(date, 'DD/MM/YYYY') as fecha 
    FROM repertoire r
    INNER JOIN student s ON r.student_id = s.id 
    WHERE r.student_id = p_student_id 
    ORDER BY date ASC;
$$;

CREATE OR REPLACE FUNCTION check_students()
RETURNS TABLE (aidi INT, nombre TEXT, valor_clase integer)
LANGUAGE SQL
AS $$
  SELECT id as aidi,name as nombre, value as valor_clase 
FROM student
where active=true;
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
    s.id not in (select student_id from attendance where to_char(date, 'DD/MM/YYYY') = to_char(NOW(), 'DD/MM/YYYY'))
    and s.active = true;
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

CREATE OR REPLACE FUNCTION months()
RETURNS table (mesesito char(2))
LANGUAGE SQL
AS $$
	select to_char(date, 'MM') 
	from attendance 
	group by to_char(date, 'MM');
$$;

-- Inserts from student.json
INSERT INTO student (id, name, value, active, day_of_week) VALUES (1, 'Hans', 7000, true, 5);
INSERT INTO student (id, name, value, active, day_of_week) VALUES (2, 'Bastián', 0, true, 5);
INSERT INTO student (id, name, value, active, day_of_week) VALUES (3, 'Amanda', 7000, true, 5);
INSERT INTO student (id, name, value, active, day_of_week) VALUES (4, 'Maily', 6250, false, 0);
INSERT INTO student (id, name, value, active, day_of_week) VALUES (5, 'Amparo', 6250, true, 1);
INSERT INTO student (id, name, value, active, day_of_week) VALUES (6, 'Samantha', 7000, false, 1);
INSERT INTO student (id, name, value, active, day_of_week) VALUES (7, 'Emilia', 7000, false, 1);
INSERT INTO student (id, name, value, active, day_of_week) VALUES (8, 'Sebastián Betancour', 6250, true, 1);
INSERT INTO student (id, name, value, active, day_of_week) VALUES (9, 'Tomás', 7000, true, 1);

-- Inserts from attendance.json
INSERT INTO attendance (id, student_id, date) VALUES (1, 5, '2025-06-06 01:55:39.821905');
INSERT INTO attendance (id, student_id, date) VALUES (2, 6, '2025-06-06 01:55:51.837526');
INSERT INTO attendance (id, student_id, date) VALUES (3, 4, '2025-06-06 01:56:06.053297');
INSERT INTO attendance (id, student_id, date) VALUES (4, 7, '2025-06-06 01:56:28.660601');
INSERT INTO attendance (id, student_id, date) VALUES (5, 2, '2025-06-06 17:53:59.845826');
INSERT INTO attendance (id, student_id, date) VALUES (6, 3, '2025-06-06 18:57:40.72216');
INSERT INTO attendance (id, student_id, date) VALUES (7, 6, '2025-06-09 20:20:33.111516');
INSERT INTO attendance (id, student_id, date) VALUES (8, 7, '2025-06-09 20:20:38.793172');
INSERT INTO attendance (id, student_id, date) VALUES (9, 5, '2025-06-11 21:28:40.934874');
INSERT INTO attendance (id, student_id, date) VALUES (10, 1, '2025-06-13 17:01:45.019825');
INSERT INTO attendance (id, student_id, date) VALUES (14, 2, '2025-06-13 17:56:43.428986');
INSERT INTO attendance (id, student_id, date) VALUES (15, 3, '2025-06-13 18:57:38.119135');
INSERT INTO attendance (id, student_id, date) VALUES (16, 6, '2025-06-16 19:26:59.733151');
INSERT INTO attendance (id, student_id, date) VALUES (17, 7, '2025-06-18 17:02:23.14697');
INSERT INTO attendance (id, student_id, date) VALUES (18, 5, '2025-06-18 18:28:55.371633');
INSERT INTO attendance (id, student_id, date) VALUES (19, 6, '2025-06-23 21:55:41.945904');
INSERT INTO attendance (id, student_id, date) VALUES (20, 7, '2025-06-25 17:03:17.895548');
INSERT INTO attendance (id, student_id, date) VALUES (21, 5, '2025-06-25 18:55:43.035961');
INSERT INTO attendance (id, student_id, date) VALUES (22, 2, '2025-06-27 18:11:13.758931');
INSERT INTO attendance (id, student_id, date) VALUES (23, 4, '2025-06-27 19:13:15.066851');
INSERT INTO attendance (id, student_id, date) VALUES (24, 5, '2025-07-04 15:45:58.366206');
INSERT INTO attendance (id, student_id, date) VALUES (25, 1, '2025-07-04 20:11:27.268835');
INSERT INTO attendance (id, student_id, date) VALUES (26, 2, '2025-07-04 20:11:32.485014');
INSERT INTO attendance (id, student_id, date) VALUES (27, 3, '2025-07-04 20:11:37.117964');
INSERT INTO attendance (id, student_id, date) VALUES (28, 4, '2025-07-04 20:11:43.371722');
INSERT INTO attendance (id, student_id, date) VALUES (29, 7, '2025-07-11 16:02:44.302325');
INSERT INTO attendance (id, student_id, date) VALUES (30, 5, '2025-07-11 16:02:51.500854');
INSERT INTO attendance (id, student_id, date) VALUES (31, 1, '2025-07-11 16:26:58.312579');
INSERT INTO attendance (id, student_id, date) VALUES (32, 2, '2025-07-11 18:47:38.440547');
INSERT INTO attendance (id, student_id, date) VALUES (33, 7, '2025-07-15 01:42:57.860684');
INSERT INTO attendance (id, student_id, date) VALUES (34, 1, '2025-07-18 20:26:43.592088');
INSERT INTO attendance (id, student_id, date) VALUES (35, 2, '2025-07-18 20:26:48.632319');
INSERT INTO attendance (id, student_id, date) VALUES (36, 3, '2025-07-18 20:26:52.163939');
INSERT INTO attendance (id, student_id, date) VALUES (37, 7, '2025-07-22 12:56:46.21168');
INSERT INTO attendance (id, student_id, date) VALUES (38, 5, '2025-07-24 02:08:04.159952');
INSERT INTO attendance (id, student_id, date) VALUES (39, 1, '2025-07-25 23:45:50.168824');
INSERT INTO attendance (id, student_id, date) VALUES (40, 3, '2025-07-25 23:45:58.669665');
INSERT INTO attendance (id, student_id, date) VALUES (41, 1, '2025-08-05 03:05:06.688578');
INSERT INTO attendance (id, student_id, date) VALUES (42, 2, '2025-08-05 03:05:15.107853');
INSERT INTO attendance (id, student_id, date) VALUES (43, 3, '2025-08-05 03:05:24.963187');
INSERT INTO attendance (id, student_id, date) VALUES (44, 3, '2025-08-08 19:21:21.082444');
INSERT INTO attendance (id, student_id, date) VALUES (45, 5, '2025-08-11 19:47:28.222387');
INSERT INTO attendance (id, student_id, date) VALUES (46, 8, '2025-08-22 14:10:52.820957');
INSERT INTO attendance (id, student_id, date) VALUES (47, 5, '2025-08-22 14:11:00.145637');
INSERT INTO attendance (id, student_id, date) VALUES (48, 1, '2025-08-22 16:53:20.977591');
INSERT INTO attendance (id, student_id, date) VALUES (49, 2, '2025-08-22 20:31:01.387227');
INSERT INTO attendance (id, student_id, date) VALUES (50, 3, '2025-08-22 20:31:09.589727');
INSERT INTO attendance (id, student_id, date) VALUES (51, 5, '2025-08-25 20:04:51.615929');
INSERT INTO attendance (id, student_id, date) VALUES (52, 8, '2025-08-25 20:05:01.604076');
INSERT INTO attendance (id, student_id, date) VALUES (53, 9, '2025-08-25 20:05:10.564142');
INSERT INTO attendance (id, student_id, date) VALUES (54, 1, '2025-08-29 17:44:02.545879');
INSERT INTO attendance (id, student_id, date) VALUES (55, 3, '2025-08-29 19:03:42.771232');
INSERT INTO attendance (id, student_id, date) VALUES (56, 8, '2025-09-02 03:03:45.140316');
INSERT INTO attendance (id, student_id, date) VALUES (57, 5, '2025-09-02 03:03:56.392282');
INSERT INTO attendance (id, student_id, date) VALUES (58, 9, '2025-09-02 03:04:04.979327');
INSERT INTO attendance (id, student_id, date) VALUES (59, 1, '2025-09-05 19:23:29.968727');
INSERT INTO attendance (id, student_id, date) VALUES (60, 3, '2025-09-05 19:23:38.483315');
INSERT INTO attendance (id, student_id, date) VALUES (61, 8, '2025-09-08 23:45:09.44722');
INSERT INTO attendance (id, student_id, date) VALUES (62, 9, '2025-09-08 23:45:15.618415');
INSERT INTO attendance (id, student_id, date) VALUES (63, 1, '2025-09-12 19:05:08.654923');
INSERT INTO attendance (id, student_id, date) VALUES (64, 2, '2025-09-12 19:05:14.724417');
INSERT INTO attendance (id, student_id, date) VALUES (65, 8, '2025-09-15 20:09:27.765042');
INSERT INTO attendance (id, student_id, date) VALUES (66, 5, '2025-09-15 20:09:32.52461');
INSERT INTO attendance (id, student_id, date) VALUES (67, 8, '2025-09-23 15:16:33.481647');
INSERT INTO attendance (id, student_id, date) VALUES (68, 9, '2025-09-23 15:16:39.53892');
INSERT INTO attendance (id, student_id, date) VALUES (69, 1, '2025-09-26 19:15:49.426683');
INSERT INTO attendance (id, student_id, date) VALUES (70, 2, '2025-09-26 19:15:54.775897');
INSERT INTO attendance (id, student_id, date) VALUES (71, 3, '2025-09-26 19:15:59.569862');
INSERT INTO attendance (id, student_id, date) VALUES (72, 8, '2025-09-29 17:11:00.883236');
INSERT INTO attendance (id, student_id, date) VALUES (73, 5, '2025-09-29 19:03:09.19094');
INSERT INTO attendance (id, student_id, date) VALUES (74, 9, '2025-09-29 19:03:15.204503');
INSERT INTO attendance (id, student_id, date) VALUES (75, 3, '2025-10-13 12:50:27.480916');
INSERT INTO attendance (id, student_id, date) VALUES (76, 1, '2025-10-13 12:50:57.324755');
INSERT INTO attendance (id, student_id, date) VALUES (77, 2, '2025-10-13 12:51:06.051674');
INSERT INTO attendance (id, student_id, date) VALUES (78, 5, '2025-10-13 19:10:23.605048');
INSERT INTO attendance (id, student_id, date) VALUES (79, 8, '2025-10-13 19:10:32.942185');
INSERT INTO attendance (id, student_id, date) VALUES (80, 9, '2025-10-13 19:10:38.356086');
INSERT INTO attendance (id, student_id, date) VALUES (81, 5, '2025-10-14 17:11:11.989291');
INSERT INTO attendance (id, student_id, date) VALUES (82, 8, '2025-10-14 17:11:17.150097');
INSERT INTO attendance (id, student_id, date) VALUES (83, 9, '2025-10-14 17:11:21.935948');

-- Inserts from lesson_log.json
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (1, 5, 1, 'Se revisó el Waltz y Ditty. Se trabajó con metrónomo Ditry, a 55 bpm.', '2025-06-06 02:37:34.844893');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (2, 6, 2, 'Se trabajó una pieza sencilla.', '2025-06-06 02:37:51.32719');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (3, 4, 3, 'Se trabajó estrellita, con manejo de intensidad. Se trabajó en Kabalevski con manejo de intensidad.', '2025-06-06 02:38:43.889009');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (4, 7, 4, 'Se trabajó en una canción de Cami, rosa creo. Se está trabajando acordes, inversiones y acompañamiento de canciones con formas básicas.', '2025-06-06 02:39:29.868701');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (5, 2, 5, 'Se revisó Clementi, primer y segundo movimiento. El primer movimiento se está viendo a 80 bpm como negra. El segundo se está viendo a 30 bpm como negra/tresillo. La escala mayor de do se ve hasta dos octavas.', '2025-06-06 17:55:20.595879');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (6, 3, 6, 'Se revisó escala de do a manos separadas. Se vió escala espejo. La pequeña canción se ve a manos juntas y separadas, el primer sistema', '2025-06-06 18:58:43.540268');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (7, 6, 7, 'Escala de do a dos octavas. Pieza número 6 de las sencillas. Se empieza a ver frases', '2025-06-09 20:21:21.26602');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (8, 7, 8, 'Se revisan acordes y arpegios en escala de re mayor.', '2025-06-09 20:21:40.744556');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (9, 5, 9, 'Se dejó escala de do a dos octavas. Se revisa repertorio. Canción más débil ditty, por lo que se trabaja con metrónomo, se revisa intensidad.', '2025-06-11 21:30:13.810712');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (10, 2, 14, 'Se revisa Sonatina, primer movimiento con métricas de volumen, a 80bpm como negra.', '2025-06-13 17:57:39.267181');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (11, 3, 15, 'Se revisa repertorio. Se ve la pieza completa. De ejercicios: escala de do espejo, a manos separadas ( sube y baja ), a manos juntas (subida).', '2025-06-13 18:58:28.67958');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (12, 1, 10, 'Se revisa escalas: do mayor (BPM 150 1va 100 2va 50 3va), sol mayor( BPM 80 2va). Se revisa repertorio y se dan ideas para tocarlas. Se entrega angel de marty friedman.', '2025-06-13 19:03:32.328641');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (13, 6, 16, 'Escala mayor de do a dos octavas. Se revisa canción simple', '2025-06-16 19:28:20.496968');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (14, 7, 17, 'Se revisan acordes: do mayor, re mayor/menor, mi mayor/menor, fa mayor/menor, sol mayor, la mayor/menor. Se revisa la primera lección de Diabelli', '2025-06-18 17:06:55.919715');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (15, 5, 18, 'Se revisan niveles de volumen en Ditty. Trabajo de muñeca en general. Para prox. semana, se verá ditty mejorado, junto con repertorio nuevo.', '2025-06-18 18:30:14.299896');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (16, 6, 19, 'Revisión pieza, escala de Do Mayor: saltillo y dos octavas', '2025-06-23 21:56:16.630728');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (17, 7, 20, 'Se revisa escala de Do mayor a una octava, 70 BPM. Se revisan los arpegios, en las inversiones.  Se revisan acordes de Morning Mood. Se pide revisión de las lecciones de Diabelli', '2025-06-25 17:11:39.992324');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (18, 5, 21, 'Se revisa Anclado en otra isla. Escala de Do mayor a dos octavas lento. Se revisa Ditty, mejoras en la intensidad', '2025-06-25 18:56:58.341861');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (19, 2, 22, 'Se revisa repertorio. Primer movimiento con dinámicas. Segundo movimiento se revisa primera hoja. Se revisa ritmos.', '2025-06-27 18:13:24.963805');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (20, 4, 23, 'No llegó :(', '2025-06-27 19:13:55.364276');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (21, 5, 24, 'Revisión de Ditty. Se revisan notas de Anclado en Otra Isla', '2025-07-04 15:46:46.012683');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (22, 1, 25, 'Escalas a más velocidad. Revisión de temas', '2025-07-11 16:04:06.116723');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (23, 2, 26, 'Revisión segundo mov de sonatina.', '2025-07-11 16:04:29.841457');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (24, 3, 27, 'revisión escala, canciones', '2025-07-11 16:05:21.668532');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (25, 4, 28, 'Se revisa repertorio. Se recuerdan las formas de tocar piano.', '2025-07-11 16:28:47.112232');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (26, 7, 29, 'Se revisa el repertorio.', '2025-07-11 16:29:01.05336');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (27, 5, 30, 'Se añade angel, se revisan acordes y ritmos. Se deja como tarea avanzar con anclado en otra isla.', '2025-07-11 16:29:36.985481');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (28, 1, 31, 'Escalas de do, sol y fa mayor. BPM de 110. Pieza para gala de Satie. Se revisa sonatina en fa mayor, ritmos.', '2025-07-15 01:43:58.818692');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (29, 2, 32, 'Se revisa el segundo movimiento de la sonatina de clementi. Primer movimiento se revisa bien con el pulso marcado. Segundo movimiento se empieza a ver dinámicas.', '2025-07-15 01:44:37.376601');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (30, 7, 33, 'Se revisa Morning Mood. Se llega hasta el final de la pieza, se revisa qué se debe hacer. Se debe seguir revisando la forma y las dinámicas más adelante.', '2025-07-15 01:45:19.801303');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (31, 1, 34, 'Se revisa sonatina. Se deja como tarea revisar escala de sol con variantes en tempo. Escala de fa por ahora lento. ', '2025-07-18 20:27:48.654784');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (32, 2, 35, 'Revisión de sonatina. Primeros dos movimientos se revisa ritmo. Se deja como tarea la primera hoja del tercer movimiento.', '2025-07-18 20:28:25.265575');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (33, 3, 36, 'Se revisan las piezas. Ambas se están llegando al final. Se debe trabajar ritmos y fraseo.', '2025-07-18 20:28:51.776912');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (34, 7, 37, 'Se revisa repertorio', '2025-07-22 12:57:04.184805');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (35, 5, 38, 'Revisión de ritmo de Anclado en otra isla. Se empieza a trabajar con el pedal', '2025-07-24 02:08:35.841094');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (36, 1, 39, 'Se revisan partes complicadas de Sonatina. Se revisa tema de gala. Está sonando bien', '2025-07-25 23:46:34.409043');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (37, 3, 40, 'Se revisa el repertorio. Se sigue trabajando con llave de fa', '2025-07-25 23:47:33.055207');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (38, 2, 42, 'Se termina de leer la sonatina. Se perfecciona mov. 1 y 2', '2025-08-05 03:05:58.726148');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (39, 1, 41, 'Se termina de revisar la sonatina. El tema de gala está lista', '2025-08-05 03:06:17.588156');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (40, 3, 43, 'Se revisan loa primeros 8 compases de Arietta de Clementi', '2025-08-05 03:06:50.391308');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (41, 3, 44, 'Se revisa Arietta', '2025-08-08 19:22:24.741422');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (42, 5, 45, 'última revisión de Anclado en Otra Isla', '2025-08-11 19:47:55.465921');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (43, 8, 46, 'Se enseñan las notas del piano, escala de do y posición de manos. Se revisan acordes de la canción Autumn Leaves.', '2025-08-22 14:12:25.529426');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (44, 5, 47, 'Se revisa escala mayor de Do: ligado, saltillo y saltillo inverso. Se lee hasta la mitad de la primera hoja del primer movimiento de Diabelli (hasta la repetición)', '2025-08-22 14:13:31.321394');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (45, 1, 48, 'Se revisan matices de sonatina. Escala de do mayor, 70bpm 4 octavas. Trabajo de dedos 4 y 5 en mano derecha', '2025-08-22 20:32:35.49867');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (46, 2, 49, 'Se empieza a trabajar Melodie. Se estudian las notas y el dedaje.', '2025-08-22 20:33:57.27168');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (47, 3, 50, 'Se sigue trabajando Arietta. Se llega hasta el cuarto sistema. Se trabaja el ritmo', '2025-08-22 20:34:22.819138');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (48, 5, 51, 'Se trabaja repertorio, viendo ritmos y notas (hasta primera repetición)', '2025-08-29 17:45:23.890214');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (49, 8, 52, 'Se trabaja posición de la mano, notas y dedaje de Autumn Leaves', '2025-08-29 17:45:47.294485');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (50, 9, 53, 'Se inicia con escala de do a dos octavas. Se inicia trabajo con Piezas Básicas para probar nivel', '2025-08-29 17:46:49.357213');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (51, 1, 54, 'Escalas: Do a 65BPM 4va, sol a 4va 55BPM. Sonatina se trabaja en 50 para matices, 70 para velocidad. Dedicatoria se inicia trabajo en 50BPM para tresillo. Se debe trabajar bien niveles de diferentes voces', '2025-08-29 17:48:56.923229');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (52, 3, 55, 'Se avanza en la pieza. Se llega al último sistema. Se empieza a trabajar la escala de do a manos juntas.', '2025-09-02 03:04:45.437927');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (53, 8, 56, 'Se sigue trabajando en posición de mano.', '2025-09-02 03:05:08.712321');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (54, 5, 57, 'Se trabaja en la pieza. Se dan indicaciones para run run.', '2025-09-02 03:06:01.080147');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (55, 9, 58, 'Se trabaja la escala de do. Se revisa Morning Mood. Se llega hasta un poco antes del final de la pieza.', '2025-09-02 03:06:55.429339');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (56, 3, 60, 'Se completa la obra. Se dan indicaciones para ligar todo.', '2025-09-05 19:24:15.15149');
INSERT INTO lesson_log (id, student_id, attendance_id, lesson_content, date) VALUES (57, 1, 59, 'Se dan indicaciones para Mira Niñita. Se refuerza sonatina. Dedicatoria aún lenta, buscando balance entre voces', '2025-09-05 19:25:28.788048');

-- Inserts from repertoire.json
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (1, 1, 'Bach - Preludio en Do mayor', '2025-06-06 02:24:24.568381');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (2, 1, 'Minuet en Sol mayor', '2025-06-06 02:25:04.86323');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (3, 1, 'Satie - Gymnopedie 1', '2025-06-06 02:25:39.109205');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (4, 2, 'Clementi - Sonatina 1 Mov. 1', '2025-06-06 02:26:19.481516');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (5, 2, 'Clementi - Sonatina 1 Mov. 2', '2025-06-06 02:26:39.128256');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (6, 3, 'Pieza número 3 de las fáciles', '2025-06-06 02:27:03.378426');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (7, 4, 'Estrellita, Cockoo', '2025-06-06 02:27:34.801142');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (8, 4, 'Kabalevski Op. 39 No. 1', '2025-06-06 02:28:26.273273');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (9, 5, 'Kabalevski Op. 39 No. 13', '2025-06-06 02:28:56.9168');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (10, 5, 'Kabalevski Op. 27 No 2', '2025-06-06 02:30:07.082742');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (11, 1, 'Marty Friedman - Angel', '2025-06-11 17:20:04.906013');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (12, 7, 'Diabelli - Lessons 1 & 2', '2025-06-18 17:07:21.096482');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (13, 5, 'Jaime Barría - Anclado en Otra Isla', '2025-06-18 18:30:37.161366');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (14, 7, 'Grieg - Morning Mood', '2025-06-25 17:12:06.496446');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (15, 1, 'Sonatina en Fa Mayor', '2025-07-11 16:03:33.675202');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (16, 3, 'Clementi - Arietta', '2025-08-05 03:07:18.579622');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (17, 8, 'Autumn Leaves', '2025-08-22 14:11:13.013228');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (18, 5, 'Diabelli Opus 151 No. 2', '2025-08-22 14:11:37.277558');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (19, 1, 'Granados - Dedicatoria (Op. 1 No. 1)', '2025-08-22 16:54:09.148849');
INSERT INTO repertoire (id, student_id, piece_name, date) VALUES (20, 2, 'Schumann - Melodie (Op. 68 No. 1)', '2025-08-22 20:33:07.765882');
