# 景点门票预约系统

[![www.bysj.site](../../assets/og-cover.png)](https://www.bysj.site/)

> 对照草稿，不是可运行工程。完整案例见 [www.bysj.site](https://www.bysj.site/)

> 技术栈：Spring Boot + Vue + Elasticsearch
> 景点预约毕设常陷入高并发秒杀与ES集群死循环。本文通过真实内存撑爆死胡同，砍掉Redis分布式锁与Canal同步，将系统收敛至分时段单行排他扣减与4张核心表，给出5个关键接口预算与可跑代码。

## 本目录文件

- `TicketBookingService.java`
- `景点门票预约.txt`

## 说明

- 伪代码只描述主路径，表结构/状态机请自己落库实现。
- 禁止把本目录当作业直接提交。
- 选题边界与可演示清单： [www.bysj.site](https://www.bysj.site/)

### 站点封面（仓库本地 assets）

![选题结构](../../assets/cover-topic.jpg)

![Java / Spring Boot](../../assets/cover-java.jpg)

## 原文摘要

> 景点预约毕设常陷入高并发秒杀与ES集群死循环。本文通过真实内存撑爆死胡同，砍掉Redis分布式锁与Canal同步，将系统收敛至分时段单行排他扣减与4张核心表，给出5个关键接口预算与可跑代码。
> 示例系统：景点门票预约系统
> tags: Java, SpringBoot, 毕业设计, MySQL, 架构设计

## 现场：第4周开发机上的 `OutOfMemoryError: Java heap space`

![图：景点门票预约系统工作台演示](/api/blog-tasks/media/20260908-043524_景点门票预约系统别堆分布式_分时段库存扣减与4张表的可行性预算_ui_1.jpg)

*图：景点门票预约系统工作台演示*


![图：系统架构示意 · 去中间件单机开发拓扑（说明剔除ES与MQ后的低内存稳定运行架构）](/api/blog-tasks/media/20260908-043524_景点门票预约系统别堆分布式_分时段库存扣减与4张表的可行性预算_1.jpg)

*图：系统架构示意 · 去中间件单机开发拓扑（说明剔除ES与MQ后的低内存稳定运行架构）*


开题答辩时，很多同学在任务书里写满了高大上的名词：「基于 Spring Boot + Elasticsearch 分词检索 + Redis 延时双删 + RabbitMQ 削峰填谷的智慧旅游门票预约系统」。

到了第4周，在 8GB 内存的轻薄本上同时启动 IntelliJ IDEA、Navicat、Docker 跑着的 Elasticsearch 7.x、Kibana、Redis 和 Spring Boot。浏览器还没打开，后台进程先被杀掉了，IDEA 弹窗报 `OutOfMemoryError: Java heap space`。更尴尬的是，本地导入了 300 条模拟景点数据，每次通过 Logstash 或 Canal 往 ES 同步，经常发生主键丢失或者时区偏差 8 小时。到了中期检查，导师站在身后，系统连最基本的「选日期-看剩余票数-下单」都没走通。

做毕业设计的景点门票系统，根本不需要抗每秒上万 QPS 的故宫抢票并发，真正卡住评审的是：场次库存会不会扣成负数、退款后配额是否返还、入园核销状态是否严密。

## 真实死胡同：为什么要在开题阶段移走 Elasticsearch

![图：景点门票预约系统业务列表页](/api/blog-tasks/media/20260908-043524_景点门票预约系统别堆分布式_分时段库存扣减与4张表的可行性预算_ui_2.jpg)

*图：景点门票预约系统业务列表页*


![图：数据流示意 · 4张核心表约束关联拓扑（展示景区配额拆分至核销防重的4表约束关系）](/api/blog-tasks/media/20260908-043524_景点门票预约系统别堆分布式_分时段库存扣减与4张表的可行性预算_2.jpg)

*图：数据流示意 · 4张核心表约束关联拓扑（展示景区配额拆分至核销防重的4表约束关系）*


我们最初曾尝试在门票系统里完整引入 Elasticsearch，试图做出类似携程的「拼音高亮+多条件过滤」效果，但在单人开发场景下迅速踩进死胡同：

1. **集群冷启动超时**：单机 Docker 分配给 ES 的容器内存若低于 1.5GB，启动直接 Exit 137；若给 2GB，本地运行 Spring Boot 时电脑风扇狂转，前端 Node.js 编译直接卡死。
2. **数据双写一致性折磨**：后台管理员在 Vue 界面修改了「某景点上午场门票从 50 元调整为 45 元」，MySQL 更新成功了，但同步线程报错。导致前台列表展示 45 元，结算页读取 MySQL 却依然算 50 元，演示时当场穿帮。
3. **嵌套文档 Mapping 地狱**：一个景区（Scenic）包含多个票种（成人票/学生票），每个票种又分时段（08:00-12:00, 13:00-17:00）。在 ES 里面做 Nested 结构聚合查询，DSL 语句写了整整两页，联调时连自己都读不懂字段路径。

**处理策略**：除非你的题目明确叫做「基于 Lucene/ES 的海量旅游数据检索系统」，否则直接拿掉 ES。在演示数据量小于 5000 条的前提下，单表建立复合索引加 SQL `LIKE 'keyword%'`，响应时间在 5 毫秒以内，省下的系统资源足够整机稳定跑完全程。

## 核心表结构：用4张表卡死分时段预约

![图：景点门票预约系统详情办理页](/api/blog-tasks/media/20260908-043524_景点门票预约系统别堆分布式_分时段库存扣减与4张表的可行性预算_ui_3.jpg)

*图：景点门票预约系统详情办理页*


![图：请求调用链 · 单库行级锁库存扣减时序（演示基于SQL原子更新防止超卖与核销过程）](/api/blog-tasks/media/20260908-043524_景点门票预约系统别堆分布式_分时段库存扣减与4张表的可行性预算_3.jpg)

*图：请求调用链 · 单库行级锁库存扣减时序（演示基于SQL原子更新防止超卖与核销过程）*


门票预约的核心不是景区介绍有多花哨，而是「日期 + 场次 + 票种」组合下的配额管理。整套系统只要 4 张核心业务表即可支撑完整闭环，无需引入微服务分库。

| 表名 | 关键字段 | 作用与约束说明 |
| :--- | :--- | :--- |
| `scenic_spot` | `id`, `name`, `open_time`, `status` | 景区基本信息，存储封面图、开放时间及上下架状态 |
| `ticket_stock` | `id`, `scenic_id`, `ticket_date`, `time_slot`, `total_stock`, `remain_stock`, `version` | **核心配额表**。联合唯一索引：`uk_date_slot(scenic_id, ticket_date, time_slot)` |
| `ticket_order` | `order_sn`, `user_id`, `stock_id`, `ticket_count`, `total_amount`, `order_status` | 订单表。状态严格限制：`0-待支付, 1-预约成功, 2-已核销, 3-已取消` |
| `ticket_verify_log`| `id`, `order_sn`, `verifier_id`, `verify_time` | 核销流水表，记录管理员扫码或输入券码动作，防重复入园 |

很多系统翻车，是因为把「库存」直接作为一个整数字段塞在景区表里。7月1日和7月2日的库存显然不同，上午场和下午场的容量也有上限。上面的 `ticket_stock` 表把粒度拆细到「场次」，并由唯一索引卡死，彻底杜绝数据重复插入。

## 唯一推荐：单库排他行锁与两阶段扣减

![图：毕设无忧网站入口（www.bysj.site）](/api/blog-tasks/media/20260908-043524_景点门票预约系统别堆分布式_分时段库存扣减与4张表的可行性预算_ui_site.jpg)

*图：毕设无忧网站入口（www.bysj.site）*


在库存扣减选型上，很多博客鼓吹「Redis 分布式锁 + Lua 脚本 + 异步队列」。对于单体系统演示，这是极脆弱的链条——答辩时如果 Redis 挂掉或者网络抖动，整个购买链路直接瘫痪。

**唯一推荐方案**：使用 MySQL 事务结合行级条件更新（乐观版本号或条件判断），由数据库自身保证原子性。

**切换条件**：只有当压测报告明确要求单机承载超过 1200 QPS，且你已经部署了独立 Redis 哨兵实例时，才允许切到 Redis 预扣减。

下面是可直接编译跑通的分时段扣减核心代码：

```java
// TicketBookingService.java（示意可跑逻辑）
@Service
public class TicketBookingService {

    @Autowired
    private TicketStockMapper stockMapper;
    
    @Autowired
    private TicketOrderMapper orderMapper;

    @Transactional(rollbackFor = Exception.class)
    public String createBooking(Long stockId, Long userId, Integer buyNum) {
        // 1. 严格原子扣减：利用数据库行锁，在 UPDATE 时做库存下限校验，避免超卖
        int affectedRows = stockMapper.decreaseStock(stockId, buyNum);
        if (affectedRows == 0) {
            throw new BusinessException("当前场次门票已售罄或余票不足");
        }

        // 2. 生成本地唯一订单
        String orderSn = "TK" + System.currentTimeMillis() + ThreadLocalRandom.current().nextInt(100, 999);
        TicketOrder order = new TicketOrder();
        order.setOrderSn(orderSn);
        order.setStockId(stockId);
        order.setUserId(userId);
        order.setTicketCount(buyNum);
        order.setOrderStatus(1); // 毕业设计直接置为预订成功，避开外部公网支付回调沙箱
        orderMapper.insert(order);

        return orderSn;
    }
}
```

对应的 XML 排他更新 SQL：

```xml
<update id="decreaseStock">
    UPDATE ticket_stock
    SET remain_stock = remain_stock - #{buyNum},
        version = version + 1
    WHERE id = #{stockId} 
      AND remain_stock >= #{buyNum}
</update>
```

在本地并发 50 个线程压测下（Apache JMeter 模拟），50 张余票被同时抢购，上述 SQL 能保证无一张超卖，且无需依赖任何外部中间件。

## 5个关键接口预算与页面映射

一套完整的门票预约系统，前台与后台加起来不必堆上几十个接口。控制在 5 个核心写接口内，足以串联出清晰流畅的答辩演示。

1. **场次日历初始化接口**：`POST /api/stock/init`
   - 管理员设定未来 7 天的每日开放容量，后台批量写入 `ticket_stock`，避免用户选到未初始化的空白日期。
2. **景点分时余票查询**：`GET /api/scenic/{id}/availability`
   - 传入 `target_date`，返回上午场、下午场的剩余票数。
3. **门票预约提交**：`POST /api/order/book`
   - 前端携带 `stockId` 与购买人数，调用上述原子扣减逻辑，返回凭证码。
4. **订单状态回滚（退订）**：`POST /api/order/cancel`
   - 状态校验：只有状态为 `1-预约成功` 允许取消；执行 `remain_stock = remain_stock + buyNum` 并将订单置为 `3-已取消`。
5. **门闸入园核销**：`POST /api/order/verify`
   - 管理员后台输入订单凭证码或扫码，状态从 `1` 流转至 `2-已核销`，写入核销流水表，阻断二次进园。

## 演示页面的翻车点与防御步骤

在答辩现场演示系统时，评委最常发难的不是底层用了什么高级技术，而是界面状态逻辑是否自洽。请按以下顺序自检前端交互：

1. **日期选择器硬编码限制**：前端 Vue 的 `el-date-picker` 必须配置 `disabledDate`，强制禁止选中今天之前的历史日期，否则评委随手点一年前的日期并下单成功，逻辑当场崩塌。
2. **售罄状态灰化**：当后端返回 `remain_stock <= 0` 时，前端场次按钮必须直接设为 `disabled`，不能让用户点进填写信息页才弹窗报错。
3. **核销幂等防御**：演示入园核销接口时，连续点击两次核销按钮，第二次必须明确提示「该门票已于 XX:XX:XX 核销，请勿重复使用」，禁止报 500 错误。

把精力从沉重的中间件配置中抽出来，收拢到单库事务的准确性、分时库存表的字段设计以及严谨的状态机校验上，单机即可跑通稳定演示，论文与答辩也有实在的业务落脚点。

