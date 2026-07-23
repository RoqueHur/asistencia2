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

    public TeacherRecord(int id, LocalDate date, LocalTime time, String type) {
        this.id = id;
        this.date = date;
        this.time = time;
        this.type = type;
    }

    public int getId() { return id; }
    public LocalDate getDate() { return date; }
    public LocalTime getTime() { return time; }
    public String getType() { return type; }
}
