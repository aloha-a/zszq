-- MySQL 8.4。初始化脚本在业务库 zszq 中执行。
CREATE TABLE activity (
    activity_id     VARCHAR(64) PRIMARY KEY,
    product_id      VARCHAR(64) NOT NULL,
    total_quota     INT UNSIGNED NOT NULL,
    available_quota INT UNSIGNED NOT NULL,
    per_user_limit  INT UNSIGNED NOT NULL,
    starts_at       DATETIME(6) NOT NULL,
    status          ENUM('DRAFT', 'ONLINE', 'OFFLINE') NOT NULL DEFAULT 'DRAFT',
    CHECK (total_quota > 0 AND available_quota <= total_quota),
    CHECK (per_user_limit > 0)
) ENGINE=InnoDB;

CREATE TABLE purchase_receipt (
    order_id    VARCHAR(64) PRIMARY KEY,
    activity_id VARCHAR(64) NOT NULL,
    user_id     VARCHAR(64) NOT NULL,
    quantity    INT UNSIGNED NOT NULL,
    accepted_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UNIQUE KEY uk_receipt_activity_user (activity_id, user_id),
    FOREIGN KEY (activity_id) REFERENCES activity (activity_id),
    CHECK (quantity > 0)
) ENGINE=InnoDB;

CREATE TABLE stock_ledger (
    order_id    VARCHAR(64) NOT NULL,
    kind        ENUM('DEBIT', 'RELEASE') NOT NULL,
    activity_id VARCHAR(64) NOT NULL,
    quantity    INT UNSIGNED NOT NULL,
    created_at  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (order_id, kind),
    KEY ix_ledger_activity_kind (activity_id, kind),
    FOREIGN KEY (order_id) REFERENCES purchase_receipt (order_id),
    FOREIGN KEY (activity_id) REFERENCES activity (activity_id),
    CHECK (quantity > 0)
) ENGINE=InnoDB;

CREATE TABLE outbox_event (
    event_id        VARCHAR(64) PRIMARY KEY,
    order_id        VARCHAR(64) NOT NULL,
    event_type      VARCHAR(64) NOT NULL,
    payload         JSON NOT NULL,
    status          ENUM('PENDING', 'SENT') NOT NULL DEFAULT 'PENDING',
    attempts        INT UNSIGNED NOT NULL DEFAULT 0,
    next_attempt_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    sent_at         DATETIME(6),
    UNIQUE KEY uk_outbox_order_type (order_id, event_type),
    KEY ix_outbox_due (status, next_attempt_at),
    FOREIGN KEY (order_id) REFERENCES purchase_receipt (order_id)
) ENGINE=InnoDB;

CREATE TABLE purchase_order (
    order_id   VARCHAR(64) PRIMARY KEY,
    quantity   INT UNSIGNED NOT NULL,
    status     ENUM('PENDING_TA', 'CONFIRMED', 'RELEASED') NOT NULL DEFAULT 'PENDING_TA',
    ta_result  ENUM('APPLIED', 'REJECTED'),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    FOREIGN KEY (order_id) REFERENCES purchase_receipt (order_id),
    CHECK (quantity > 0)
) ENGINE=InnoDB;

CREATE TABLE consumed_event (
    event_id    VARCHAR(64) PRIMARY KEY,
    order_id    VARCHAR(64) NOT NULL,
    consumed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    FOREIGN KEY (order_id) REFERENCES purchase_receipt (order_id)
) ENGINE=InnoDB;

CREATE TABLE ta_task (
    order_id        VARCHAR(64) PRIMARY KEY,
    status          ENUM('PENDING', 'DONE', 'REVIEW') NOT NULL DEFAULT 'PENDING',
    attempts        INT UNSIGNED NOT NULL DEFAULT 0,
    next_attempt_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    lease_until     DATETIME(6),
    last_error      VARCHAR(1024),
    KEY ix_ta_task_due (status, next_attempt_at),
    FOREIGN KEY (order_id) REFERENCES purchase_order (order_id)
) ENGINE=InnoDB;
