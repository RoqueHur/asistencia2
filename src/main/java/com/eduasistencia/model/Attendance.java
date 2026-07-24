package com.eduasistencia.model;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalTime;

public class Attendance implements Serializable {
    private static final long serialVersionUID = 1L;
    private static final String DEFAULT_PERIOD = "UNIDAD_4";

    private int id;
    private String studentCode;
    private LocalDate date;
    private LocalTime time;
    private String status;
    private String course;
    private String period;

    public Attendance(int id, String studentCode, LocalDate date, LocalTime time, String status) {
        this(id, studentCode, date, time, status, "Sin curso", DEFAULT_PERIOD);
    }

    public Attendance(int id, String studentCode, LocalDate date, LocalTime time, String status, String course) {
        this(id, studentCode, date, time, status, course, DEFAULT_PERIOD);
    }

    public Attendance(int id, String studentCode, LocalDate date, LocalTime time,
                      String status, String course, String period) {
        this.id = id;
        this.studentCode = studentCode;
        this.date = date;
        this.time = time;
        this.status = status;
        this.course = course;
        this.period = period;
    }

    public int getId() { return id; }
    public String getStudentCode() { return studentCode; }
    public LocalDate getDate() { return date; }
    public LocalTime getTime() { return time; }
    public String getStatus() { return status; }
    public String getCourse() {
        return course == null || course.trim().isEmpty() ? "Sin curso" : course;
    }
    public String getPeriod() {
        if (period == null || period.trim().isEmpty()) return DEFAULT_PERIOD;
        return period;
    }
    public void setTime(LocalTime time) { this.time = time; }
    public void setStatus(String status) { this.status = status; }
    public void setCourse(String course) { this.course = course; }
    public void setPeriod(String period) { this.period = period; }
}
