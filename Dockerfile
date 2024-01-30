FROM      maven as BUILD
RUN       mkdir /app
WORKDIR   /app
COPY      pom.xml .
COPY      src src
RUN       mvn clean package

FROM      openjdk:8-jdk
COPY      --from=BUILD /app/target/shipping-1.0.jar /shipping.jar
CMD       ["java", "-jar", "/shipping.jar"]