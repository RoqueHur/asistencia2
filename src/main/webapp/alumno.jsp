<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.List" %>
<%@ page import="com.eduasistencia.repository.AppRepository" %>
<%@ page import="com.eduasistencia.model.Student" %>
<%@ page import="com.eduasistencia.model.Attendance" %>
<%@ page import="com.eduasistencia.model.Schedule" %>
<%@ page import="com.eduasistencia.util.WebUtil" %>
<%
    if (!"ALUMNO".equals(session.getAttribute("role"))) { response.sendRedirect("login.jsp"); return; }
    AppRepository repo = AppRepository.getInstance();
    String code = (String) session.getAttribute("studentCode");
    Student student = repo.findStudentByCode(code);
    if (student == null) { session.invalidate(); response.sendRedirect("login.jsp"); return; }
    List<Attendance> records = repo.getAttendanceByStudent(code);
    List<Schedule> schedules = repo.getSchedules();
    long present = records.stream().filter(a -> "PRESENTE".equals(a.getStatus())).count();
    long late = records.stream().filter(a -> "TARDANZA".equals(a.getStatus())).count();
    long absent = records.stream().filter(a -> "FALTA".equals(a.getStatus())).count();
%>
<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Portal del alumno | EduAsistencia</title><link rel="stylesheet" href="assets/css/styles.css"></head><body class="student-body">
<header class="student-topbar"><div class="brand"><span class="brand-mark">E</span><span><strong>EduAsistencia</strong><small>Portal del alumno</small></span></div><div class="student-actions"><span class="profile-chip"><span class="avatar"><%= WebUtil.h(student.getFullName().substring(0,1).toUpperCase()) %></span><span><strong><%= WebUtil.h(student.getFullName()) %></strong><small><%= WebUtil.h(student.getCode()) %></small></span></span><a class="btn btn-outline" href="logout.jsp">Cerrar sesión</a></div></header>
<main class="student-content">
<section class="student-hero"><div><span class="eyebrow">Mi portal académico</span><h1>Hola, <%= WebUtil.h(student.getFullName()) %></h1><p><%= WebUtil.h(student.getProgram()) %> · <%= WebUtil.h(student.getCourse()) %></p></div><div class="qr-card"><img src="assets/qr/<%= WebUtil.h(student.getCode()) %>.png" alt="Código QR personal" onerror="this.style.display='none';this.nextElementSibling.style.display='block'"><div class="qr-fallback">Código: <strong><%= WebUtil.h(student.getCode()) %></strong></div><span>Mi código de asistencia</span><a download="QR-<%= WebUtil.h(student.getCode()) %>.png" href="assets/qr/<%= WebUtil.h(student.getCode()) %>.png">Descargar QR</a></div></section>
<section class="stats-grid compact"><article class="stat-card"><span class="stat-icon green">✓</span><div><small>Asistencias</small><strong><%= present %></strong></div></article><article class="stat-card"><span class="stat-icon yellow">◷</span><div><small>Tardanzas</small><strong><%= late %></strong></div></article><article class="stat-card"><span class="stat-icon red">×</span><div><small>Faltas</small><strong><%= absent %></strong></div></article><article class="stat-card"><span class="stat-icon blue">%</span><div><small>Porcentaje</small><strong><%= records.isEmpty() ? 0 : Math.round((present * 100.0) / records.size()) %>%</strong></div></article></section>
<section class="student-grid">
<article class="panel"><div class="panel-head"><div><h2>Mi horario</h2><p>Clases programadas por el profesor.</p></div><a class="btn btn-secondary" href="descargar-horario.jsp">Descargar CSV</a></div><div class="table-wrap"><table><thead><tr><th>Día</th><th>Curso</th><th>Horario</th><th>Aula</th></tr></thead><tbody><% for (Schedule s : schedules) { %><tr><td><strong><%= WebUtil.h(s.getDay()) %></strong></td><td><%= WebUtil.h(s.getCourse()) %></td><td><%= WebUtil.h(s.getStartTime()) %> – <%= WebUtil.h(s.getEndTime()) %></td><td><%= WebUtil.h(s.getClassroom()) %></td></tr><% } %></tbody></table></div></article>
<article class="panel"><div class="panel-head"><div><h2>Mi asistencia</h2><p>Consulta tus registros.</p></div><a class="btn btn-secondary" href="descargar-asistencia.jsp">Descargar CSV</a></div><div class="table-wrap"><table><thead><tr><th>Fecha</th><th>Hora</th><th>Estado</th></tr></thead><tbody><% if (records.isEmpty()) { %><tr><td colspan="3" class="empty">No hay registros.</td></tr><% } %><% for (Attendance a : records) { %><tr><td><%= a.getDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) %></td><td><%= a.getTime().format(DateTimeFormatter.ofPattern("HH:mm")) %></td><td><span class="badge <%= a.getStatus().toLowerCase() %>"><%= a.getStatus() %></span></td></tr><% } %></tbody></table></div></article>
</section></main><script src="assets/js/app.js"></script></body></html>
