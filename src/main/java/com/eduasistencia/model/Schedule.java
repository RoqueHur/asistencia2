package com.eduasistencia.model;

import java.io.Serializable;

public class Schedule implements Serializable {
    private static final long serialVersionUID = 1L;

    private int id;
    private String day;
    private String course;
    private String startTime;
    private String endTime;
    private String classroom;

    public Schedule(int id, String day, String course, String startTime, String endTime, String classroom) {
        this.id = id;
        this.day = day;
        this.course = course;
        this.startTime = startTime;
        this.endTime = endTime;
        this.classroom = classroom;
    }

    public int getId() { return id; }
    public String getDay() { return day; }
    public String getCourse() { return course; }
    public String getStartTime() { return startTime; }
    public String getEndTime() { return endTime; }
    public String getClassroom() { return classroom; }
}
