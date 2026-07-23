<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="com.eduasistencia.repository.AppRepository" %>
<%@ page import="com.eduasistencia.model.Schedule" %>
<%@ page import="com.eduasistencia.util.WebUtil" %>
<%
    if (!"PROFESOR".equals(session.getAttribute("role"))) { response.sendRedirect("login.jsp"); return; }
    request.setCharacterEncoding("UTF-8");
    AppRepository repo = AppRepository.getInstance();
    String message = null, error = null;
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String result = repo.addSchedule(request.getParameter("day"), request.getParameter("course"), request.getParameter("start"), request.getParameter("end"), request.getParameter("classroom"));
        if (result == null) message = "Horario agregado correctamente."; else error = result;
    }
    if (request.getParameter("eliminar") != null) {
        try { if (repo.deleteSchedule(Integer.parseInt(request.getParameter("eliminar")))) message = "Horario eliminado correctamente."; }
        catch (NumberFormatException ex) { error = "Identificador de horario inválido."; }
    }
    List<Schedule> schedules = repo.getSchedules();
%>
<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Horarios | EduAsistencia</title><link rel="stylesheet" href="assets/css/styles.css"></head><body>
<div class="app-layout"><aside class="sidebar"><div class="brand"><span class="brand-mark">E</span><span><strong>EduAsistencia</strong><small>Panel docente</small></span></div><nav><a href="dashboard.jsp"><span>▦</span> Dashboard</a><a href="asistencia.jsp"><span>◉</span> Cámara QR</a><a href="lista-asistencia.jsp"><span>☑</span> Lista de asistencia</a><a href="alumnos.jsp"><span>♟</span> Alumnos</a><a class="active" href="horarios.jsp"><span>▤</span> Horarios</a></nav><div class="sidebar-bottom"><a href="logout.jsp" class="danger-link">↪ Cerrar sesión</a></div></aside>
<div class="main-area"><header class="topbar"><button class="menu-toggle" type="button" data-menu-toggle>☰</button><div><strong>Gestión de horarios</strong></div><div class="profile-chip"><span class="avatar">AR</span><span><strong><%= WebUtil.h((String)session.getAttribute("displayName")) %></strong><small>Profesor</small></span></div></header>
<main class="content"><section class="page-heading"><div><span class="eyebrow">Programación académica</span><h1>Horarios</h1><p>Agrega o elimina clases visibles para los estudiantes.</p></div><button class="btn btn-primary" type="button" data-modal-open="schedule-modal">＋ Nuevo horario</button></section>
<% if (message != null) { %><div class="alert alert-success"><%= message %></div><% } %><% if (error != null) { %><div class="alert alert-error"><%= WebUtil.h(error) %></div><% } %>
<section class="schedule-grid">
<% if (schedules.isEmpty()) { %><article class="panel empty">No hay horarios registrados.</article><% } %>
<% for (Schedule s : schedules) { %><article class="schedule-card"><div class="schedule-day"><span><%= WebUtil.h(s.getDay()) %></span><strong><%= WebUtil.h(s.getStartTime()) %> – <%= WebUtil.h(s.getEndTime()) %></strong></div><div class="schedule-info"><h3><%= WebUtil.h(s.getCourse()) %></h3><p>⌖ <%= WebUtil.h(s.getClassroom()) %></p></div><a class="btn-icon danger" href="horarios.jsp?eliminar=<%= s.getId() %>" data-confirm="¿Eliminar este horario?">Eliminar</a></article><% } %>
</section></main></div></div>
<div class="modal" id="schedule-modal" aria-hidden="true"><div class="modal-backdrop" data-modal-close></div><section class="modal-card"><div class="modal-head"><div><h2>Nuevo horario</h2><p>Define la clase y su ubicación.</p></div><button type="button" class="modal-close" data-modal-close>×</button></div><form method="post" class="form-grid">
<label class="field"><span>Día *</span><select name="day" required><option>Lunes</option><option>Martes</option><option>Miércoles</option><option>Jueves</option><option>Viernes</option><option>Sábado</option></select></label>
<label class="field"><span>Aula</span><input name="classroom" value="Aula 202"></label>
<label class="field span-2"><span>Curso *</span><input name="course" required value="Lenguaje de Programación"></label>
<label class="field"><span>Inicio *</span><input type="time" name="start" required></label><label class="field"><span>Fin *</span><input type="time" name="end" required></label>
<div class="form-actions span-2"><button type="button" class="btn btn-secondary" data-modal-close>Cancelar</button><button class="btn btn-primary" type="submit">Guardar horario</button></div></form></section></div>
<script src="assets/js/app.js"></script></body></html>
