FROM maven:3.9.11-eclipse-temurin-21 AS build
WORKDIR /source
COPY pom.xml .
COPY activity-service/ activity-service/
COPY purchase-service/ purchase-service/
COPY order-service/ order-service/
COPY mock-ta-service/ mock-ta-service/
RUN --mount=type=cache,id=zszq-maven,target=/root/.m2,sharing=locked mvn -B -ntp verify

FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app
RUN addgroup -S app && adduser -S -G app app
USER app
ENTRYPOINT ["java", "-jar", "/app/service.jar"]

FROM runtime AS activity-service
COPY --from=build /source/activity-service/target/activity-service.jar /app/service.jar

FROM runtime AS purchase-service
COPY --from=build /source/purchase-service/target/purchase-service.jar /app/service.jar

FROM runtime AS order-service
COPY --from=build /source/order-service/target/order-service.jar /app/service.jar

FROM runtime AS mock-ta-service
COPY --from=build /source/mock-ta-service/target/mock-ta-service.jar /app/service.jar
