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
}
