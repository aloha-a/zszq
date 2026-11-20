package com.zszq.order.messaging;

import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Declarables;
import org.springframework.amqp.core.DirectExchange;
import org.springframework.amqp.core.QueueBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration(proxyBeanMethods = false)
class PurchaseQueueConfiguration {
    @Bean
    Declarables purchaseAcceptedTopology() {
        var events = new DirectExchange("purchase.events");
        var deadLetters = new DirectExchange("purchase.dead");
        var routingKey = "purchase.accepted";
        var accepted = QueueBuilder.durable("order.purchase-accepted")
                .quorum()
                .deadLetterExchange(deadLetters.getName())
                .withArgument("x-dead-letter-strategy", "at-least-once")
                .withArgument("x-overflow", "reject-publish")
                .build();
        var failed = QueueBuilder.durable("order.purchase-accepted.dead").quorum().build();

        return new Declarables(events, deadLetters, accepted, failed,
                BindingBuilder.bind(accepted).to(events).with(routingKey),
                BindingBuilder.bind(failed).to(deadLetters).with(routingKey));
    }
}
