package com.eduasistencia.repository;

import com.eduasistencia.model.Attendance;
import com.eduasistencia.model.Schedule;
import com.eduasistencia.model.Student;
import com.eduasistencia.model.TeacherRecord;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

public final class AppRepository {
    private static final AppRepository INSTANCE = new AppRepository();
    private static final String TEACHER_EMAIL = "profesor@edumanage.pe";
    private static final String TEACHER_PASSWORD = "Profesor123";
    private static final String TEACHER_NAME = "Prof. Alejandro Ruiz";

    private final Path dataFile;
    private List<Student> students;
    private List<Attendance> attendance;
    private List<Schedule> schedules;
    private List<TeacherRecord> teacherRecords;
    private AtomicInteger attendanceId;
    private AtomicInteger scheduleId;
    private AtomicInteger teacherRecordId;

    private AppRepository() {
        Path folder = Paths.get(System.getProperty("user.home", System.getProperty("java.io.tmpdir")), ".eduasistencia");
        dataFile = folder.resolve("datos.ser");
        try { Files.createDirectories(folder); } catch (IOException ignored) { }
        if (!load()) seed();
    }

    public static AppRepository getInstance() { return INSTANCE; }
    public String getTeacherEmail() { return TEACHER_EMAIL; }
    public String getTeacherPassword() { return TEACHER_PASSWORD; }
    public String getTeacherName() { return TEACHER_NAME; }

    public synchronized boolean validateTeacher(String user, String password) {
        return TEACHER_EMAIL.equalsIgnoreCase(safe(user)) && TEACHER_PASSWORD.equals(password);
    }

    public synchronized Student validateStudent(String code, String password) {
        Student student = findStudentByCode(code);
        return student != null && student.getPassword().equals(password) ? student : null;
    }

    public synchronized List<Student> getStudents() {
        return students.stream()
                .sorted(Comparator.comparing(Student::getFullName, String.CASE_INSENSITIVE_ORDER))
                .collect(Collectors.toList());
    }

    public synchronized Student findStudentByCode(String code) {
        if (code == null) return null;
        return students.stream().filter(s -> s.getCode().equalsIgnoreCase(code.trim())).findFirst().orElse(null);
    }

    public synchronized String addStudent(String code, String fullName, String email, String program, String course, String password) {
        code = safe(code);
        fullName = safe(fullName);
        if (code.isEmpty() || fullName.isEmpty()) return "El código y el nombre son obligatorios.";
        if (findStudentByCode(code) != null) return "Ya existe un alumno con ese código.";
        students.add(new Student(code, fullName, safe(email), defaultValue(program, "Diseño y Programación Web"),
                defaultValue(course, "Lenguaje de Programación"), defaultValue(password, "Alumno123")));
        save();
        return null;
    }

    public synchronized boolean deleteStudent(String code) {
        boolean removed = students.removeIf(s -> s.getCode().equalsIgnoreCase(safe(code)));
        if (removed) {
            attendance.removeIf(a -> a.getStudentCode().equalsIgnoreCase(safe(code)));
            save();
        }
        return removed;
    }

    public synchronized List<Attendance> getAttendance() {
        return attendance.stream()
                .sorted(Comparator.comparing(Attendance::getDate).thenComparing(Attendance::getTime).reversed())
                .collect(Collectors.toList());
    }

    public synchronized List<Attendance> getAttendanceByStudent(String code) {
        return attendance.stream()
                .filter(a -> a.getStudentCode().equalsIgnoreCase(safe(code)))
                .sorted(Comparator.comparing(Attendance::getDate).thenComparing(Attendance::getTime).reversed())
                .collect(Collectors.toList());
    }

    public synchronized int registerAttendance(String code, LocalDate date, LocalTime time, String status) {
        Student student = findStudentByCode(code);
        if (student == null) return -2;
        Optional<Attendance> existing = attendance.stream()
                .filter(a -> a.getStudentCode().equalsIgnoreCase(code.trim()) && a.getDate().equals(date))
                .findFirst();
        if (existing.isPresent()) return -1;
        int id = attendanceId.getAndIncrement();
        attendance.add(new Attendance(id, student.getCode(), date, time.withSecond(0).withNano(0), status));
        save();
        return id;
    }

    public synchronized Attendance findAttendanceByStudentAndDate(String code, LocalDate date) {
        if (date == null) return null;
        String normalizedCode = safe(code);
        return attendance.stream()
                .filter(a -> a.getStudentCode().equalsIgnoreCase(normalizedCode) && a.getDate().equals(date))
                .findFirst()
                .orElse(null);
    }

    /**
     * Crea o actualiza la asistencia del alumno para una fecha.
     * @return 1 si creó, 2 si actualizó y -2 si el alumno no existe.
     */
    public synchronized int upsertAttendance(String code, LocalDate date, LocalTime time, String status) {
        Student student = findStudentByCode(code);
        if (student == null) return -2;
        LocalDate safeDate = date == null ? LocalDate.now() : date;
        LocalTime safeTime = time == null ? LocalTime.now() : time;
        String safeStatus = defaultValue(status, "PRESENTE").toUpperCase(Locale.ROOT);
        Attendance existing = findAttendanceByStudentAndDate(student.getCode(), safeDate);
        if (existing != null) {
            existing.setTime(safeTime.withSecond(0).withNano(0));
            existing.setStatus(safeStatus);
            save();
            return 2;
        }
        int id = attendanceId.getAndIncrement();
        attendance.add(new Attendance(id, student.getCode(), safeDate, safeTime.withSecond(0).withNano(0), safeStatus));
        save();
        return 1;
    }

    public synchronized boolean deleteAttendance(String code, LocalDate date) {
        String normalizedCode = safe(code);
        boolean removed = attendance.removeIf(a -> a.getStudentCode().equalsIgnoreCase(normalizedCode) && a.getDate().equals(date));
        if (removed) save();
        return removed;
    }

    public synchronized boolean deleteAttendance(int id) {
        boolean removed = attendance.removeIf(a -> a.getId() == id);
        if (removed) save();
        return removed;
    }

    public synchronized List<Schedule> getSchedules() {
        final List<String> days = Arrays.asList("LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO");
        return schedules.stream().sorted(Comparator
                .comparingInt((Schedule s) -> {
                    int index = days.indexOf(s.getDay().toUpperCase());
                    return index < 0 ? 99 : index;
                })
                .thenComparing(Schedule::getStartTime)).collect(Collectors.toList());
    }

    public synchronized String addSchedule(String day, String course, String start, String end, String classroom) {
        if (safe(day).isEmpty() || safe(course).isEmpty() || safe(start).isEmpty() || safe(end).isEmpty()) {
            return "Completa el día, curso, hora de inicio y hora de fin.";
        }
        int id = scheduleId.getAndIncrement();
        schedules.add(new Schedule(id, day.trim().toUpperCase(), course.trim(), start.trim(), end.trim(), defaultValue(classroom, "Aula 202")));
        save();
        return null;
    }

    public synchronized boolean deleteSchedule(int id) {
        boolean removed = schedules.removeIf(s -> s.getId() == id);
        if (removed) save();
        return removed;
    }

    public synchronized TeacherRecord registerTeacher(String type) {
        TeacherRecord record = new TeacherRecord(teacherRecordId.getAndIncrement(), LocalDate.now(), LocalTime.now().withSecond(0).withNano(0), type);
        teacherRecords.add(record);
        save();
        return record;
    }

    public synchronized List<TeacherRecord> getTeacherRecords() {
        return teacherRecords.stream()
                .sorted(Comparator.comparing(TeacherRecord::getDate).thenComparing(TeacherRecord::getTime).reversed())
                .collect(Collectors.toList());
    }

    public synchronized long countStatusToday(String status) {
        LocalDate today = LocalDate.now();
        return attendance.stream().filter(a -> a.getDate().equals(today) && a.getStatus().equalsIgnoreCase(status)).count();
    }

    public synchronized long countRegisteredToday() {
        LocalDate today = LocalDate.now();
        return attendance.stream().filter(a -> a.getDate().equals(today)).count();
    }

    private void seed() {
        students = new ArrayList<>();
        attendance = new ArrayList<>();
        schedules = new ArrayList<>();
        teacherRecords = new ArrayList<>();
        attendanceId = new AtomicInteger(1);
        scheduleId = new AtomicInteger(1);
        teacherRecordId = new AtomicInteger(1);

        students.add(new Student("2026001", "Roque Hurtado Dilber", "roque.hurtado@estudiante.edu.pe",
                "Diseño y Programación Web", "Lenguaje de Programación", "Alumno123"));
        students.add(new Student("2026002", "Lopez Parado Juan", "juan.lopez@estudiante.edu.pe",
                "Diseño y Programación Web", "Lenguaje de Programación", "Alumno123"));

        schedules.add(new Schedule(scheduleId.getAndIncrement(), "LUNES", "Lenguaje de Programación", "08:00", "10:00", "Laboratorio 3"));
        schedules.add(new Schedule(scheduleId.getAndIncrement(), "MIÉRCOLES", "Diseño de Interfaces Web", "10:15", "12:15", "Aula 202"));
        schedules.add(new Schedule(scheduleId.getAndIncrement(), "VIERNES", "Base de Datos", "08:00", "10:00", "Laboratorio 2"));

        LocalDate today = LocalDate.now();
        attendance.add(new Attendance(attendanceId.getAndIncrement(), "2026001", today, LocalTime.of(7, 58), "PRESENTE"));
        attendance.add(new Attendance(attendanceId.getAndIncrement(), "2026002", today, LocalTime.of(8, 12), "TARDANZA"));
        attendance.add(new Attendance(attendanceId.getAndIncrement(), "2026001", today.minusDays(2), LocalTime.of(8, 1), "PRESENTE"));
        attendance.add(new Attendance(attendanceId.getAndIncrement(), "2026002", today.minusDays(2), LocalTime.of(8, 0), "PRESENTE"));
        save();
    }

    private boolean load() {
        if (!Files.exists(dataFile)) return false;
        try (ObjectInputStream in = new ObjectInputStream(Files.newInputStream(dataFile))) {
            DataState state = (DataState) in.readObject();
            students = state.students;
            attendance = state.attendance;
            schedules = state.schedules;
            teacherRecords = state.teacherRecords == null ? new ArrayList<>() : state.teacherRecords;
            attendanceId = new AtomicInteger(state.nextAttendanceId);
            scheduleId = new AtomicInteger(state.nextScheduleId);
            teacherRecordId = new AtomicInteger(state.nextTeacherRecordId <= 0 ? 1 : state.nextTeacherRecordId);
            return students != null && attendance != null && schedules != null;
        } catch (Exception ignored) {
            return false;
        }
    }

    private synchronized void save() {
        try (ObjectOutputStream out = new ObjectOutputStream(Files.newOutputStream(dataFile))) {
            out.writeObject(new DataState(students, attendance, schedules, teacherRecords,
                    attendanceId.get(), scheduleId.get(), teacherRecordId.get()));
        } catch (IOException ignored) { }
    }

    private static String safe(String value) { return value == null ? "" : value.trim(); }
    private static String defaultValue(String value, String fallback) { return safe(value).isEmpty() ? fallback : value.trim(); }

    private static class DataState implements Serializable {
        private static final long serialVersionUID = 1L;
        List<Student> students;
        List<Attendance> attendance;
        List<Schedule> schedules;
        List<TeacherRecord> teacherRecords;
        int nextAttendanceId;
        int nextScheduleId;
        int nextTeacherRecordId;

        DataState(List<Student> students, List<Attendance> attendance, List<Schedule> schedules,
                  List<TeacherRecord> teacherRecords, int nextAttendanceId, int nextScheduleId, int nextTeacherRecordId) {
            this.students = students;
            this.attendance = attendance;
            this.schedules = schedules;
            this.teacherRecords = teacherRecords;
            this.nextAttendanceId = nextAttendanceId;
            this.nextScheduleId = nextScheduleId;
            this.nextTeacherRecordId = nextTeacherRecordId;
        }
    }
}
