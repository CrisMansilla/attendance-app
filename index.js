const express = require('express');
const { Pool } = require('pg');
require('dotenv').config();
const layouts = require('express-ejs-layouts');
const path = require('path');
const app = express();
const port = process.env.PORT || 3000;

// Set EJS as the view engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
// Serve static files from the 'public' directory
app.use(express.static(path.join(__dirname, 'public')));
app.use(layouts);
app.set('layout', 'layouts/main');
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

app.get('/', (req, res) => {
  pool.query('SELECT * FROM check_attendance_list()', (err, result) => {
    if (err) {
      console.error('Error fetching students:', err);
      return res.status(500).send('Internal Server Error');
    }
    res.render('index', { title: 'Home', students: result.rows });
  });
});

app.get('/students', (req, res) => {
  // Fetch students from the database
  pool.query('SELECT * FROM check_students()', (err, result) => {
    if (err) {
      console.error('Error fetching students:', err);
      return res.status(500).send('Internal Server Error');
    }
    res.render('students', { title: 'Manage Students', students: result.rows });
  });
});

app.get('/students/new', (req, res) => {
  res.render('new_student', { title: 'Agregar nuevo estudiante' });
}
);

app.post('/add_student', (req, res) => {
  const {name, valor, dow} = req.body;
  // Insert new student into the database
  pool.query('CALL add_student($1, $2, $3)', [name, valor, dow], (err) => {
    if (err) {
      console.error('Error adding student:', err);
      return res.status(500).send('Internal Server Error');
    }
    
    // Redirect to the students page after adding a new student
    res.redirect('/students');
  });
});

app.get('/students/mark_attendance/:id', (req, res) => {
  const studentId = req.params.id;
  // Update attendance in the database
  pool.query('CALL mark_attendance($1)', [studentId], (err) => {
    if (err) {
      console.error('Error updating attendance:', err);
      return res.status(500).send('Internal Server Error');
    }
    
    // Redirect to the attendance page after marking attendance
    res.redirect('/');
  });
});

app.get('/attendance', (req, res) => {
  pool.query('SELECT * FROM check_attendance_list()', (err, result) => {
    if (err) {
      console.error('Error fetching students:', err);
      return res.status(500).send('Internal Server Error');
    }
    res.render('attendance', { title: 'Attendance', students: result.rows });
  });
}
);

app.get('/summary', async (req, res) => {
  try {
    // Traemos todos los estudiantes para el select siempre
    const estudiantesQuery = await pool.query('SELECT * FROM check_students()');
    const estudiantes = estudiantesQuery.rows;

    const { month, year, estudiante } = req.query;

    // Si no hay parámetros, render vacío
    if (!month && !year && !estudiante) {
      return res.render('check_attendance', {
        title: 'Summary',
        attendance: [],
        month: [],
        year: [],
        students: estudiantes,
        mensual: false,
        individual: false
      });
    }

    // Si hay mes y año pero no estudiante: resumen mensual
    if (month && year && !estudiante) {
      const result = await pool.query('SELECT * FROM get_monthly_attendance($1, $2)', [month, year]);
      return res.render('check_attendance', {
        title: 'Summary',
        students: estudiantes,
        attendance: result.rows,
        month,
        year,
        mensual: true,
        individual: false
      });
    }

    // Si hay estudiante + mes + año: resumen individual
    if (month && year && estudiante) {
      const result = await pool.query('SELECT * FROM check_attendance_student($1, $2, $3)', [estudiante, month, year]);
      return res.render('check_attendance', {
        title: 'Summary',
        students: estudiantes,
        asistencia: result.rows,
        month,
        year,
        individual: true,
        mensual: false
      });
    }

    // Si cae en un caso no contemplado (parámetros sueltos), devolvemos error o redirigimos
    return res.status(400).send('Parámetros inválidos para resumen');
    
  } catch (err) {
    console.error('Error fetching summary:', err);
    res.status(500).send('Internal Server Error');
  }
});


app.get('/add_log', (req, res) => {
  pool.query('SELECT * FROM check_unadded_logs()', (err, result) => {
    if (err) {
      console.error('Error fetching logs:', err);
      return res.status(500).send('Internal Server Error');
    }
    res.render('add_log', { title: 'Agregar actividad', clases: result.rows });
  });
});

app.post('/add_log/add_activity', async (req, res) => {
  const { lesson_id, activity } = req.body;
  try {
    await pool.query('CALL add_lesson_log($1, $2);', [lesson_id, activity]);
    res.redirect('/add_log'); 
  } catch (err) {
    console.error('Error guardando actividad:', err);
    res.status(500).send('Error interno');
  }
});

app.get('/repertoire', async (req, res) => {
  const filas = await pool.query('SELECT * FROM check_students()');
  const estudiantes = filas.rows;

  const student = req.query.student;

  if (!student) {
    return res.render('repertoire', { title: 'Repertorio', students: estudiantes, repertoirs:false });
  }
  
  else{
    try{
      pool.query('SELECT * FROM get_student_repertoire($1)', [student], (err, result) => {
        if (err) {
          console.error('Error fetching repertoire:', err);
          return res.status(500).send('Internal Server Error');
        }
        if (result.rows.length === 0) {
          return res.render('repertoire', { title: 'Repertorio', students: estudiantes, repertoirs:false });
        }
        res.render('repertoire', { title: 'Repertorio', students: estudiantes, repertoirs: true, repertoire: result.rows });
      });
    } catch (err) {
      console.error('Error fetching repertoire:', err);
      return res.render('repertoire', { title: 'Repertorio', students: estudiantes, repertoirs:false });
    }
  }
});

app.get('/extra_class', async (req, res) => {
  const filas = await pool.query('SELECT * FROM check_students()');
  const estudiantes = filas.rows;
  res.render('extra_class', { title: 'Recuperación de clases', students: estudiantes });
});

app.post('/repertoire/add', async (req, res) => {
  const { estudiante_id, repertorio } = req.body;
  try {
    await pool.query('CALL add_repertoire($1, $2);', [estudiante_id, repertorio]);
    res.redirect('/repertoire'); 
  } catch (err) {
    console.error('Error guardando repertorio:', err);
    res.status(500).send('Error interno');
  }
}
);

app.get('/check_log', async (req, res) => {
  const results = await pool.query('SELECT * FROM check_students()');
  const estudiantes = results.rows;

  const student = req.query;

  if (!student) {
    return res.render('check_log', { title: 'Log de actividades', students: estudiantes, log:false });
  }

  else{
    pool.query('SELECT * FROM get_student_lesson_log($1)', [student], (err, result) => {
      if (err) {
        console.error('Error fetching log:', err);
        return res.status(500).send('Internal Server Error');
      }
      res.render('check_log', { title: 'Log de actividades', students: estudiantes, log: true, logs: result.rows });
    });
  }
 
}
);

app.get('/students/edit/:id', (req, res) => {
  const studentId = req.params.id;
  pool.query('SELECT * FROM check_student($1)', [studentId], (err, result) => {
    if (err) {
      console.error('Error fetching student:', err);
      return res.status(500).send('Internal Server Error');
    }
    if (result.rows.length === 0) {
      return res.status(404).send('Student not found');
    }
    res.render('edit_student', { title: 'Edit Student', student: result.rows[0] });
  });
}
);

app.post('/edit_student/edit', (req, res) => {
  const { random_forest, ident, val, dow } = req.body;
  pool.query('CALL edit_student($1, $2, $3, $4)', [random_forest, ident, val, dow], (err) => {
    if (err) {
      console.error('Error editing student:', err);
      return res.status(500).send('Internal Server Error');
    }
    
    res.redirect('/students');
  });
});


app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
