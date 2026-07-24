package com.eduasistencia.util;

public final class WebUtil {
    private WebUtil() {}

    public static String h(String value) {
        if (value == null) return "";
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    public static String normalizeStatus(String value) {
        if (value == null) return "PRESENTE";
        String normalized = value.trim().toUpperCase();
        switch (normalized) {
            case "TARDANZA":
            case "FALTA":
            case "JUSTIFICADO":
            case "PRESENTE":
                return normalized;
            default:
                return "PRESENTE";
        }
    }

    public static String normalizePeriod(String value) {
        if (value == null) return "UNIDAD_4";
        String normalized = value.trim().toUpperCase().replace(' ', '_');
        switch (normalized) {
            case "UNIDAD_1":
            case "UNIDAD_2":
            case "UNIDAD_3":
            case "UNIDAD_4":
            case "REGULAR":
                return normalized;
            default:
                return "UNIDAD_4";
        }
    }

    public static String periodLabel(String value) {
        switch (normalizePeriod(value)) {
            case "UNIDAD_1": return "UNIDAD 1";
            case "UNIDAD_2": return "UNIDAD 2";
            case "UNIDAD_3": return "UNIDAD 3";
            case "REGULAR": return "REGULAR";
            default: return "UNIDAD 4";
        }
    }
}
