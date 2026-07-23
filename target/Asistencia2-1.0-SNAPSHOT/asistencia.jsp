<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.LocalTime" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.List" %>
<%@ page import="com.eduasistencia.repository.AppRepository" %>
<%@ page import="com.eduasistencia.model.Attendance" %>
<%@ page import="com.eduasistencia.model.Student" %>
<%@ page import="com.eduasistencia.model.TeacherRecord" %>
<%@ page import="com.eduasistencia.util.WebUtil" %>
<%
    if (!"PROFESOR".equals(session.getAttribute("role"))) { response.sendRedirect("login.jsp"); return; }
    request.setCharacterEncoding("UTF-8");
    AppRepository repo = AppRepository.getInstance();
    String message = null, error = null;

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        if ("teacher".equals(action)) {
            TeacherRecord record = repo.registerTeacher("SALIDA".equals(request.getParameter("type")) ? "SALIDA" : "ENTRADA");
            message = "Asistencia docente registrada: " + record.getType() + " a las " + record.getTime().format(DateTimeFormatter.ofPattern("HH:mm")) + ".";
        } else {
            try {
                String code = request.getParameter("code");
                String status = WebUtil.normalizeStatus(request.getParameter("status"));
                LocalDate date = request.getParameter("date") == null || request.getParameter("date").isEmpty() ? LocalDate.now() : LocalDate.parse(request.getParameter("date"));
                LocalTime time = request.getParameter("time") == null || request.getParameter("time").isEmpty() ? LocalTime.now() : LocalTime.parse(request.getParameter("time"));
                int result = repo.registerAttendance(code, date, time, status);
                if (result > 0) message = "Asistencia registrada correctamente para el código " + WebUtil.h(code) + ".";
                else if (result == -1) error = "Ese alumno ya tiene asistencia registrada en la fecha seleccionada.";
                else error = "No existe un alumno con el código ingresado.";
            } catch (Exception ex) { error = "No se pudo registrar la asistencia. Revisa la fecha y la hora."; }
        }
    }

    if (request.getParameter("eliminar") != null) {
        try { if (repo.deleteAttendance(Integer.parseInt(request.getParameter("eliminar")))) message = "Registro de asistencia eliminado."; }
        catch (NumberFormatException ex) { error = "Identificador de asistencia inválido."; }
    }

    List<Student> students = repo.getStudents();
    List<Attendance> records = repo.getAttendance();
%>
<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Marcar asistencia | EduAsistencia</title><link rel="stylesheet" href="assets/css/styles.css"></head><body>
<div class="app-layout"><aside class="sidebar"><div class="brand"><span class="brand-mark">E</span><span><strong>EduAsistencia</strong><small>Panel docente</small></span></div><nav><a href="dashboard.jsp"><span>▦</span> Dashboard</a><a class="active" href="asistencia.jsp"><span>◉</span> Cámara QR</a><a href="lista-asistencia.jsp"><span>☑</span> Lista de asistencia</a><a href="alumnos.jsp"><span>♟</span> Alumnos</a><a href="horarios.jsp"><span>▤</span> Horarios</a></nav><div class="sidebar-bottom"><a href="logout.jsp" class="danger-link">↪ Cerrar sesión</a></div></aside>
<div class="main-area"><header class="topbar"><button class="menu-toggle" type="button" data-menu-toggle>☰</button><div><strong>Control de asistencia</strong></div><div class="profile-chip"><span class="avatar">AR</span><span><strong><%= WebUtil.h((String)session.getAttribute("displayName")) %></strong><small>Profesor</small></span></div></header>
<main class="content"><section class="page-heading"><div><span class="eyebrow">Asistencia con cámara</span><h1>Marcar asistencia</h1><p>Escanea el código QR del alumno o registra su código manualmente.</p></div></section>
<% if (message != null) { %><div class="alert alert-success"><%= message %></div><% } %><% if (error != null) { %><div class="alert alert-error"><%= WebUtil.h(error) %></div><% } %>

<section class="scanner-layout">
    <article class="scanner-panel">
        <div class="scanner-toolbar"><button class="tool-button active" type="button" title="Cámara">▣</button><button class="tool-button" type="button" id="camera-toggle" title="Encender o apagar">◉</button><span id="camera-status">Cámara lista para iniciar</span></div>
        <div class="camera-frame" id="camera-frame"><video id="camera-video" playsinline muted></video><div class="camera-placeholder" id="camera-placeholder"><span class="camera-symbol">⌗</span><strong>Presiona “Encender cámara”</strong><small>Permite el acceso cuando el navegador lo solicite.</small></div><div class="scan-corners"><i></i><i></i><i></i><i></i></div></div>
        <div class="scan-progress"><span id="scan-message">Esperando lectura QR…</span><div><i></i></div></div>
        <button class="btn btn-primary btn-block" type="button" id="start-camera">Encender cámara</button>
        <form method="post" id="scan-form"><input type="hidden" name="action" value="student"><input type="hidden" name="code" id="scan-code"><input type="hidden" name="status" value="PRESENTE"></form>
    </article>

    <aside class="instruction-panel">
        <h3>Instrucciones</h3><ol><li><span>1</span><p>Pide al estudiante mostrar su código QR frente a la cámara.</p></li><li><span>2</span><p>Mantén el código dentro del recuadro verde.</p></li><li><span>3</span><p>La asistencia se registrará automáticamente.</p></li></ol>
        <div class="teacher-check"><h4>Mi asistencia docente</h4><p>Registra tu entrada o salida del aula.</p><form method="post"><input type="hidden" name="action" value="teacher"><button class="btn btn-secondary btn-block" name="type" value="ENTRADA">Registrar entrada</button><button class="btn btn-outline btn-block" name="type" value="SALIDA">Registrar salida</button></form></div>
        <button class="btn btn-dark btn-block" type="button" data-modal-open="attendance-modal">Marcar manualmente</button>
    </aside>
</section>

<section class="stats-grid compact"><article class="stat-card"><span class="stat-icon blue">♟</span><div><small>Total estudiantes</small><strong><%= students.size() %></strong></div></article><article class="stat-card"><span class="stat-icon green">✓</span><div><small>Presentes hoy</small><strong><%= repo.countStatusToday("PRESENTE") %></strong></div></article><article class="stat-card"><span class="stat-icon yellow">◷</span><div><small>Tardanzas</small><strong><%= repo.countStatusToday("TARDANZA") %></strong></div></article><article class="stat-card"><span class="stat-icon red">×</span><div><small>Faltas</small><strong><%= repo.countStatusToday("FALTA") %></strong></div></article></section>

<article class="panel"><div class="panel-head"><div><h2>Historial de asistencia</h2><p>Los registros pueden eliminarse individualmente.</p></div><input class="search-input" type="search" placeholder="Buscar..." data-table-search="attendance-table"></div><div class="table-wrap"><table id="attendance-table"><thead><tr><th>Alumno</th><th>Fecha</th><th>Hora</th><th>Estado</th><th>Acción</th></tr></thead><tbody>
<% if (records.isEmpty()) { %><tr><td colspan="5" class="empty">No hay asistencias.</td></tr><% } %>
<% for (Attendance a : records) { Student s = repo.findStudentByCode(a.getStudentCode()); %><tr><td><strong><%= WebUtil.h(s == null ? a.getStudentCode() : s.getFullName()) %></strong><small class="table-sub"><%= WebUtil.h(a.getStudentCode()) %></small></td><td><%= a.getDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) %></td><td><%= a.getTime().format(DateTimeFormatter.ofPattern("HH:mm")) %></td><td><span class="badge <%= a.getStatus().toLowerCase() %>"><%= a.getStatus() %></span></td><td><a class="btn-icon danger" href="asistencia.jsp?eliminar=<%= a.getId() %>" data-confirm="¿Eliminar este registro de asistencia?">Eliminar</a></td></tr><% } %>
</tbody></table></div></article>
</main></div></div>

<div class="modal" id="attendance-modal" aria-hidden="true"><div class="modal-backdrop" data-modal-close></div><section class="modal-card"><div class="modal-head"><div><h2>Marcar manualmente</h2><p>Selecciona el alumno y el estado.</p></div><button type="button" class="modal-close" data-modal-close>×</button></div><form method="post" class="form-grid"><input type="hidden" name="action" value="student"><label class="field span-2"><span>Alumno *</span><select name="code" required><% for (Student s : students) { %><option value="<%= WebUtil.h(s.getCode()) %>"><%= WebUtil.h(s.getCode() + " — " + s.getFullName()) %></option><% } %></select></label><label class="field"><span>Fecha</span><input type="date" name="date" value="<%= LocalDate.now() %>"></label><label class="field"><span>Hora</span><input type="time" name="time" value="<%= LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm")) %>"></label><label class="field span-2"><span>Estado</span><select name="status"><option>PRESENTE</option><option>TARDANZA</option><option>FALTA</option><option>JUSTIFICADO</option></select></label><div class="form-actions span-2"><button type="button" class="btn btn-secondary" data-modal-close>Cancelar</button><button class="btn btn-primary" type="submit">Registrar asistencia</button></div></form></section></div>
<script src="assets/js/app.js"></script><script src="assets/js/camera.js"></script></body></html>
