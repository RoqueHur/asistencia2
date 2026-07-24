<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.LocalTime" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Locale" %>
<%@ page import="com.eduasistencia.repository.AppRepository" %>
<%@ page import="com.eduasistencia.model.Attendance" %>
<%@ page import="com.eduasistencia.model.Student" %>
<%@ page import="com.eduasistencia.util.WebUtil" %>
<%
    if (!"PROFESOR".equals(session.getAttribute("role"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    request.setCharacterEncoding("UTF-8");
    AppRepository repo = AppRepository.getInstance();
    String action = request.getParameter("action");
    String requestedCourse = request.getParameter("course");
    String selectedPeriod = WebUtil.normalizePeriod(request.getParameter("period"));
    String selectedPeriodLabel = WebUtil.periodLabel(selectedPeriod);
    String message = null;
    String error = null;

    LocalDate selectedDate = LocalDate.now();
    String requestedDate = request.getParameter("date");
    if (requestedDate != null && !requestedDate.trim().isEmpty()) {
        try {
            selectedDate = LocalDate.parse(requestedDate);
        } catch (Exception ex) {
            error = "La fecha seleccionada no es válida.";
        }
    }

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

    List<Student> students = repo.getStudents();
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

    if ("POST".equalsIgnoreCase(request.getMethod()) && "save_attendance".equals(action)) {
        int saved = 0;
        int removed = 0;
        int skipped = 0;
        try {
            for (Student student : students) {
                String key = student.getCode();
                String statusValue = request.getParameter("status_" + key);
                if (statusValue == null || statusValue.trim().isEmpty()) {
                    skipped++;
                    continue;
                }

                if ("SIN_REGISTRAR".equalsIgnoreCase(statusValue)) {
                    if (repo.deleteAttendance(key, selectedDate, selectedCourse, selectedPeriod)) removed++;
                    continue;
                }

                String timeValue = request.getParameter("time_" + key);
                LocalTime attendanceTime = (timeValue == null || timeValue.trim().isEmpty())
                        ? LocalTime.now()
                        : LocalTime.parse(timeValue);
                int result = repo.upsertAttendance(key, selectedDate, attendanceTime,
                        WebUtil.normalizeStatus(statusValue), selectedCourse, selectedPeriod);
                if (result > 0) saved++; else skipped++;
            }
            message = "Lista de " + selectedCourse + " · " + selectedPeriodLabel + " guardada: " + saved
                    + " asistencia(s) registradas o actualizadas"
                    + (removed > 0 ? ", " + removed + " eliminada(s)" : "") + ".";
        } catch (Exception ex) {
            error = "No se pudo guardar la lista. Revisa las horas seleccionadas.";
        }
    }

    Locale spanish = new Locale("es", "PE");
    String dayName = selectedDate.format(DateTimeFormatter.ofPattern("EEEE", spanish));
    dayName = dayName.substring(0, 1).toUpperCase(spanish) + dayName.substring(1);
    String longDate = selectedDate.format(DateTimeFormatter.ofPattern("dd 'de' MMMM 'de' yyyy", spanish));
    String nowTime = LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm"));
    String encodedCourse = URLEncoder.encode(selectedCourse, "UTF-8");
    String encodedPeriod = URLEncoder.encode(selectedPeriod, "UTF-8");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lista de asistencia | EduAsistencia</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/assets/css/styles.css?v=20260722">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/assets/css/attendance-design.css?v=20260722">
</head>
<body class="attendance-page">
<div class="app-layout">
    <aside class="sidebar">
        <div class="brand"><span class="brand-mark">E</span><span><strong>EduAsistencia</strong><small>Panel docente</small></span></div>
        <nav>
            <a href="dashboard.jsp"><span>▦</span> Dashboard</a>
            <a href="asistencia.jsp?course=<%= encodedCourse %>&period=<%= encodedPeriod %>"><span>◉</span> Cámara QR</a>
            <a class="active" href="lista-asistencia.jsp"><span>☑</span> Lista de asistencia</a>
            <a href="alumnos.jsp"><span>♟</span> Alumnos</a>
            <a href="horarios.jsp"><span>▤</span> Horarios</a>
        </nav>
        <div class="sidebar-bottom"><a href="logout.jsp" class="danger-link">↪ Cerrar sesión</a></div>
    </aside>

    <div class="main-area">
        <header class="topbar">
            <button class="menu-toggle" type="button" data-menu-toggle>☰</button>
            <div><strong>Control diario de asistencia</strong><span class="top-date"><%= WebUtil.h(dayName + ", " + longDate) %></span></div>
            <div class="profile-chip"><span class="avatar">AR</span><span><strong><%= WebUtil.h((String)session.getAttribute("displayName")) %></strong><small>Profesor</small></span></div>
        </header>

        <main class="content">
            <section class="page-heading attendance-heading">
                <div>
                    <span class="eyebrow">Registro por lista</span>
                    <h1>Lista de estudiantes</h1>
                    <p>Marca la asistencia de cada alumno indicando curso, estado, día, fecha y hora.</p>
                </div>
                <div class="heading-actions">
                    <a class="btn btn-outline" href="asistencia.jsp?course=<%= encodedCourse %>&period=<%= encodedPeriod %>">▣ Usar cámara</a>
                    <button class="btn btn-primary" type="button" data-mark-all-present>✓ Todos presentes</button>
                </div>
            </section>

            <% if (message != null) { %><div class="alert alert-success"><%= WebUtil.h(message) %></div><% } %>
            <% if (error != null) { %><div class="alert alert-error"><%= WebUtil.h(error) %></div><% } %>

            <form method="get" class="attendance-overview-card">
                <input type="hidden" name="period" value="<%= WebUtil.h(selectedPeriod) %>">
                <div class="attendance-summary-grid">
                    <div class="attendance-summary-item">
                        <span class="attendance-summary-icon">◫</span>
                        <div><small>Día de clase</small><strong><%= WebUtil.h(dayName) %></strong></div>
                    </div>
                    <div class="attendance-summary-item">
                        <span class="attendance-summary-icon">▣</span>
                        <div><small>Fecha seleccionada</small><strong><%= WebUtil.h(longDate) %></strong></div>
                    </div>
                    <div class="attendance-summary-item">
                        <span class="attendance-summary-icon">◷</span>
                        <div><small>Hora actual</small><strong id="live-clock"><%= nowTime %></strong></div>
                    </div>
                    <label class="attendance-summary-item attendance-course-item" for="attendance-course">
                        <span class="attendance-summary-icon">▤</span>
                        <div>
                            <small>Curso</small>
                            <select id="attendance-course" name="course">
                                <% for (String courseOption : courses) { %>
                                    <option value="<%= WebUtil.h(courseOption) %>" <%= courseOption.equals(selectedCourse) ? "selected" : "" %>><%= WebUtil.h(courseOption) %></option>
                                <% } %>
                            </select>
                        </div>
                    </label>
                </div>

                <div class="attendance-overview-actions">
                    <label class="attendance-date-control" for="attendance-date">
                        <span>Fecha de la lista</span>
                        <input id="attendance-date" type="date" name="date" value="<%= selectedDate %>">
                    </label>
                    <button class="btn btn-light-action" type="submit">☷ Ver lista</button>
                    <button class="btn btn-light-action" type="button" data-modal-open="course-add-modal">＋ Agregar curso</button>
                    <button class="btn btn-light-danger" type="button" data-modal-open="course-remove-modal">− Quitar curso</button>
                </div>
            </form>

            <nav class="attendance-tabs" aria-label="Periodo académico">
                <a class="<%= "UNIDAD_1".equals(selectedPeriod) ? "active" : "" %>" href="lista-asistencia.jsp?course=<%= encodedCourse %>&date=<%= selectedDate %>&period=UNIDAD_1">UNIDAD 1</a>
                <a class="<%= "UNIDAD_2".equals(selectedPeriod) ? "active" : "" %>" href="lista-asistencia.jsp?course=<%= encodedCourse %>&date=<%= selectedDate %>&period=UNIDAD_2">UNIDAD 2</a>
                <a class="<%= "UNIDAD_3".equals(selectedPeriod) ? "active" : "" %>" href="lista-asistencia.jsp?course=<%= encodedCourse %>&date=<%= selectedDate %>&period=UNIDAD_3">UNIDAD 3</a>
                <a class="<%= "UNIDAD_4".equals(selectedPeriod) ? "active" : "" %>" href="lista-asistencia.jsp?course=<%= encodedCourse %>&date=<%= selectedDate %>&period=UNIDAD_4">UNIDAD 4</a>
                <a class="<%= "REGULAR".equals(selectedPeriod) ? "active" : "" %>" href="lista-asistencia.jsp?course=<%= encodedCourse %>&date=<%= selectedDate %>&period=REGULAR">REGULAR</a>
            </nav>

            <article class="panel attendance-list-panel">
                <div class="course-context-row"><span>▤ Curso seleccionado: <strong><%= WebUtil.h(selectedCourse) %></strong></span><span class="period-context-chip">Periodo: <strong><%= WebUtil.h(selectedPeriodLabel) %></strong></span></div>
                <div class="panel-head">
                    <div><h2>Asistencia de alumnos</h2><p><%= students.size() %> estudiantes · <%= WebUtil.h(selectedCourse) %> · <%= WebUtil.h(selectedPeriodLabel) %></p></div>
                    <input class="search-input" type="search" placeholder="Buscar estudiante..." data-table-search="daily-attendance-table">
                </div>

                <form method="post" id="attendance-list-form">
                    <input type="hidden" name="action" value="save_attendance">
                    <input type="hidden" name="date" value="<%= selectedDate %>">
                    <input type="hidden" name="course" value="<%= WebUtil.h(selectedCourse) %>">
                    <input type="hidden" name="period" value="<%= WebUtil.h(selectedPeriod) %>">
                    <div class="table-wrap">
                        <table id="daily-attendance-table" class="attendance-table">
                            <thead>
                            <tr>
                                <th>#</th>
                                <th>Código</th>
                                <th>Nombre completo</th>
                                <th>Día</th>
                                <th>Fecha</th>
                                <th>Hora</th>
                                <th>Estado de asistencia</th>
                                <th>Registro</th>
                            </tr>
                            </thead>
                            <tbody>
                            <% if (students.isEmpty()) { %>
                                <tr><td colspan="8" class="empty">No hay alumnos registrados. Agrégalos desde la sección Alumnos.</td></tr>
                            <% } %>
                            <% int rowNumber = 1; for (Student student : students) {
                                Attendance current = repo.findAttendanceByStudentDateCoursePeriod(student.getCode(), selectedDate, selectedCourse, selectedPeriod);
                                String currentStatus = current == null ? "SIN_REGISTRAR" : current.getStatus();
                                String currentTime = current == null ? nowTime : current.getTime().format(DateTimeFormatter.ofPattern("HH:mm"));
                            %>
                                <tr class="attendance-row" data-attendance-row>
                                    <td><strong><%= rowNumber++ %></strong></td>
                                    <td><span class="code-pill"><%= WebUtil.h(student.getCode()) %></span></td>
                                    <td><strong><%= WebUtil.h(student.getFullName()) %></strong><small class="table-sub"><%= WebUtil.h(student.getCourse()) %></small></td>
                                    <td><span class="day-chip"><%= WebUtil.h(dayName) %></span></td>
                                    <td><%= selectedDate.format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) %></td>
                                    <td><input class="table-time" type="time" name="time_<%= WebUtil.h(student.getCode()) %>" value="<%= currentTime %>" aria-label="Hora de <%= WebUtil.h(student.getFullName()) %>"></td>
                                    <td>
                                        <select class="table-status attendance-status" name="status_<%= WebUtil.h(student.getCode()) %>" aria-label="Estado de <%= WebUtil.h(student.getFullName()) %>">
                                            <option value="SIN_REGISTRAR" <%= "SIN_REGISTRAR".equals(currentStatus) ? "selected" : "" %>>Sin registrar</option>
                                            <option value="PRESENTE" <%= "PRESENTE".equals(currentStatus) ? "selected" : "" %>>Presente</option>
                                            <option value="TARDANZA" <%= "TARDANZA".equals(currentStatus) ? "selected" : "" %>>Tardanza</option>
                                            <option value="FALTA" <%= "FALTA".equals(currentStatus) ? "selected" : "" %>>Falta</option>
                                            <option value="JUSTIFICADO" <%= "JUSTIFICADO".equals(currentStatus) ? "selected" : "" %>>Justificado</option>
                                        </select>
                                    </td>
                                    <td>
                                        <% if (current == null) { %>
                                            <span class="record-state pending">Pendiente</span>
                                        <% } else { %>
                                            <span class="record-state saved">Guardado</span>
                                        <% } %>
                                    </td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                    <div class="attendance-form-footer">
                        <p><strong>Importante:</strong> selecciona “Sin registrar” y guarda para eliminar la asistencia de ese alumno en la fecha elegida.</p>
                        <div>
                            <button class="btn btn-outline" type="button" data-reset-attendance>Limpiar cambios</button>
                            <button class="btn btn-primary" type="submit">Guardar lista de asistencia</button>
                        </div>
                    </div>
                </form>
            </article>
        </main>
    </div>
</div>
<div class="modal" id="course-add-modal" aria-hidden="true">
    <div class="modal-backdrop" data-modal-close></div>
    <section class="modal-card modal-card-small">
        <div class="modal-head">
            <div><h2>Agregar curso</h2><p>El curso quedará disponible en Cámara QR y Lista de asistencia.</p></div>
            <button type="button" class="modal-close" data-modal-close>×</button>
        </div>
        <form method="post" class="form-stack">
            <input type="hidden" name="action" value="course_add">
            <input type="hidden" name="course" value="<%= WebUtil.h(selectedCourse) %>">
            <input type="hidden" name="date" value="<%= selectedDate %>">
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
            <input type="hidden" name="date" value="<%= selectedDate %>">
            <input type="hidden" name="period" value="<%= WebUtil.h(selectedPeriod) %>">
            <label class="field"><span>Curso a quitar *</span>
                <select name="courseToRemove" required>
                    <% for (String courseOption : courses) { %>
                        <option value="<%= WebUtil.h(courseOption) %>" <%= courseOption.equals(selectedCourse) ? "selected" : "" %>><%= WebUtil.h(courseOption) %></option>
                    <% } %>
                </select>
            </label>
            <div class="course-warning">No se borrarán las asistencias históricas. Si el curso está en uso, primero cambia sus asignaciones.</div>
            <div class="form-actions">
                <button type="button" class="btn btn-outline" data-modal-close>Cancelar</button>
                <button type="submit" class="btn btn-danger">Quitar curso</button>
            </div>
        </form>
    </section>
</div>

<script src="<%= request.getContextPath() %>/assets/js/app.js?v=20260722"></script>
</body>
</html>
