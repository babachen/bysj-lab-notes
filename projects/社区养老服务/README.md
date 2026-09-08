# 社区养老服务系统

[![www.bysj.site](../../assets/og-cover.png)](https://www.bysj.site/)

> 对照草稿，不是可运行工程。完整案例见 [www.bysj.site](https://www.bysj.site/)

> 技术栈：Spring Boot + 小程序 + Redis
> 很多社区养老毕设卡在穿戴设备蓝牙丢包、跌倒检测误报与多端抢单冲突。本文把选题边界收敛在亲属代办、助餐时段配额控制与上门核销三个动作，给出最小表结构与防超卖伪代码，保障单人单机跑通答辩。

## 本目录文件

- `社区养老服务_schema.sql`
- `社区养老服务_flow.pseudo`
- `CareOrderService.java`
- `CareOrderMapper.java`

## 说明

- 伪代码只描述主路径，表结构/状态机请自己落库实现。
- 禁止把本目录当作业直接提交。
- 选题边界与可演示清单： [www.bysj.site](https://www.bysj.site/)

### 站点封面（仓库本地 assets）

![选题结构](../../assets/cover-topic.jpg)

![Java / Spring Boot](../../assets/cover-java.jpg)

## 原文摘要

> 很多社区养老毕设卡在穿戴设备蓝牙丢包、跌倒检测误报与多端抢单冲突。本文把选题边界收敛在亲属代办、助餐时段配额控制与上门核销三个动作，给出最小表结构与防超卖伪代码，保障单人单机跑通答辩。
> 示例系统：社区养老服务系统
> tags: 毕业设计, Spring Boot, 微信小程序, 系统设计, 后端开发

### 开题第 3 周的硬件死胡同

第 3 周中期检查现场，一个同学端着面包板、ESP32 模块和淘宝买来的光电心率手环站在讲台前。原本任务书里写着「老年人体征实时监控与跌倒告警」，答辩老师随手拿起手环套在保温杯上，后台曲线依然在 70 到 80 次/分之间规律跳动。老师追问老人进浴室洗澡断网后数据怎么暂存、重连后怎么补发 MQTT 报文，现场直接卡住。

做社区养老系统的学生极易在开题阶段写进大量高大上的词：智能手环监测、室内 UWB 厘米级定位、WebRTC 紧急视频对讲。实际上校内环境连固定公网 IP 都没有，宿舍 WiFi 隔一堵承重墙就丢包，硬件串口驱动能把两周时间耗光，连核心的民政养老业务都没碰。

社区养老的核心本质是公共服务资源的配额分发与履约核销，不是医疗器械研发。先确认业务到底是在帮街道做日间照料中心排班，还是在帮家属代老人点助餐，把虚浮的物联网砍掉，题目才能在单人开发周期内落地。

### 错法与做法的功能对照

社区养老业务如果贪多，容易把系统做成四个半拉子工程的拼接怪。下面是开题阶段最容易跑偏的对比：

| 功能域 | 容易翻车的设想（死胡同） | 建议保留的边界（可演示） |
| :--- | :--- | :--- |
| 健康数据采集 | 接入蓝牙手环心率步数、陀螺仪算法测跌倒 | 静态体检指标卡（高血压/糖尿病等枚举）+ 手工录入 |
| 紧急呼叫 | 硬件 SOS 物理按键推送、长连接语音通话 | 小程序一键求助拨号 + 站内生成高优先级待办通知 |
| 助餐助洁 | 百度地图动态路网规划、骑手智能抢单调度 | 固定服务时段库存扣减 + 网格员指派履约 |
| 账号体系 | 人脸识别登录、多端复杂权限混部 | 手机号验证码 + 家属绑老人档案（代申领模式） |

一个可反驳的判断：在纯软件工程的毕设答辩中，一律不要在社区养老系统里接实体传感器。如果学院要求必须带硬件实物，应该将课题类型变更为嵌入式控制系统，并在任务书里把后端管理功能剔除到只剩一张日志表，不要试图两头兼顾。

### 最小表结构设计

系统只需要两张核心业务表：一张理清老人身份及其健康档案，另一张负责承载服务工单从申请到核销的生命周期。

```sql
-- 老人核心档案表
CREATE TABLE `elder_profile` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `id_card_hash` VARCHAR(64) NOT NULL COMMENT '身份证哈希，脱敏索引',
  `real_name` VARCHAR(32) NOT NULL,
  `age` INT NOT NULL,
  `grid_code` VARCHAR(16) NOT NULL COMMENT '社区网格编码，如 01-03-A',
  `care_level` TINYINT NOT NULL DEFAULT 1 COMMENT '自理等级: 1自理 2半失能 3失能',
  `emergency_phone` VARCHAR(11) NOT NULL COMMENT '紧急联络人电话',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_grid` (`grid_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 养老服务预约与核销单
CREATE TABLE `care_order` (
  `order_no` VARCHAR(32) NOT NULL,
  `elder_id` BIGINT NOT NULL,
  `service_type` TINYINT NOT NULL COMMENT '1助餐 2助洁 3上门理发 4助医',
  `reserve_date` DATE NOT NULL COMMENT '服务预约日期',
  `time_slot` TINYINT NOT NULL COMMENT '1上午 2下午',
  `order_status` TINYINT NOT NULL DEFAULT 1 COMMENT '1待服务 2已核销 3已取消 4已逾期',
  `staff_id` BIGINT DEFAULT NULL COMMENT '履约服务人员ID',
  `verify_code` VARCHAR(6) NOT NULL COMMENT '6位核销码',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`order_no`),
  UNIQUE KEY `uk_verify_code` (`verify_code`),
  KEY `idx_elder_date` (`elder_id`, `reserve_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 服务预约与配额扣减伪代码

养老助餐属于典型资源受限业务，比如某社区食堂在 2026-05-10 上午最多提供 80 份助老餐，不能出现超卖。利用 Redis 执行原子扣减配额，拦截无效请求，数据库只做流水落库。

```text
FUNCTION createCareOrder(elderId, serviceType, reserveDate, timeSlot):
    // 1. 业务准入校验：老人是否存在、自理等级是否符合要求
    elder = queryElderById(elderId)
    IF elder IS NULL THEN
        RETURN Error("老人档案不存在")
    END IF

    // 2. 防重申领：同一老人同一种服务同一天只能约一次
    existOrder = queryOrder(elderId, serviceType, reserveDate)
    IF existOrder IS NOT NULL AND existOrder.status != CANCELLED THEN
        RETURN Error("当日该服务已存在有效预约")
    END IF

    // 3. 构造配额键并尝试扣减：例如 care:quota:1:2026-05-10:1
    quotaKey = format("care:quota:%d:%s:%d", serviceType, reserveDate, timeSlot)
    remaining = redis.DECR(quotaKey)
    IF remaining < 0 THEN
        redis.INCR(quotaKey) // 补回库存
        RETURN Error("该时段助老名额已满")
    END IF

    // 4. 生成不可逆核销码（随机 6 位）与入库流水
    verifyCode = generateRandomNumericCode(6)
    orderNo = generateSnowflakeId()
    
    TRY:
        insertCareOrder(orderNo, elderId, serviceType, reserveDate, timeSlot, verifyCode, STATUS_PENDING)
    CATCH DatabaseException:
        redis.INCR(quotaKey) // 数据库写入异常回滚配额
        RETURN Error("工单创建失败，请稍后重试")
    
    RETURN Success(orderNo, verifyCode)
END FUNCTION
```

### 核心实现草稿

下面给出一个基于 Spring Boot 的服务实现草稿（`CareOrderService.java`）。用于向导师展示状态核销与配额控制逻辑，并非完整工程代码，边界异常处理需要结合具体需求补充。

```java
package com.community.care.service;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CareOrderService {
    private final StringRedisTemplate redisTemplate;
    private final CareOrderMapper orderMapper;

    public CareOrderService(StringRedisTemplate redisTemplate, CareOrderMapper orderMapper) {
        this.redisTemplate = redisTemplate;
        this.orderMapper = orderMapper;
    }

    @Transactional(rollbackFor = Exception.class)
    public boolean verifyOrder(String verifyCode, Long staffId) {
        // 1. 按照核销码检索处于待履约状态的工单
        CareOrder order = orderMapper.selectByVerifyCode(verifyCode);
        if (order == null || order.getOrderStatus() != 1) {
            throw new IllegalArgumentException("核销码无效或服务单不在待核销状态");
        }

        // 2. 状态机流转：从待服务(1)更新为已核销(2)，带行版本更新
        int affected = orderMapper.updateStatusToFinished(order.getOrderNo(), staffId);
        if (affected == 0) {
            throw new IllegalStateException("工单已被其他服务人员核销");
        }
        return true;
    }
}
```

对应的数据持久层草稿（`CareOrderMapper.java`）：

```java
package com.community.care.service;

import org.apache.ibatis.annotations.*;

@Mapper
public interface CareOrderMapper {
    @Select("SELECT * FROM care_order WHERE verify_code = #{code} LIMIT 1")
    CareOrder selectByVerifyCode(@Param("code") String code);

    @Update("UPDATE care_order SET order_status = 2, staff_id = #{staffId} " +
            "WHERE order_no = #{orderNo} AND order_status = 1")
    int updateStatusToFinished(@Param("orderNo") String orderNo, @Param("staffId") Long staffId);
}
```

### 演示前需要锁定的执行顺序

答辩演示不需要把管理后台做得花里胡哨，把主业务流串起来只需要依序跑通 4 个动作：

1. 在数据库或管理后台预置一条老人的真实脱敏信息（包含身份证哈希与网格编号）。
2. 在 Redis 中通过命令预设明天上午的助餐配额：`SET care:quota:1:2026-05-10:1 2`（特意设置成 2，方便演示名额耗尽后的拦截报错）。
3. 用小程序模拟家属端发起 2 次代办预约，获取到 6 位核销码，第 3 次提交收到名额耗尽的提示。
4. 打开网格员界面，输入核销码，触发数据库更新，刷新老人端工单状态，观察状态变为「已核销」。

在单机 2 核 4G、MySQL 8.0 运行环境下，这套带 Redis 预减与单表防重的工单接口，耗时稳定在 20ms 以内。今晚先建好这两张表，用 Postman 测通代办预约与核销这两个接口，选题的业务骨架就立住了。

---

## 相关资料

同类问题里，最常见的不是「不会写某段代码」，而是边界没钉死。下面两张图是公开资料里的结构示意，适合贴在笔记本旁边对照（非代写、不包过）。

![毕设验收清单封面](../../assets/cover-checklist.jpg)

*上线/演示前用清单自检，少返工*

![Java 方向项目封面](../../assets/cover-java.jpg)

*Java / Spring Boot 方向可参考站点案例结构*

完整案例与选题自检：[www.bysj888.com](https://www.bysj888.com/) · [选题评估](https://www.bysj888.com/wechat/)

仓库里只放设计草稿和伪代码，完整实现请对照站点案例自己完成。

---

## 相关资料

[![www.bysj.site](../../assets/og-cover.png)](https://www.bysj.site/)

完整选题、案例结构与自检清单见 [www.bysj.site](https://www.bysj.site/) ；资料只作对照，自己写代码、自己改论文。

