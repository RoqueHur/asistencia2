package com.eduasistencia.model;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalTime;

public class Attendance implements Serializable {
    private static final long serialVersionUID = 1L;

    private int id;
    private String studentCode;
    private LocalDate date;
    private LocalTime time;
    private String status;

    public Attendance(int id, String studentCode, LocalDate date, LocalTime time, String status) {
        this.id = id;
        this.studentCode = studentCode;
        this.date = date;
        this.time = time;
        this.status = status;
    }

    public int getId() { return id; }
    public String getStudentCode() { return studentCode; }
    public LocalDate getDate() { return date; }
    public LocalTime getTime() { return time; }
    public String getStatus() { return status; }
    public void setTime(LocalTime time) { this.time = time; }
    public void setStatus(String status) { this.status = status; }
}
