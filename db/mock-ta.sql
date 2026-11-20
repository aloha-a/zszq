-- 本地 TA 使用独立数据库保存按单号查询的终局结果。
CREATE DATABASE zszq_ta CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_bin;
GRANT SELECT, INSERT, UPDATE ON zszq_ta.* TO 'zszq'@'%';

CREATE TABLE zszq_ta.ta_result (
    order_id    VARCHAR(64) PRIMARY KEY,
    activity_id VARCHAR(64) NOT NULL,
    user_id     VARCHAR(64) NOT NULL,
    quantity    INT UNSIGNED NOT NULL,
    result      ENUM('APPLIED', 'REJECTED') NOT NULL,
    recorded_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CHECK (quantity > 0)
) ENGINE=InnoDB;
