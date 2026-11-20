package com.zszq.purchase;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpStatus;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "spring.datasource.url=jdbc:h2:mem:purchase",
        "spring.datasource.username=sa",
        "spring.datasource.password=",
        "spring.rabbitmq.host=127.0.0.1",
        "spring.rabbitmq.port=1",
        "management.endpoint.health.group.readiness.show-components=always"
})
class PurchaseReadinessTest {
    @Autowired
    TestRestTemplate http;

    @Test
    void purchaseIsReadyWithAWorkingDatabaseAndAnUnavailableBroker() {
        var response = http.getForEntity("/actuator/health/readiness", JsonNode.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().path("components").path("db").path("status").asText())
                .isEqualTo("UP");
    }
}
