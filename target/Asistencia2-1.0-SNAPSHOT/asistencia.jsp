<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.LocalTime" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.List" %>
<%@ page import="com.eduasistencia.repository.AppRepository" %>
<%@ page import="com.eduasistencia.model.Attendance" %>
<%@ page import="com.eduasistencia.model.Schedule" %>
<%@ page import="com.eduasistencia.model.Student" %>
<%@ page import="com.eduasistencia.model.TeacherRecord" %>
<%@ page import="com.eduasistencia.util.WebUtil" %>
<%
    if (!"PROFESOR".equals(session.getAttribute("role"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    request.setCharacterEncoding("UTF-8");
    AppRepository repo = AppRepository.getInstance();
    String requestedCourse = request.getParameter("course");
    String selectedPeriod = WebUtil.normalizePeriod(request.getParameter("period"));
    String selectedPeriodLabel = WebUtil.periodLabel(selectedPeriod);
    String message = null;
    String error = null;
    String action = request.getParameter("action");

    if ("POST".equalsIgnoreCase(request.getMethod()) && "course_add".equals(action)) {
        String newCourse = request.getParameter("newCourse");
        String courseError = repo.addCourse(newCourse);
        if (courseError == null) {
            requestedCourse = newCourse == null ? null : newCourse.trim();
            message = "Curso agregado correctamente.";
        } else {
            error = courseError;
        }
    }

    if ("POST".equalsIgnoreCase(request.getMethod()) && "course_remove".equals(action)) {
        String courseToRemove = request.getParameter("courseToRemove");
        String courseError = repo.deleteCourse(courseToRemove);
        if (courseError == null) {
            if (requestedCourse != null && requestedCourse.equalsIgnoreCase(courseToRemove)) requestedCourse = null;
            message = "Curso quitado correctamente.";
        } else {
            error = courseError;
        }
    }

    List<String> courses = repo.getCourseOptions();
    String selectedCourse = requestedCourse;
    if (selectedCourse == null || selectedCourse.trim().isEmpty()) selectedCourse = repo.getDefaultCourse();
    boolean validCourse = false;
    for (String courseOption : courses) {
        if (courseOption.equalsIgnoreCase(selectedCourse.trim())) {
            selectedCourse = courseOption;
            validCourse = true;
            break;
        }
    }
    if (!validCourse) selectedCourse = courses.isEmpty() ? "Lenguaje de Programación" : courses.get(0);

    if ("POST".equalsIgnoreCase(request.getMethod()) && "teacher".equals(action)) {
        String type = "SALIDA".equals(request.getParameter("type")) ? "SALIDA" : "ENTRADA";
        TeacherRecord record = repo.registerTeacher(type, selectedCourse);
        message = "Asistencia docente registrada: " + record.getType() + " a las "
                + record.getTime().format(DateTimeFormatter.ofPattern("HH:mm"))
                + " en " + record.getCourse() + ".";
    }

    if ("POST".equalsIgnoreCase(request.getMethod()) && "student".equals(action)) {
        try {
            String code = request.getParameter("code");
            String status = WebUtil.normalizeStatus(request.getParameter("status"));
            LocalDate date = request.getParameter("date") == null || request.getParameter("date").isEmpty()
                    ? LocalDate.now() : LocalDate.parse(request.getParameter("date"));
            LocalTime time = request.getParameter("time") == null || request.getParameter("time").isEmpty()
                    ? LocalTime.now() : LocalTime.parse(request.getParameter("time"));
            int result = repo.registerAttendance(code, date, time, status, selectedCourse, selectedPeriod);
            if (result > 0) {
                Student markedStudent = repo.findStudentByCode(code);
                message = "Asistencia registrada para "
                        + (markedStudent == null ? code : markedStudent.getFullName())
                        + " en " + selectedCourse + " · " + selectedPeriodLabel + ".";
            } else if (result == -1) {
                error = "Ese alumno ya tiene asistencia registrada hoy en " + selectedCourse + " · " + selectedPeriodLabel + ".";
            } else {
                error = "No existe un alumno con el código ingresado.";
            }
        } catch (Exception ex) {
            error = "No se pudo registrar la asistencia. Revisa la fecha y la hora.";
        }
    }

    if (request.getParameter("eliminar") != null) {
        try {
            if (repo.deleteAttendance(Integer.parseInt(request.getParameter("eliminar")))) {
                message = "Registro de asistencia eliminado.";
            }
        } catch (NumberFormatException ex) {
            error = "Identificador de asistencia inválido.";
        }
    }

    List<Student> students = repo.getStudents();
    List<Attendance> records = repo.getAttendance();
    List<Attendance> recentCourseRecords = repo.getAttendanceForCourseOnDate(selectedCourse, LocalDate.now(), selectedPeriod);
    List<TeacherRecord> teacherRecords = repo.getTeacherRecords();
    TeacherRecord latestTeacherRecord = teacherRecords.isEmpty() ? null : teacherRecords.get(0);

    Schedule selectedSchedule = null;
    for (Schedule schedule : repo.getSchedules()) {
        if (schedule.getCourse().equalsIgnoreCase(selectedCourse)) {
            selectedSchedule = schedule;
            break;
        }
    }
    String encodedCourse = URLEncoder.encode(selectedCourse, "UTF-8");
    String encodedPeriod = URLEncoder.encode(selectedPeriod, "UTF-8");
    String currentTime = LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm"));
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Marcar asistencia | EduAsistencia</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/assets/css/styles.css?v=20260722">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/assets/css/attendance-design.css?v=20260722">
</head>
<body class="camera-page">
<div class="app-layout">
    <aside class="sidebar">
        <div class="brand"><span class="brand-mark">E</span><span><strong>EduAsistencia</strong><small>Panel docente</small></span></div>
        <nav>
            <a href="dashboard.jsp"><span>▦</span> Dashboard</a>
            <a class="active" href="asistencia.jsp"><span>◉</span> Cámara QR</a>
            <a href="lista-asistencia.jsp?course=<%= encodedCourse %>&period=<%= encodedPeriod %>"><span>☑</span> Lista de asistencia</a>
            <a href="alumnos.jsp"><span>♟</span> Alumnos</a>
            <a href="horarios.jsp"><span>▤</span> Horarios</a>
        </nav>
        <div class="sidebar-bottom"><a href="logout.jsp" class="danger-link">↪ Cerrar sesión</a></div>
    </aside>

    <div class="main-area">
        <header class="topbar">
            <button class="menu-toggle" type="button" data-menu-toggle>☰</button>
            <div><strong>Control de asistencia</strong><span class="top-date"><%= LocalDate.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) %></span></div>
            <div class="profile-chip"><span class="avatar">AR</span><span><strong><%= WebUtil.h((String)session.getAttribute("displayName")) %></strong><small>Profesor</small></span></div>
        </header>

        <main class="content">
            <section class="page-heading">
                <div>
                    <span class="eyebrow">Asistencia con cámara</span>
                    <h1>Marcar asistencia</h1>
                    <p>Selecciona el curso y escanea el código QR del alumno.</p>
                </div>
            </section>

            <% if (message != null) { %><div class="alert alert-success"><%= WebUtil.h(message) %></div><% } %>
            <% if (error != null) { %><div class="alert alert-error"><%= WebUtil.h(error) %></div><% } %>

            <section class="course-session-card">
                <div class="course-session-icon">▤</div>
                <div class="course-session-copy">
                    <small>Curso en el que estás tomando asistencia</small>
                    <strong><%= WebUtil.h(selectedCourse) %></strong>
                    <span>
                        <%= selectedSchedule == null ? "Horario no configurado para este curso" : WebUtil.h(selectedSchedule.getDay() + " · " + selectedSchedule.getStartTime() + " a " + selectedSchedule.getEndTime() + " · " + selectedSchedule.getClassroom()) %>
                    </span>
                </div>
                <span class="course-session-badge">Curso activo · <%= WebUtil.h(selectedPeriodLabel) %></span>
            </section>

            <form method="get" class="course-control-bar">
                <input type="hidden" name="period" value="<%= WebUtil.h(selectedPeriod) %>">
                <label class="course-control-select" for="course-select">
                    <span>Cambiar curso</span>
                    <select id="course-select" name="course">
                        <% for (String courseOption : courses) { %>
                            <option value="<%= WebUtil.h(courseOption) %>" <%= courseOption.equals(selectedCourse) ? "selected" : "" %>><%= WebUtil.h(courseOption) %></option>
                        <% } %>
                    </select>
                </label>
                <button class="btn btn-primary" type="submit">Aplicar</button>
                <button class="btn btn-course-add" type="button" data-modal-open="course-add-modal">＋ Agregar curso</button>
                <button class="btn btn-course-remove" type="button" data-modal-open="course-remove-modal">− Quitar curso</button>
            </form>

            <section class="scanner-layout">
                <article class="scanner-panel">
                    <div class="scanner-toolbar">
                        <button class="tool-button active" type="button" title="Cámara">▣</button>
                        <button class="tool-button" type="button" id="camera-toggle" title="Encender o apagar">◉</button>
                        <span id="camera-status">Cámara lista para iniciar</span>
                    </div>

                    <div class="camera-frame" id="camera-frame">
                        <video id="camera-video" playsinline muted></video>
                        <div class="camera-placeholder" id="camera-placeholder">
                            <span class="camera-symbol">⌗</span>
                            <strong>Presiona “Encender cámara”</strong>
                            <small>Permite el acceso cuando el navegador lo solicite.</small>
                        </div>
                        <div class="scan-corners"><i></i><i></i><i></i><i></i></div>
                    </div>

                    <div class="scan-progress"><span id="scan-message">Esperando lectura QR…</span><div><i></i></div></div>
                    <button class="btn btn-primary btn-block" type="button" id="start-camera">Encender cámara</button>

                    <div class="current-marking-card">
                        <span class="live-dot"></span>
                        <div>
                            <small>Actualmente estás marcando asistencia de</small>
                            <strong><%= WebUtil.h(selectedCourse) %> · <%= WebUtil.h(selectedPeriodLabel) %></strong>
                            <span><%= LocalDate.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) %> · <span id="scanner-live-clock"><%= currentTime %></span> · Estado automático: Presente</span>
                        </div>
                    </div>

                    <form method="post" id="scan-form">
                        <input type="hidden" name="action" value="student">
                        <input type="hidden" name="course" id="scan-course" value="<%= WebUtil.h(selectedCourse) %>">
                        <input type="hidden" name="period" value="<%= WebUtil.h(selectedPeriod) %>">
                        <input type="hidden" name="code" id="scan-code">
                        <input type="hidden" name="status" value="PRESENTE">
                    </form>

                    <section class="recent-scans">
                        <div class="recent-scans-head">
                            <div><h3>Alumnos marcados en esta clase</h3><p>Registros de hoy para <%= WebUtil.h(selectedCourse) %> · <%= WebUtil.h(selectedPeriodLabel) %>.</p></div>
                            <span><%= recentCourseRecords.size() %> registrados</span>
                        </div>
                        <div class="recent-scan-list">
                            <% if (recentCourseRecords.isEmpty()) { %>
                                <div class="recent-scan-empty">Todavía no se ha marcado ningún alumno en <strong><%= WebUtil.h(selectedCourse) %></strong>.</div>
                            <% } %>
                            <% for (int i = 0; i < Math.min(5, recentCourseRecords.size()); i++) {
                                Attendance attendanceRecord = recentCourseRecords.get(i);
                                Student attendanceStudent = repo.findStudentByCode(attendanceRecord.getStudentCode());
                            %>
                                <div class="recent-scan-item">
                                    <span class="recent-avatar"><%= WebUtil.h(attendanceStudent == null ? "A" : attendanceStudent.getFullName().substring(0, 1).toUpperCase()) %></span>
                                    <div>
                                        <strong><%= WebUtil.h(attendanceStudent == null ? attendanceRecord.getStudentCode() : attendanceStudent.getFullName()) %></strong>
                                        <small><%= WebUtil.h(attendanceRecord.getStudentCode()) %> · <%= WebUtil.h(attendanceRecord.getCourse()) %> · <%= WebUtil.h(WebUtil.periodLabel(attendanceRecord.getPeriod())) %></small>
                                    </div>
                                    <span class="badge <%= attendanceRecord.getStatus().toLowerCase() %>"><%= attendanceRecord.getStatus() %></span>
                                    <time><%= attendanceRecord.getTime().format(DateTimeFormatter.ofPattern("HH:mm")) %></time>
                                </div>
                            <% } %>
                        </div>
                    </section>
                </article>

                <aside class="instruction-panel">
                    <h3>Instrucciones</h3>
                    <ol>
                        <li><span>1</span><p>Confirma que el curso seleccionado sea el correcto.</p></li>
                        <li><span>2</span><p>Pide al estudiante mostrar su código QR frente a la cámara.</p></li>
                        <li><span>3</span><p>Mantén el código dentro del recuadro verde.</p></li>
                        <li><span>4</span><p>El alumno aparecerá debajo de la cámara al registrarse.</p></li>
                    </ol>

                    <div class="teacher-check">
                        <h4>Mi asistencia docente</h4>
                        <p>Registra tu entrada o salida para el curso seleccionado.</p>
                        <form method="post">
                            <input type="hidden" name="action" value="teacher">
                            <input type="hidden" name="course" value="<%= WebUtil.h(selectedCourse) %>">
                            <input type="hidden" name="period" value="<%= WebUtil.h(selectedPeriod) %>">
                            <button class="btn btn-secondary btn-block" name="type" value="ENTRADA">Registrar entrada</button>
                            <button class="btn btn-outline btn-block" name="type" value="SALIDA">Registrar salida</button>
                        </form>

                        <div class="teacher-current-record">
                            <small>Último registro realizado</small>
                            <% if (latestTeacherRecord == null) { %>
                                <strong>Sin marcación</strong>
                                <span>Registra tu entrada para comenzar.</span>
                            <% } else { %>
                                <strong><span class="teacher-type <%= latestTeacherRecord.getType().toLowerCase() %>"><%= latestTeacherRecord.getType() %></span> <%= latestTeacherRecord.getTime().format(DateTimeFormatter.ofPattern("HH:mm")) %></strong>
                                <span><%= WebUtil.h(latestTeacherRecord.getCourse()) %> · <%= latestTeacherRecord.getDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) %></span>
                            <% } %>
                        </div>

                        <% if (!teacherRecords.isEmpty()) { %>
                            <div class="teacher-record-history">
                                <% for (int i = 0; i < Math.min(3, teacherRecords.size()); i++) {
                                    TeacherRecord teacherRecord = teacherRecords.get(i);
                                %>
                                    <div><span class="teacher-type <%= teacherRecord.getType().toLowerCase() %>"><%= teacherRecord.getType() %></span><p><strong><%= teacherRecord.getTime().format(DateTimeFormatter.ofPattern("HH:mm")) %></strong><small><%= WebUtil.h(teacherRecord.getCourse()) %></small></p></div>
                                <% } %>
                            </div>
                        <% } %>
                    </div>

                    <button class="btn btn-dark btn-block" type="button" data-modal-open="attendance-modal">Marcar manualmente</button>
                </aside>
            </section>

            <section class="stats-grid compact">
                <article class="stat-card"><span class="stat-icon blue">♟</span><div><small>Total estudiantes</small><strong><%= students.size() %></strong></div></article>
                <article class="stat-card"><span class="stat-icon green">✓</span><div><small>Presentes en el curso</small><strong><%= repo.countStatusToday("PRESENTE", selectedCourse, selectedPeriod) %></strong></div></article>
                <article class="stat-card"><span class="stat-icon yellow">◷</span><div><small>Tardanzas en el curso</small><strong><%= repo.countStatusToday("TARDANZA", selectedCourse, selectedPeriod) %></strong></div></article>
                <article class="stat-card"><span class="stat-icon red">×</span><div><small>Faltas en el curso</small><strong><%= repo.countStatusToday("FALTA", selectedCourse, selectedPeriod) %></strong></div></article>
            </section>

            <article class="panel">
                <div class="panel-head">
                    <div><h2>Historial de asistencia</h2><p>Incluye el curso en el que se realizó cada marcación.</p></div>
                    <input class="search-input" type="search" placeholder="Buscar..." data-table-search="attendance-table">
                </div>
                <div class="table-wrap">
                    <table id="attendance-table">
                        <thead><tr><th>Alumno</th><th>Curso</th><th>Periodo</th><th>Fecha</th><th>Hora</th><th>Estado</th><th>Acción</th></tr></thead>
                        <tbody>
                        <% if (records.isEmpty()) { %><tr><td colspan="7" class="empty">No hay asistencias.</td></tr><% } %>
                        <% for (Attendance attendanceRecord : records) {
                            Student attendanceStudent = repo.findStudentByCode(attendanceRecord.getStudentCode());
                        %>
                            <tr>
                                <td><strong><%= WebUtil.h(attendanceStudent == null ? attendanceRecord.getStudentCode() : attendanceStudent.getFullName()) %></strong><small class="table-sub"><%= WebUtil.h(attendanceRecord.getStudentCode()) %></small></td>
                                <td><span class="course-table-chip"><%= WebUtil.h(attendanceRecord.getCourse()) %></span></td>
                                <td><span class="period-table-chip"><%= WebUtil.h(WebUtil.periodLabel(attendanceRecord.getPeriod())) %></span></td>
                                <td><%= attendanceRecord.getDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) %></td>
                                <td><%= attendanceRecord.getTime().format(DateTimeFormatter.ofPattern("HH:mm")) %></td>
                                <td><span class="badge <%= attendanceRecord.getStatus().toLowerCase() %>"><%= attendanceRecord.getStatus() %></span></td>
                                <td><a class="btn-icon danger" href="asistencia.jsp?course=<%= encodedCourse %>&period=<%= encodedPeriod %>&eliminar=<%= attendanceRecord.getId() %>" data-confirm="¿Eliminar este registro de asistencia?">Eliminar</a></td>
                            </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </article>
        </main>
    </div>
</div>

<div class="modal" id="course-add-modal" aria-hidden="true">
    <div class="modal-backdrop" data-modal-close></div>
    <section class="modal-card modal-card-small">
        <div class="modal-head">
            <div><h2>Agregar curso</h2><p>El nuevo curso aparecerá en los selectores de asistencia.</p></div>
            <button type="button" class="modal-close" data-modal-close>×</button>
        </div>
        <form method="post" class="form-stack">
            <input type="hidden" name="action" value="course_add">
            <input type="hidden" name="course" value="<%= WebUtil.h(selectedCourse) %>">
            <input type="hidden" name="period" value="<%= WebUtil.h(selectedPeriod) %>">
            <label class="field"><span>Nombre del curso *</span><input type="text" name="newCourse" maxlength="80" required placeholder="Ejemplo: Programación Web II"></label>
            <div class="form-actions">
                <button type="button" class="btn btn-outline" data-modal-close>Cancelar</button>
                <button type="submit" class="btn btn-primary">Agregar curso</button>
            </div>
        </form>
    </section>
</div>

<div class="modal" id="course-remove-modal" aria-hidden="true">
    <div class="modal-backdrop" data-modal-close></div>
    <section class="modal-card modal-card-small">
        <div class="modal-head">
            <div><h2>Quitar curso</h2><p>Solo se puede quitar un curso que no esté asignado a alumnos ni horarios.</p></div>
            <button type="button" class="modal-close" data-modal-close>×</button>
        </div>
        <form method="post" class="form-stack">
            <input type="hidden" name="action" value="course_remove">
            <input type="hidden" name="course" value="<%= WebUtil.h(selectedCourse) %>">
            <input type="hidden" name="period" value="<%= WebUtil.h(selectedPeriod) %>">
            <label class="field"><span>Curso a quitar *</span>
                <select name="courseToRemove" required>
                    <% for (String courseOption : courses) { %>
                        <option value="<%= WebUtil.h(courseOption) %>" <%= courseOption.equals(selectedCourse) ? "selected" : "" %>><%= WebUtil.h(courseOption) %></option>
                    <% } %>
                </select>
            </label>
            <div class="course-warning">No se eliminan las asistencias históricas. Si el curso está en uso, primero debes cambiar sus asignaciones.</div>
            <div class="form-actions">
                <button type="button" class="btn btn-outline" data-modal-close>Cancelar</button>
                <button type="submit" class="btn btn-danger">Quitar curso</button>
            </div>
        </form>
    </section>
</div>

<div class="modal" id="attendance-modal" aria-hidden="true">
    <div class="modal-backdrop" data-modal-close></div>
    <section class="modal-card">
        <div class="modal-head">
            <div><h2>Marcar manualmente</h2><p>La asistencia se guardará en <strong><%= WebUtil.h(selectedCourse) %> · <%= WebUtil.h(selectedPeriodLabel) %></strong>.</p></div>
            <button type="button" class="modal-close" data-modal-close>×</button>
        </div>
        <form method="post" class="form-grid">
            <input type="hidden" name="action" value="student">
            <input type="hidden" name="course" value="<%= WebUtil.h(selectedCourse) %>">
            <input type="hidden" name="period" value="<%= WebUtil.h(selectedPeriod) %>">
            <label class="field"><span>Curso</span><input value="<%= WebUtil.h(selectedCourse) %>" readonly></label>
            <label class="field"><span>Periodo</span><input value="<%= WebUtil.h(selectedPeriodLabel) %>" readonly></label>
            <label class="field span-2"><span>Alumno *</span><select name="code" required><% for (Student student : students) { %><option value="<%= WebUtil.h(student.getCode()) %>"><%= WebUtil.h(student.getCode() + " — " + student.getFullName()) %></option><% } %></select></label>
            <label class="field"><span>Fecha</span><input type="date" name="date" value="<%= LocalDate.now() %>"></label>
            <label class="field"><span>Hora</span><input type="time" name="time" value="<%= LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm")) %>"></label>
            <label class="field span-2"><span>Estado</span><select name="status"><option>PRESENTE</option><option>TARDANZA</option><option>FALTA</option><option>JUSTIFICADO</option></select></label>
            <div class="form-actions span-2"><button type="button" class="btn btn-secondary" data-modal-close>Cancelar</button><button class="btn btn-primary" type="submit">Registrar asistencia</button></div>
        </form>
    </section>
</div>
<script src="<%= request.getContextPath() %>/assets/js/app.js?v=20260722"></script>
<script src="<%= request.getContextPath() %>/assets/js/camera.js?v=20260722"></script>
</body>
</html>
