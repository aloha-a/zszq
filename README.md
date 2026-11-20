# 限量产品预约抢购系统

Java 21、Spring Boot 3.5 和 Maven 多模块工程。本地环境包含四个服务，网关默认把抢购请求分发给两个抢购实例。当前可以启动服务、检查依赖、核对表结构和队列路由。活动管理、库存扣减和异步履约将在此基础上实现。

## 启动本地环境

在仓库根目录运行以下命令。需要 Docker Desktop 或 Docker Engine、Compose v2.20 以上版本及 Linux 容器。构建镜像内置 JDK 和 Maven。首次启动会下载镜像及构建依赖，并在新数据卷中初始化数据库。

```sh
docker compose up -d --build --wait
docker compose ps
```

网关默认地址为 `http://127.0.0.1:8080`。以下路径通过网关检查真实服务的就绪状态。抢购探针还返回 `X-Upstream-Address` 响应头，可据此区分实例。

| 模块 | 职责 | 网关就绪检查 | 单独用 JVM 启动时的默认端口 |
| --- | --- | --- | --- |
| `activity-service` | 活动配置、上下线和活动查询 | `/health/activity` | 8081 |
| `purchase-service` | 抢购受理、库存扣减、本人查单和待发事件 | `/health/purchase` | 8082 |
| `order-service` | 订单消费、下游待办和履约 | `/health/order` | 8083 |
| `mock-ta-service` | 本地账户／TA 模拟服务 | `/health/ta` | 8084 |

业务路由已预留。`/api/activities/{id}/purchases` 及其子路径转给抢购服务，其余活动接口转给活动服务。健康检查已可调用，预留业务接口在对应控制器实现前返回 404。网关沿用调用方的 `X-Request-Id`，缺省时生成新值。运行 `docker compose logs gateway` 可按请求 ID 核对上游地址与耗时。

## 验证启动与分流

在 Windows PowerShell 中可读取就绪结果及上游地址。

```powershell
curl.exe -i http://127.0.0.1:8080/health/purchase
```

四个服务就绪后，可以使用 Python 3 标准库运行两项冒烟测试。第一项检查四个入口，第二项连续请求网关并核对至少两个不同的抢购上游地址。

```sh
python -m unittest discover -s tests/smoke -v
```

MySQL 是受理数据源，抢购就绪检查只依赖应用状态和 MySQL。订单服务还检查 RabbitMQ。框架测试覆盖消息队列离线时抢购入口的就绪条件，以及订单正常队列和死信队列的绑定。

## 数据与消息

- 业务库 `zszq` 有活动、受理、库存流水、待发事件、业务订单、消费记录和下游待办七张表。受理表对活动与用户设唯一约束，库存流水以单号和流水类型为联合主键。[业务表结构](db/schema.sql)
- 本地 TA 使用同一个 MySQL 实例内的独立库 `zszq_ta`，以单号为主键保存终局结果。[模拟服务表结构](db/mock-ta.sql)
- 订单服务首次连接 RabbitMQ 时声明持久化交换机和队列。`purchase.events` 通过路由键 `purchase.accepted` 投递至 `order.purchase-accepted`。死信通过 `purchase.dead` 和相同路由键进入 `order.purchase-accepted.dead`。
- MySQL 和 RabbitMQ 使用命名数据卷。建表脚本仅在新 MySQL 数据卷初始化时执行。停用本地服务可运行 `docker compose stop`，再次运行 `docker compose up -d --wait` 可沿用已有数据。

## 在 IDE 中开发

本机安装 JDK 21 和 Maven 3.9 后，可将根目录的 `pom.xml` 作为 Maven 工程导入。下面的命令先启动开发依赖，再测试、打包全部模块，最后在本机启动一个抢购实例。

```sh
docker compose up -d --wait mysql rabbitmq
mvn -B -ntp verify
java -jar purchase-service/target/purchase-service.jar
```

本机实例可直接访问 `http://127.0.0.1:8082/actuator/health/readiness`。运行其他模块时选择对应的主类或 JAR 即可。`SERVER_PORT` 可覆盖单个 JVM 的监听端口。

| 本地依赖 | 默认连接 | 默认开发账号 |
| --- | --- | --- |
| MySQL | `127.0.0.1:3306` | `zszq / zszq_local` |
| RabbitMQ AMQP | `127.0.0.1:5672` | `zszq / zszq_local` |
| RabbitMQ 管理界面 | `http://127.0.0.1:15672` | 同上 |

Compose 仅将端口绑定到本机回环地址。可在根目录的 `.env` 调整 `GATEWAY_PORT`、`MYSQL_PORT`、`RABBITMQ_PORT` 和 `RABBITMQ_UI_PORT`。首次建库前可覆盖 `MYSQL_PASSWORD`、`MYSQL_ROOT_PASSWORD` 和 `RABBITMQ_PASSWORD`。用 IDE 启动时将同样的依赖端口和密码设成进程环境变量。若更改网关端口，运行冒烟测试前将 `ZSZQ_BASE_URL` 指向对应地址。

## 项目文档

[业务规格与验收矩阵](docs/SPEC.md) · [两周实施计划](docs/superpowers/plans/2026-11-19-限量产品预约抢购系统实施计划.md) · [项目过程记录](docs/过程记录.md)
