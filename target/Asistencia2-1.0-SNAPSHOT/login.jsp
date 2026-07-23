<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.eduasistencia.repository.AppRepository" %>
<%@ page import="com.eduasistencia.model.Student" %>
<%
    request.setCharacterEncoding("UTF-8");
    AppRepository repo = AppRepository.getInstance();
    String error = null;

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String role = request.getParameter("role");
        String user = request.getParameter("user");
        String password = request.getParameter("password");

        if ("PROFESOR".equals(role) && repo.validateTeacher(user, password)) {
            session.setAttribute("role", "PROFESOR");
            session.setAttribute("displayName", repo.getTeacherName());
            response.sendRedirect("dashboard.jsp");
            return;
        }

        if ("ALUMNO".equals(role)) {
            Student student = repo.validateStudent(user, password);
            if (student != null) {
                session.setAttribute("role", "ALUMNO");
                session.setAttribute("studentCode", student.getCode());
                session.setAttribute("displayName", student.getFullName());
                response.sendRedirect("alumno.jsp");
                return;
            }
        }
        error = "Usuario, contraseña o tipo de acceso incorrecto.";
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Iniciar sesión | EduAsistencia</title>
    <link rel="stylesheet" href="assets/css/styles.css">
</head>
<body class="login-body">
<main class="login-shell">
    <section class="login-visual">
        <img src="assets/img/login-illustration.svg" alt="Ilustración educativa">
        <div class="login-copy">
            <span class="eyebrow">Sistema académico</span>
            <h1>Control de asistencia claro y rápido</h1>
            <p>Acceso diferenciado para docentes y estudiantes de Diseño y Programación Web.</p>
        </div>
    </section>

    <section class="login-panel">
        <div class="brand large">
            <span class="brand-mark">E</span>
            <span><strong>EduAsistencia</strong><small>Lenguaje de Programación</small></span>
        </div>
        <h2>Iniciar sesión</h2>
        <p class="muted">Selecciona tu perfil e ingresa tus credenciales.</p>

        <% if (error != null) { %>
        <div class="alert alert-error"><%= error %></div>
        <% } %>

        <form method="post" class="form-stack" autocomplete="off">
            <div class="role-switch" role="group" aria-label="Tipo de acceso">
                <label><input type="radio" name="role" value="ALUMNO" checked><span>Alumno</span></label>
                <label><input type="radio" name="role" value="PROFESOR"><span>Profesor</span></label>
            </div>
            <label class="field">
                <span>Usuario o código</span>
                <input type="text" name="user" required placeholder="Ej.: 2026001">
            </label>
            <label class="field">
                <span>Contraseña</span>
                <input type="password" name="password" required placeholder="••••••••">
            </label>
            <button class="btn btn-primary btn-block" type="submit">Ingresar</button>
        </form>

        <details class="demo-credentials">
            <summary>Ver credenciales de prueba</summary>
            <p><strong>Profesor:</strong> profesor@edumanage.pe / Profesor123</p>
            <p><strong>Roque:</strong> 2026001 / Alumno123</p>
            <p><strong>Juan:</strong> 2026002 / Alumno123</p>
        </details>
    </section>
</main>
</body>
</html>
