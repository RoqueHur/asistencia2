EDUASISTENCIA JSP - PROYECTO PARA NETBEANS
==========================================

ESTRUCTURA
----------
Este es un proyecto Maven Web Application. Al abrirlo en NetBeans se mostrará:

- Web Pages
  - META-INF
  - WEB-INF
  - assets
  - index.jsp
  - login.jsp
  - dashboard.jsp
  - asistencia.jsp
  - alumnos.jsp
  - horarios.jsp
  - alumno.jsp
  - registro.jsp
- Source Packages
- Test Packages
- Other Sources
- Dependencies
- Java Dependencies
- Project Files

REQUISITOS
----------
1. Apache NetBeans 17 o superior.
2. JDK 11, 17 o 21.
3. Apache Tomcat 9/10, Payara o GlassFish configurado en NetBeans.

CÓMO ABRIR EN NETBEANS
----------------------
1. Extrae completamente el archivo ZIP.
2. Abre NetBeans.
3. Ve a File > Open Project / Archivo > Abrir proyecto.
4. Selecciona la carpeta EduAsistenciaJSP, no una JSP individual.
5. Espera a que NetBeans cargue el archivo pom.xml.
6. Clic derecho sobre el proyecto > Run / Ejecutar.
7. Si NetBeans pregunta por un servidor, selecciona Tomcat, Payara o GlassFish.
8. El navegador abrirá una dirección similar a:
   http://localhost:8080/EduAsistenciaJSP/

CREDENCIALES
------------
PROFESOR
Usuario: profesor@edumanage.pe
Contraseña: Profesor123

ALUMNOS
Roque Hurtado Dilber
Usuario: 2026001
Contraseña: Alumno123

Lopez Parado Juan
Usuario: 2026002
Contraseña: Alumno123

CÁMARA
------
La cámara funciona al ejecutar la aplicación desde localhost. Usa Chrome o Edge y acepta el permiso de cámara.
El navegador debe admitir BarcodeDetector para leer QR automáticamente. Si no lo admite, la cámara igual se enciende y se puede usar el botón "Marcar manualmente".

DATOS
-----
Los alumnos, asistencias y horarios creados se guardan en:
C:\Users\TU_USUARIO\.eduasistencia\datos.ser

Para restablecer los datos iniciales, cierra el servidor y elimina esa carpeta.

ARCHIVO WAR
-----------
En la carpeta dist se incluye EduAsistenciaJSP.war. Puede copiarse directamente a la carpeta webapps de Tomcat.
