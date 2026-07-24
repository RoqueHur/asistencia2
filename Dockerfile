FROM maven:3.9-eclipse-temurin-17 AS build 
WORKDIR /app 
COPY . . 
RUN mvn clean package -DskipTests 
 
FROM tomcat:10-jdk17 
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/ROOT.war 
EXPOSE 8080 
