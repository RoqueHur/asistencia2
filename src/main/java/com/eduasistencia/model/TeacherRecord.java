package com.eduasistencia.model;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalTime;

public class TeacherRecord implements Serializable {
    private static final long serialVersionUID = 1L;

    private int id;
    private LocalDate date;
    private LocalTime time;
    private String type;
    private String course;

    public TeacherRecord(int id, LocalDate date, LocalTime time, String type) {
        this(id, date, time, type, "Sin curso");
    }

    public TeacherRecord(int id, LocalDate date, LocalTime time, String type, String course) {
        this.id = id;
        this.date = date;
        this.time = time;
        this.type = type;
        this.course = course;
    }

    public int getId() { return id; }
    public LocalDate getDate() { return date; }
    public LocalTime getTime() { return time; }
    public String getType() { return type; }
    public String getCourse() {
        return course == null || course.trim().isEmpty() ? "Sin curso" : course;
    }
    public void setCourse(String course) { this.course = course; }
}
