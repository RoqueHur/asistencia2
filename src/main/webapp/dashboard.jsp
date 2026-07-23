<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.List" %>
<%@ page import="com.eduasistencia.repository.AppRepository" %>
<%@ page import="com.eduasistencia.model.Attendance" %>
<%@ page import="com.eduasistencia.model.Student" %>
<%@ page import="com.eduasistencia.util.WebUtil" %>
<%
    if (!"PROFESOR".equals(session.getAttribute("role"))) { response.sendRedirect("login.jsp"); return; }
    AppRepository repo = AppRepository.getInstance();
    List<Attendance> records = repo.getAttendance();
    long present = repo.countStatusToday("PRESENTE");
    long late = repo.countStatusToday("TARDANZA");
    long absent = repo.countStatusToday("FALTA");
    long registered = repo.countRegisteredToday();
    int total = repo.getStudents().size();
    long pending = Math.max(0, total - registered);
    String dateText = LocalDate.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard | EduAsistencia</title><link rel="stylesheet" href="assets/css/styles.css">
</head>
<body>
<div class="app-layout">
    <aside class="sidebar">
        <div class="brand"><span class="brand-mark">E</span><span><strong>EduAsistencia</strong><small>Panel docente</small></span></div>
        <nav>
            <a class="active" href="dashboard.jsp"><span>▦</span> Dashboard</a>
            <a href="asistencia.jsp"><span>◉</span> Cámara QR</a>
            <a href="lista-asistencia.jsp"><span>☑</span> Lista de asistencia</a>
            <a href="alumnos.jsp"><span>♟</span> Alumnos</a>
            <a href="horarios.jsp"><span>▤</span> Horarios</a>
        </nav>
        <div class="sidebar-bottom"><a href="logout.jsp" class="danger-link">↪ Cerrar sesión</a></div>
    </aside>

    <div class="main-area">
        <header class="topbar">
            <button class="menu-toggle" type="button" data-menu-toggle>☰</button>
            <div><strong>Panel de control</strong><span class="top-date"><%= dateText %></span></div>
            <div class="profile-chip"><span class="avatar">AR</span><span><strong><%= WebUtil.h((String)session.getAttribute("displayName")) %></strong><small>Profesor</small></span></div>
        </header>

        <main class="content">
            <section class="welcome-row">
                <div><span class="eyebrow">Resumen del día</span><h1>Bienvenido, profesor</h1><p>Administra alumnos, horarios y asistencia desde un solo lugar.</p></div>
                <a class="btn btn-primary" href="asistencia.jsp">Abrir cámara</a>
            </section>

            <section class="stats-grid">
                <article class="stat-card"><span class="stat-icon green">✓</span><div><small>Presentes hoy</small><strong><%= present %></strong></div></article>
                <article class="stat-card"><span class="stat-icon yellow">◷</span><div><small>Tardanzas</small><strong><%= late %></strong></div></article>
                <article class="stat-card"><span class="stat-icon red">×</span><div><small>Faltas</small><strong><%= absent %></strong></div></article>
                <article class="stat-card"><span class="stat-icon blue">…</span><div><small>Sin registrar</small><strong><%= pending %></strong></div></article>
            </section>

            <section class="dashboard-grid">
                <article class="panel">
                    <div class="panel-head"><div><h2>Asistencia reciente</h2><p>Últimos registros almacenados.</p></div><a href="asistencia.jsp">Ver todos</a></div>
                    <div class="table-wrap">
                        <table>
                            <thead><tr><th>Alumno</th><th>Fecha</th><th>Hora</th><th>Estado</th></tr></thead>
                            <tbody>
                            <% if (records.isEmpty()) { %><tr><td colspan="4" class="empty">Todavía no hay registros.</td></tr><% } %>
                            <% for (int i = 0; i < Math.min(6, records.size()); i++) { Attendance a = records.get(i); Student s = repo.findStudentByCode(a.getStudentCode()); %>
                            <tr>
                                <td><strong><%= WebUtil.h(s == null ? a.getStudentCode() : s.getFullName()) %></strong><small class="table-sub"><%= WebUtil.h(a.getStudentCode()) %></small></td>
                                <td><%= a.getDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) %></td>
                                <td><%= a.getTime().format(DateTimeFormatter.ofPattern("HH:mm")) %></td>
                                <td><span class="badge <%= a.getStatus().toLowerCase() %>"><%= a.getStatus() %></span></td>
                            </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                </article>

                <article class="panel quick-panel">
                    <div class="panel-head"><div><h2>Acciones rápidas</h2><p>Funciones principales.</p></div></div>
                    <a class="quick-action" href="asistencia.jsp"><span class="quick-icon">▣</span><div><strong>Escanear código QR</strong><small>Enciende la cámara y registra asistencia.</small></div><b>›</b></a>
                    <a class="quick-action" href="lista-asistencia.jsp"><span class="quick-icon">☑</span><div><strong>Pasar lista</strong><small>Marca estado, día, fecha y hora por alumno.</small></div><b>›</b></a>
                    <a class="quick-action" href="alumnos.jsp"><span class="quick-icon">＋</span><div><strong>Agregar alumno</strong><small>Crea una cuenta estudiantil.</small></div><b>›</b></a>
                    <a class="quick-action" href="horarios.jsp"><span class="quick-icon">▤</span><div><strong>Gestionar horarios</strong><small>Agrega o elimina clases.</small></div><b>›</b></a>
                </article>
            </section>
        </main>
    </div>
</div>
<script src="assets/js/app.js"></script>
</body>
</html>
