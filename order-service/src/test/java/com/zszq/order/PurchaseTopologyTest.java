package com.zszq.order;

import org.junit.jupiter.api.Test;
import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.Declarables;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.tuple;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.NONE)
class PurchaseTopologyTest {
    @Autowired
    ApplicationContext context;

    @Test
    void routesAcceptedEventsAndDeadLettersToTheirOwnQueues() {
        var bindings = context.getBeansOfType(Declarables.class).values().stream()
                .flatMap(group -> group.getDeclarablesByType(Binding.class).stream())
                .toList();

        assertThat(bindings)
                .extracting(Binding::getExchange, Binding::getRoutingKey, Binding::getDestination)
                .contains(tuple("purchase.events", "purchase.accepted", "order.purchase-accepted"),
                        tuple("purchase.dead", "purchase.accepted", "order.purchase-accepted.dead"));
    }
}
