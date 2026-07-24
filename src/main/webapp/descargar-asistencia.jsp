<%@ page contentType="text/csv; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="com.eduasistencia.repository.AppRepository" %>
<%@ page import="com.eduasistencia.model.Attendance" %>
<%@ page import="com.eduasistencia.util.WebUtil" %>
<%
    if (!"ALUMNO".equals(session.getAttribute("role"))) { response.sendRedirect("login.jsp"); return; }
    String code = (String) session.getAttribute("studentCode");
    response.setHeader("Content-Disposition", "attachment; filename=mi-asistencia.csv");
    out.print('\ufeff');
    out.println("Curso,Periodo,Fecha,Hora,Estado");
    for (Attendance a : AppRepository.getInstance().getAttendanceByStudent(code)) {
        out.println("\"" + a.getCourse().replace("\"", "\"\"") + "\",\"" + WebUtil.periodLabel(a.getPeriod()) + "\"," + a.getDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) + "," + a.getTime().format(DateTimeFormatter.ofPattern("HH:mm")) + "," + a.getStatus());
    }
%>
