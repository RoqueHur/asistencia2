<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="com.eduasistencia.repository.AppRepository" %>
<%@ page import="com.eduasistencia.model.Student" %>
<%@ page import="com.eduasistencia.util.WebUtil" %>
<%
    if (!"PROFESOR".equals(session.getAttribute("role"))) { response.sendRedirect("login.jsp"); return; }
    request.setCharacterEncoding("UTF-8");
    AppRepository repo = AppRepository.getInstance();
    String message = null, error = null;

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String result = repo.addStudent(request.getParameter("code"), request.getParameter("fullName"),
                request.getParameter("email"), request.getParameter("program"), request.getParameter("course"),
                request.getParameter("password"));
        if (result == null) message = "Alumno registrado correctamente."; else error = result;
    }
    if (request.getParameter("eliminar") != null) {
        if (repo.deleteStudent(request.getParameter("eliminar"))) message = "Alumno eliminado correctamente.";
        else error = "No se encontró al alumno.";
    }
    List<Student> students = repo.getStudents();
%>
<!DOCTYPE html>
<html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Alumnos | EduAsistencia</title><link rel="stylesheet" href="assets/css/styles.css"></head><body>
<div class="app-layout">
<aside class="sidebar">
    <div class="brand"><span class="brand-mark">E</span><span><strong>EduAsistencia</strong><small>Panel docente</small></span></div>
    <nav><a href="dashboard.jsp"><span>▦</span> Dashboard</a><a href="asistencia.jsp"><span>◉</span> Cámara QR</a><a href="lista-asistencia.jsp"><span>☑</span> Lista de asistencia</a><a class="active" href="alumnos.jsp"><span>♟</span> Alumnos</a><a href="horarios.jsp"><span>▤</span> Horarios</a></nav>
    <div class="sidebar-bottom"><a href="logout.jsp" class="danger-link">↪ Cerrar sesión</a></div>
</aside>
<div class="main-area">
<header class="topbar"><button class="menu-toggle" type="button" data-menu-toggle>☰</button><div><strong>Gestión de alumnos</strong></div><div class="profile-chip"><span class="avatar">AR</span><span><strong><%= WebUtil.h((String)session.getAttribute("displayName")) %></strong><small>Profesor</small></span></div></header>
<main class="content">
    <section class="page-heading"><div><span class="eyebrow">Administración</span><h1>Alumnos</h1><p>Crea cuentas nuevas y elimina registros que ya no necesites.</p></div><button class="btn btn-primary" type="button" data-modal-open="student-modal">＋ Nuevo alumno</button></section>
    <% if (message != null) { %><div class="alert alert-success"><%= message %></div><% } %>
    <% if (error != null) { %><div class="alert alert-error"><%= WebUtil.h(error) %></div><% } %>

    <article class="panel">
        <div class="panel-head"><div><h2>Lista de estudiantes</h2><p><%= students.size() %> alumnos registrados.</p></div><input class="search-input" type="search" placeholder="Buscar alumno..." data-table-search="students-table"></div>
        <div class="table-wrap"><table id="students-table"><thead><tr><th>Código</th><th>Nombre completo</th><th>Correo</th><th>Programa</th><th>Acciones</th></tr></thead><tbody>
        <% for (Student s : students) { %>
        <tr>
            <td><span class="code-pill"><%= WebUtil.h(s.getCode()) %></span></td>
            <td><strong><%= WebUtil.h(s.getFullName()) %></strong><small class="table-sub"><%= WebUtil.h(s.getCourse()) %></small></td>
            <td><%= WebUtil.h(s.getEmail()) %></td>
            <td><%= WebUtil.h(s.getProgram()) %></td>
            <td><a class="btn-icon danger" href="alumnos.jsp?eliminar=<%= WebUtil.h(s.getCode()) %>" data-confirm="¿Eliminar al alumno y todas sus asistencias?">Eliminar</a></td>
        </tr>
        <% } %>
        </tbody></table></div>
    </article>
</main>
</div></div>

<div class="modal" id="student-modal" aria-hidden="true"><div class="modal-backdrop" data-modal-close></div><section class="modal-card"><div class="modal-head"><div><h2>Nuevo alumno</h2><p>Completa los datos de acceso.</p></div><button type="button" class="modal-close" data-modal-close>×</button></div>
<form method="post" class="form-grid">
    <label class="field"><span>Código *</span><input name="code" required placeholder="2026003"></label>
    <label class="field"><span>Nombre completo *</span><input name="fullName" required placeholder="Apellidos y nombres"></label>
    <label class="field"><span>Correo</span><input type="email" name="email" placeholder="alumno@estudiante.edu.pe"></label>
    <label class="field"><span>Contraseña</span><input name="password" value="Alumno123"></label>
    <label class="field span-2"><span>Programa</span><input name="program" value="Diseño y Programación Web"></label>
    <label class="field span-2"><span>Curso</span><input name="course" value="Lenguaje de Programación"></label>
    <div class="form-actions span-2"><button type="button" class="btn btn-secondary" data-modal-close>Cancelar</button><button class="btn btn-primary" type="submit">Guardar alumno</button></div>
</form></section></div>
<script src="assets/js/app.js"></script></body></html>
