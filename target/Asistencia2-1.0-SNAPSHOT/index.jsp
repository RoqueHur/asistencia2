<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String role = (String) session.getAttribute("role");
    if ("PROFESOR".equals(role)) {
        response.sendRedirect("dashboard.jsp");
    } else if ("ALUMNO".equals(role)) {
        response.sendRedirect("alumno.jsp");
    } else {
        response.sendRedirect("login.jsp");
    }
%>
