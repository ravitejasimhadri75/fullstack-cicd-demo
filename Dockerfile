FROM eclipse-temurin:17-jdk
WORKDIR /app

# copy backend jar produced by mvn package
COPY backend/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
