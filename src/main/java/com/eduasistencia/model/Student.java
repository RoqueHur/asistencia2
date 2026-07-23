package com.eduasistencia.model;

import java.io.Serializable;

public class Student implements Serializable {
    private static final long serialVersionUID = 1L;

    private String code;
    private String fullName;
    private String email;
    private String program;
    private String course;
    private String password;

    public Student(String code, String fullName, String email, String program, String course, String password) {
        this.code = code;
        this.fullName = fullName;
        this.email = email;
        this.program = program;
        this.course = course;
        this.password = password;
    }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getProgram() { return program; }
    public void setProgram(String program) { this.program = program; }
    public String getCourse() { return course; }
    public void setCourse(String course) { this.course = course; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
}
