package com.eduasistencia.repository;

import com.eduasistencia.model.Attendance;
import com.eduasistencia.model.Schedule;
import com.eduasistencia.model.Student;
import com.eduasistencia.model.TeacherRecord;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

public final class AppRepository {
    private static final String TEACHER_EMAIL = "profesor@edumanage.pe";
    private static final String TEACHER_PASSWORD = "Profesor123";
    private static final String TEACHER_NAME = "Prof. Alejandro Ruiz";
    private static final String DEFAULT_COURSE = "Lenguaje de Programación";
    private static final String DEFAULT_PERIOD = "UNIDAD_4";
    private static final AppRepository INSTANCE = new AppRepository();

    private final Path dataFile;
    private List<Student> students;
    private List<Attendance> attendance;
    private List<Schedule> schedules;
    private List<TeacherRecord> teacherRecords;
    private List<String> courses;
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
        String selectedCourse = defaultValue(course, DEFAULT_COURSE);
        students.add(new Student(code, fullName, safe(email), defaultValue(program, "Diseño y Programación Web"),
                selectedCourse, defaultValue(password, "Alumno123")));
        addCourseInternal(selectedCourse);
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

    public synchronized List<String> getCourseOptions() {
        if (courses == null) courses = new ArrayList<>();
        if (courses.isEmpty()) courses.add(DEFAULT_COURSE);
        return courses.stream()
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(value -> !value.isEmpty())
                .distinct()
                .collect(Collectors.toList());
    }

    public synchronized String addCourse(String name) {
        String cleanName = safe(name);
        if (cleanName.isEmpty()) return "Escribe el nombre del curso.";
        if (cleanName.length() > 80) return "El nombre del curso es demasiado largo.";
        for (String current : getCourseOptions()) {
            if (current.equalsIgnoreCase(cleanName)) return "Ese curso ya existe.";
        }
        courses.add(cleanName);
        save();
        return null;
    }

    public synchronized String deleteCourse(String name) {
        String cleanName = safe(name);
        if (cleanName.isEmpty()) return "Selecciona el curso que deseas quitar.";

        String exactName = null;
        for (String current : getCourseOptions()) {
            if (current.equalsIgnoreCase(cleanName)) {
                exactName = current;
                break;
            }
        }
        if (exactName == null) return "El curso seleccionado no existe.";
        if (getCourseOptions().size() <= 1) return "Debe quedar al menos un curso disponible.";

        final String courseToDelete = exactName;
        boolean usedByStudent = students.stream().anyMatch(student -> student.getCourse().equalsIgnoreCase(courseToDelete));
        boolean usedBySchedule = schedules.stream().anyMatch(schedule -> schedule.getCourse().equalsIgnoreCase(courseToDelete));
        if (usedByStudent || usedBySchedule) {
            return "No se puede quitar porque está asignado a alumnos o a un horario. Primero cambia esas asignaciones.";
        }

        courses.removeIf(course -> course.equalsIgnoreCase(courseToDelete));
        save();
        return null;
    }

    public synchronized String getDefaultCourse() {
        List<Schedule> orderedSchedules = getSchedules();
        if (orderedSchedules.isEmpty()) return getCourseOptions().get(0);

        String today = spanishDay(LocalDate.now().getDayOfWeek());
        LocalTime now = LocalTime.now();
        for (Schedule schedule : orderedSchedules) {
            if (today.equalsIgnoreCase(schedule.getDay()) && timeInside(now, schedule.getStartTime(), schedule.getEndTime())) {
                return schedule.getCourse();
            }
        }
        for (Schedule schedule : orderedSchedules) {
            if (today.equalsIgnoreCase(schedule.getDay())) return schedule.getCourse();
        }
        return orderedSchedules.get(0).getCourse();
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

    public synchronized List<Attendance> getAttendanceForCourseOnDate(String course, LocalDate date) {
        return getAttendanceForCourseOnDate(course, date, DEFAULT_PERIOD);
    }

    public synchronized List<Attendance> getAttendanceForCourseOnDate(String course, LocalDate date, String period) {
        String normalizedCourse = normalizeCourse(course, null);
        String normalizedPeriod = normalizePeriod(period);
        LocalDate safeDate = date == null ? LocalDate.now() : date;
        return attendance.stream()
                .filter(a -> a.getDate().equals(safeDate)
                        && a.getCourse().equalsIgnoreCase(normalizedCourse)
                        && normalizePeriod(a.getPeriod()).equals(normalizedPeriod))
                .sorted(Comparator.comparing(Attendance::getTime).reversed())
                .collect(Collectors.toList());
    }

    public synchronized int registerAttendance(String code, LocalDate date, LocalTime time, String status) {
        return registerAttendance(code, date, time, status, null, DEFAULT_PERIOD);
    }

    public synchronized int registerAttendance(String code, LocalDate date, LocalTime time, String status, String course) {
        return registerAttendance(code, date, time, status, course, DEFAULT_PERIOD);
    }

    public synchronized int registerAttendance(String code, LocalDate date, LocalTime time,
                                               String status, String course, String period) {
        Student student = findStudentByCode(code);
        if (student == null) return -2;
        LocalDate safeDate = date == null ? LocalDate.now() : date;
        LocalTime safeTime = time == null ? LocalTime.now() : time;
        String safeStatus = defaultValue(status, "PRESENTE").toUpperCase(Locale.ROOT);
        String safeCourse = normalizeCourse(course, student);
        String safePeriod = normalizePeriod(period);
        Optional<Attendance> existing = attendance.stream()
                .filter(a -> a.getStudentCode().equalsIgnoreCase(student.getCode())
                        && a.getDate().equals(safeDate)
                        && a.getCourse().equalsIgnoreCase(safeCourse)
                        && normalizePeriod(a.getPeriod()).equals(safePeriod))
                .findFirst();
        if (existing.isPresent()) return -1;
        int id = attendanceId.getAndIncrement();
        attendance.add(new Attendance(id, student.getCode(), safeDate,
                safeTime.withSecond(0).withNano(0), safeStatus, safeCourse, safePeriod));
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

    public synchronized Attendance findAttendanceByStudentDateCourse(String code, LocalDate date, String course) {
        return findAttendanceByStudentDateCoursePeriod(code, date, course, DEFAULT_PERIOD);
    }

    public synchronized Attendance findAttendanceByStudentDateCoursePeriod(String code, LocalDate date,
                                                                            String course, String period) {
        if (date == null) return null;
        String normalizedCode = safe(code);
        String normalizedCourse = normalizeCourse(course, findStudentByCode(code));
        String normalizedPeriod = normalizePeriod(period);
        return attendance.stream()
                .filter(a -> a.getStudentCode().equalsIgnoreCase(normalizedCode)
                        && a.getDate().equals(date)
                        && a.getCourse().equalsIgnoreCase(normalizedCourse)
                        && normalizePeriod(a.getPeriod()).equals(normalizedPeriod))
                .findFirst()
                .orElse(null);
    }

    public synchronized int upsertAttendance(String code, LocalDate date, LocalTime time, String status) {
        return upsertAttendance(code, date, time, status, null, DEFAULT_PERIOD);
    }

    public synchronized int upsertAttendance(String code, LocalDate date, LocalTime time, String status, String course) {
        return upsertAttendance(code, date, time, status, course, DEFAULT_PERIOD);
    }

    /**
     * Crea o actualiza la asistencia del alumno para una fecha, curso y periodo académico.
     * @return 1 si creó, 2 si actualizó y -2 si el alumno no existe.
     */
    public synchronized int upsertAttendance(String code, LocalDate date, LocalTime time,
                                             String status, String course, String period) {
        Student student = findStudentByCode(code);
        if (student == null) return -2;
        LocalDate safeDate = date == null ? LocalDate.now() : date;
        LocalTime safeTime = time == null ? LocalTime.now() : time;
        String safeStatus = defaultValue(status, "PRESENTE").toUpperCase(Locale.ROOT);
        String safeCourse = normalizeCourse(course, student);
        String safePeriod = normalizePeriod(period);
        Attendance existing = findAttendanceByStudentDateCoursePeriod(student.getCode(), safeDate, safeCourse, safePeriod);
        if (existing != null) {
            existing.setTime(safeTime.withSecond(0).withNano(0));
            existing.setStatus(safeStatus);
            existing.setCourse(safeCourse);
            existing.setPeriod(safePeriod);
            save();
            return 2;
        }
        int id = attendanceId.getAndIncrement();
        attendance.add(new Attendance(id, student.getCode(), safeDate,
                safeTime.withSecond(0).withNano(0), safeStatus, safeCourse, safePeriod));
        save();
        return 1;
    }

    public synchronized boolean deleteAttendance(String code, LocalDate date) {
        String normalizedCode = safe(code);
        boolean removed = attendance.removeIf(a -> a.getStudentCode().equalsIgnoreCase(normalizedCode) && a.getDate().equals(date));
        if (removed) save();
        return removed;
    }

    public synchronized boolean deleteAttendance(String code, LocalDate date, String course) {
        return deleteAttendance(code, date, course, DEFAULT_PERIOD);
    }

    public synchronized boolean deleteAttendance(String code, LocalDate date, String course, String period) {
        String normalizedCode = safe(code);
        String normalizedCourse = normalizeCourse(course, findStudentByCode(code));
        String normalizedPeriod = normalizePeriod(period);
        boolean removed = attendance.removeIf(a -> a.getStudentCode().equalsIgnoreCase(normalizedCode)
                && a.getDate().equals(date)
                && a.getCourse().equalsIgnoreCase(normalizedCourse)
                && normalizePeriod(a.getPeriod()).equals(normalizedPeriod));
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
                    int index = days.indexOf(s.getDay().toUpperCase(Locale.ROOT));
                    return index < 0 ? 99 : index;
                })
                .thenComparing(Schedule::getStartTime)).collect(Collectors.toList());
    }

    public synchronized String addSchedule(String day, String course, String start, String end, String classroom) {
        if (safe(day).isEmpty() || safe(course).isEmpty() || safe(start).isEmpty() || safe(end).isEmpty()) {
            return "Completa el día, curso, hora de inicio y hora de fin.";
        }
        int id = scheduleId.getAndIncrement();
        String selectedCourse = course.trim();
        schedules.add(new Schedule(id, day.trim().toUpperCase(Locale.ROOT), selectedCourse, start.trim(), end.trim(), defaultValue(classroom, "Aula 202")));
        addCourseInternal(selectedCourse);
        save();
        return null;
    }

    public synchronized boolean deleteSchedule(int id) {
        boolean removed = schedules.removeIf(s -> s.getId() == id);
        if (removed) save();
        return removed;
    }

    public synchronized TeacherRecord registerTeacher(String type) {
        return registerTeacher(type, getDefaultCourse());
    }

    public synchronized TeacherRecord registerTeacher(String type, String course) {
        TeacherRecord record = new TeacherRecord(teacherRecordId.getAndIncrement(), LocalDate.now(),
                LocalTime.now().withSecond(0).withNano(0),
                "SALIDA".equalsIgnoreCase(type) ? "SALIDA" : "ENTRADA",
                normalizeCourse(course, null));
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

    public synchronized long countStatusToday(String status, String course) {
        return countStatusToday(status, course, DEFAULT_PERIOD);
    }

    public synchronized long countStatusToday(String status, String course, String period) {
        LocalDate today = LocalDate.now();
        String normalizedCourse = normalizeCourse(course, null);
        String normalizedPeriod = normalizePeriod(period);
        return attendance.stream().filter(a -> a.getDate().equals(today)
                && a.getStatus().equalsIgnoreCase(status)
                && a.getCourse().equalsIgnoreCase(normalizedCourse)
                && normalizePeriod(a.getPeriod()).equals(normalizedPeriod)).count();
    }

    public synchronized long countRegisteredToday() {
        LocalDate today = LocalDate.now();
        return attendance.stream().filter(a -> a.getDate().equals(today)).count();
    }

    public synchronized long countRegisteredToday(String course) {
        LocalDate today = LocalDate.now();
        String normalizedCourse = normalizeCourse(course, null);
        return attendance.stream().filter(a -> a.getDate().equals(today)
                && a.getCourse().equalsIgnoreCase(normalizedCourse)).count();
    }

    private void seed() {
        students = new ArrayList<>();
        attendance = new ArrayList<>();
        schedules = new ArrayList<>();
        teacherRecords = new ArrayList<>();
        courses = new ArrayList<>();
        attendanceId = new AtomicInteger(1);
        scheduleId = new AtomicInteger(1);
        teacherRecordId = new AtomicInteger(1);

        students.add(new Student("2026001", "Roque Hurtado Dilber", "roque.hurtado@estudiante.edu.pe",
                "Diseño y Programación Web", DEFAULT_COURSE, "Alumno123"));
        students.add(new Student("2026002", "Lopez Parado Juan", "juan.lopez@estudiante.edu.pe",
                "Diseño y Programación Web", DEFAULT_COURSE, "Alumno123"));

        courses.add(DEFAULT_COURSE);
        courses.add("Diseño de Interfaces Web");
        courses.add("Base de Datos");

        schedules.add(new Schedule(scheduleId.getAndIncrement(), "LUNES", DEFAULT_COURSE, "08:00", "10:00", "Laboratorio 3"));
        schedules.add(new Schedule(scheduleId.getAndIncrement(), "MIÉRCOLES", "Diseño de Interfaces Web", "10:15", "12:15", "Aula 202"));
        schedules.add(new Schedule(scheduleId.getAndIncrement(), "VIERNES", "Base de Datos", "08:00", "10:00", "Laboratorio 2"));

        LocalDate today = LocalDate.now();
        attendance.add(new Attendance(attendanceId.getAndIncrement(), "2026001", today, LocalTime.of(7, 58), "PRESENTE", DEFAULT_COURSE));
        attendance.add(new Attendance(attendanceId.getAndIncrement(), "2026002", today, LocalTime.of(8, 12), "TARDANZA", DEFAULT_COURSE));
        attendance.add(new Attendance(attendanceId.getAndIncrement(), "2026001", today.minusDays(2), LocalTime.of(8, 1), "PRESENTE", DEFAULT_COURSE));
        attendance.add(new Attendance(attendanceId.getAndIncrement(), "2026002", today.minusDays(2), LocalTime.of(8, 0), "PRESENTE", DEFAULT_COURSE));
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
            courses = state.courses == null ? new ArrayList<>() : state.courses;
            attendanceId = new AtomicInteger(state.nextAttendanceId);
            scheduleId = new AtomicInteger(state.nextScheduleId);
            teacherRecordId = new AtomicInteger(state.nextTeacherRecordId <= 0 ? 1 : state.nextTeacherRecordId);
            if (students == null || attendance == null || schedules == null) return false;
            migrateCourses();
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    private void migrateCourses() {
        if (courses == null) courses = new ArrayList<>();
        addCourseInternal(DEFAULT_COURSE);

        for (Schedule schedule : schedules) {
            if (schedule != null) addCourseInternal(schedule.getCourse());
        }
        for (Student student : students) {
            if (student != null) addCourseInternal(student.getCourse());
        }

        for (Attendance record : attendance) {
            if (record == null) continue;
            if ("Sin curso".equals(record.getCourse())) {
                Student student = findStudentByCode(record.getStudentCode());
                record.setCourse(normalizeCourse(null, student));
            }
            record.setPeriod(normalizePeriod(record.getPeriod()));
        }

        String defaultCourse = getDefaultCourse();
        for (TeacherRecord record : teacherRecords) {
            if (record == null) continue;
            if ("Sin curso".equals(record.getCourse())) record.setCourse(defaultCourse);
        }
        save();
    }

    private synchronized void save() {
        try (ObjectOutputStream out = new ObjectOutputStream(Files.newOutputStream(dataFile))) {
            out.writeObject(new DataState(students, attendance, schedules, teacherRecords, courses,
                    attendanceId.get(), scheduleId.get(), teacherRecordId.get()));
        } catch (IOException ignored) { }
    }

    private void addCourseInternal(String name) {
        String cleanName = safe(name);
        if (cleanName.isEmpty()) return;
        if (courses == null) courses = new ArrayList<>();
        for (String current : courses) {
            if (current != null && current.equalsIgnoreCase(cleanName)) return;
        }
        courses.add(cleanName);
    }

    private String normalizeCourse(String course, Student student) {
        if (!safe(course).isEmpty()) return course.trim();
        if (student != null && !safe(student.getCourse()).isEmpty()) return student.getCourse().trim();
        List<String> options = getCourseOptions();
        return options.isEmpty() ? DEFAULT_COURSE : options.get(0);
    }

    private static String normalizePeriod(String period) {
        String normalized = safe(period).toUpperCase(Locale.ROOT).replace(' ', '_');
        switch (normalized) {
            case "UNIDAD_1":
            case "UNIDAD_2":
            case "UNIDAD_3":
            case "UNIDAD_4":
            case "REGULAR":
                return normalized;
            default:
                return DEFAULT_PERIOD;
        }
    }

    private static boolean timeInside(LocalTime now, String start, String end) {
        try {
            LocalTime startTime = LocalTime.parse(start);
            LocalTime endTime = LocalTime.parse(end);
            return !now.isBefore(startTime) && !now.isAfter(endTime);
        } catch (Exception ex) {
            return false;
        }
    }

    private static String spanishDay(DayOfWeek day) {
        switch (day) {
            case MONDAY: return "LUNES";
            case TUESDAY: return "MARTES";
            case WEDNESDAY: return "MIÉRCOLES";
            case THURSDAY: return "JUEVES";
            case FRIDAY: return "VIERNES";
            case SATURDAY: return "SÁBADO";
            default: return "DOMINGO";
        }
    }

    private static String safe(String value) { return value == null ? "" : value.trim(); }
    private static String defaultValue(String value, String fallback) { return safe(value).isEmpty() ? fallback : value.trim(); }

    private static class DataState implements Serializable {
        private static final long serialVersionUID = 1L;
        List<Student> students;
        List<Attendance> attendance;
        List<Schedule> schedules;
        List<TeacherRecord> teacherRecords;
        List<String> courses;
        int nextAttendanceId;
        int nextScheduleId;
        int nextTeacherRecordId;

        DataState(List<Student> students, List<Attendance> attendance, List<Schedule> schedules,
                  List<TeacherRecord> teacherRecords, List<String> courses,
                  int nextAttendanceId, int nextScheduleId, int nextTeacherRecordId) {
            this.students = students;
            this.attendance = attendance;
            this.schedules = schedules;
            this.teacherRecords = teacherRecords;
            this.courses = courses;
            this.nextAttendanceId = nextAttendanceId;
            this.nextScheduleId = nextScheduleId;
            this.nextTeacherRecordId = nextTeacherRecordId;
        }
    }
}
