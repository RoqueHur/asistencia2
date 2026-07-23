<%@ page contentType="text/csv; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.eduasistencia.repository.AppRepository" %>
<%@ page import="com.eduasistencia.model.Schedule" %>
<%
    if (!"ALUMNO".equals(session.getAttribute("role"))) { response.sendRedirect("login.jsp"); return; }
    response.setHeader("Content-Disposition", "attachment; filename=mi-horario.csv");
    out.print('\ufeff');
    out.println("Día,Curso,Hora de inicio,Hora de fin,Aula");
    for (Schedule s : AppRepository.getInstance().getSchedules()) {
        out.println("\"" + s.getDay().replace("\"", "\"\"") + "\",\"" + s.getCourse().replace("\"", "\"\"") + "\",\"" + s.getStartTime() + "\",\"" + s.getEndTime() + "\",\"" + s.getClassroom().replace("\"", "\"\"") + "\"");
    }
%>
