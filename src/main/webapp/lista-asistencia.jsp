<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
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
    List<Student> students = repo.getStudents();
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

    if ("POST".equalsIgnoreCase(request.getMethod())) {
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
                    if (repo.deleteAttendance(key, selectedDate)) removed++;
                    continue;
                }

                String timeValue = request.getParameter("time_" + key);
                LocalTime attendanceTime = (timeValue == null || timeValue.trim().isEmpty())
                        ? LocalTime.now()
                        : LocalTime.parse(timeValue);
                int result = repo.upsertAttendance(key, selectedDate, attendanceTime, WebUtil.normalizeStatus(statusValue));
                if (result > 0) saved++; else skipped++;
            }
            message = "Lista guardada: " + saved + " asistencia(s) registradas o actualizadas" +
                    (removed > 0 ? ", " + removed + " eliminada(s)" : "") + ".";
        } catch (Exception ex) {
            error = "No se pudo guardar la lista. Revisa las horas seleccionadas.";
        }
    }

    Locale spanish = new Locale("es", "PE");
    String dayName = selectedDate.format(DateTimeFormatter.ofPattern("EEEE", spanish));
    dayName = dayName.substring(0, 1).toUpperCase(spanish) + dayName.substring(1);
    String longDate = selectedDate.format(DateTimeFormatter.ofPattern("dd 'de' MMMM 'de' yyyy", spanish));
    String nowTime = LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm"));
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lista de asistencia | EduAsistencia</title>
    <link rel="stylesheet" href="assets/css/styles.css">
</head>
<body>
<div class="app-layout">
    <aside class="sidebar">
        <div class="brand"><span class="brand-mark">E</span><span><strong>EduAsistencia</strong><small>Panel docente</small></span></div>
        <nav>
            <a href="dashboard.jsp"><span>▦</span> Dashboard</a>
            <a href="asistencia.jsp"><span>◉</span> Cámara QR</a>
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
                    <p>Marca la asistencia de cada alumno indicando estado, día, fecha y hora.</p>
                </div>
                <div class="heading-actions">
                    <a class="btn btn-outline" href="asistencia.jsp">▣ Usar cámara</a>
                    <button class="btn btn-primary" type="button" data-mark-all-present>✓ Todos presentes</button>
                </div>
            </section>

            <% if (message != null) { %><div class="alert alert-success"><%= WebUtil.h(message) %></div><% } %>
            <% if (error != null) { %><div class="alert alert-error"><%= WebUtil.h(error) %></div><% } %>

            <section class="attendance-daybar">
                <div class="daybar-icon">▣</div>
                <div><small>Día de clase</small><strong><%= WebUtil.h(dayName) %></strong></div>
                <div><small>Fecha seleccionada</small><strong><%= WebUtil.h(longDate) %></strong></div>
                <div><small>Hora actual</small><strong id="live-clock"><%= nowTime %></strong></div>
                <form method="get" class="date-filter">
                    <label for="attendance-date">Cambiar fecha</label>
                    <input id="attendance-date" type="date" name="date" value="<%= selectedDate %>">
                    <button class="btn btn-secondary" type="submit">Ver lista</button>
                </form>
            </section>

            <section class="attendance-tabs" aria-label="Periodo académico">
                <span>UNIDAD 1</span><span>UNIDAD 2</span><span>UNIDAD 3</span><span class="active">UNIDAD 4</span><span>REGULAR</span>
            </section>

            <article class="panel attendance-list-panel">
                <div class="panel-head">
                    <div><h2>Asistencia de alumnos</h2><p><%= students.size() %> estudiantes · Lenguaje de Programación</p></div>
                    <input class="search-input" type="search" placeholder="Buscar estudiante..." data-table-search="daily-attendance-table">
                </div>

                <form method="post" id="attendance-list-form">
                    <input type="hidden" name="date" value="<%= selectedDate %>">
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
                                Attendance current = repo.findAttendanceByStudentAndDate(student.getCode(), selectedDate);
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
<script src="assets/js/app.js"></script>
</body>
</html>
