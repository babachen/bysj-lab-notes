# 快递代收管理系统

[![www.bysj.site](../../assets/og-cover.png)](https://www.bysj.site/)

> 对照草稿，不是可运行工程。完整案例见 [www.bysj.site](https://www.bysj.site/)

> 技术栈：Django + Vue + PostgreSQL
> 多数快递代收毕设卡在商业开放平台资质审核与短信API封禁。本文剔除公网运单爬取与真实短信依赖，将系统收敛至站内货位三段码与本地事务核销，给出5个核心接口预算与最小表结构，保障单人单机稳定演示。

## 本目录文件

- `快递代收管理_schema.sql`
- `快递代收管理_flow.pseudo`
- `PackageService.py`

## 说明

- 伪代码只描述主路径，表结构/状态机请自己落库实现。
- 禁止把本目录当作业直接提交。
- 选题边界与可演示清单： [www.bysj.site](https://www.bysj.site/)

### 站点封面（仓库本地 assets）

![选题结构](../../assets/cover-topic.jpg)

![Java / Spring Boot](../../assets/cover-java.jpg)

## 原文摘要

> 多数快递代收毕设卡在商业开放平台资质审核与短信API封禁。本文剔除公网运单爬取与真实短信依赖，将系统收敛至站内货位三段码与本地事务核销，给出5个核心接口预算与最小表结构，保障单人单机稳定演示。
> 示例系统：快递代收管理系统
> tags: 计算机毕设, 系统设计, Django, PostgreSQL, 架构设计

### 现场记录：开题第3周的外部接口调用瘫痪

「老师，为什么顺丰开放平台个人申请不了沙箱密钥？快递100的免费接口查了20次就被封了IP，入库测试全卡在网络超时。」

这是做代收系统时最普遍的卡点。不少人在任务书里把系统画得像菜鸟驿站全网调度中心：对接三通一达、自动同步物流轨迹、向真实手机号发送提货短信、扫码枪硬件协议直连。到第3周联调，外部短信服务商要求企业营业执照，公网查单API频控报错 HTTP 429，本地网络只要断开，出入库功能全部不可用。

代收站的业务本质是**末端仓储的货位流转与凭证核销**，不是物流主干网的路由追踪。把外部公网依赖当成核心功能，等于把系统生命线交给不可控的第三方第三方凭据。

---

### 真实死胡同：公网运单爬取与第三方短信网关

最初的工程原型往往是这样崩溃的：

1. 在包裹入库视图里，直接发起 HTTP 请求调用第三方物流接口校验单号真实性。
2. 校验通过后，调用云短信服务给收件人发 6 位提货码。
3. 用户凭短信提货码到前台出库。

在本地开发环境（Python 3.10 + 单节点，数据量仅模拟 50 条）下，这套流程暴露出致命硬伤：

- **接口频控与网络抖动**：第三方免费查询接口通常限制每分钟 5 到 10 次调用。答辩演示时连点 3 次「批量入库」，前端直接弹红字报错。
- **短信通道黑洞**：未报备签名的个人账号发送验证码会被运营商拦截，哪怕充值了 50 条测试短信，答辩现场如果遇到 30 秒以上的短信延迟，提货出库流程根本走不下去。

**应对方案**：将公网运单轨迹彻底从主干业务剥离。系统自建运单号只作为业务检索字符，不再发起公网探活；提货码改为站内纯离线算法生成，通知渠道直接沉淀为数据库内的待领通知表，前台提供大屏看板与个人查询页查看提货码。

---

### 模块边界对照与5个核心接口预算

将代收站收敛至独立闭环，单人开发只需实现 5 个业务接口即可满足完整演进要求。

| 功能域 | 常见过度设计 | 本方案收敛边界 | 答辩验收指标 |
| :--- | :--- | :--- | :--- |
| **入库建单** | 跨平台爬取外部轨迹、OCR识别面单 | 手动录入/模拟扫码单号，分配货位 | 货位状态变为占用，生成单据 |
| **货位调度** | 3D仓储建模、自动最优路径规划 | 静态三段码（排-架-层），冲突校验 | 货位唯一占用，禁止重入 |
| **提货通知** | 阿里云/腾讯云真实短信推送 | 站内取件记录表 + 虚拟通知看板 | 前台可查 6 位凭证码 |
| **核销出库** | 人脸识别、身份证读卡器硬件集成 | 提货码匹配 + 手机尾号双重校验 | 状态跳变，货位释放 |
| **滞留处理** | 催领电话自动外呼系统 | 超期 72 小时标记 + 批处理滞留状态 | 标记异常，支持一键催领状态更新 |

#### 5个最小接口定义

1. `POST /api/v1/packages/inbound`：包裹入库并占用指定货位。
2. `GET /api/v1/packages/pickup-code`：凭手机号/运单号查询站内取件码。
3. `POST /api/v1/packages/outbound`：核销取件码，释放货位，包裹归档。
4. `GET /api/v1/shelves/status`：获取当前代收点货位排布与占用概况。
5. `POST /api/v1/packages/overdue-batch`：触发超时滞留扫描（标记未取件包裹）。

---

### 唯一技术栈推荐与切换判断

**默认推荐**：`Django 4.2 + PostgreSQL 14 + Vue 3`。

选用 PostgreSQL 的核心原因在于其支持**部分唯一索引（Partial Unique Index）**。代收点最严重的并发故障是两个包裹被分配到同一个物理货位。利用数据库层面的排他约束，可以在不依赖 Redis 分布式锁的前提下，直接在存储引擎层杜绝货位冲突。

**切换条件**：如果导师明确指定 Java 技术栈或学校只提供 MySQL 5.7 实验室镜像，则切换为 `Spring Boot 3 + MySQL 8.0`。在 MySQL 方案中，必须在入库事务内对货位行使用 `SELECT ... FOR UPDATE` 加悲观锁，防止并发抢位。

---

### 最小表结构设计（PostgreSQL）

```sql
-- 货位基础表：采用三段码结构，例如 A-01-03 表示 A区 1架 3层
CREATE TABLE shelf_slot (
    id SERIAL PRIMARY KEY,
    slot_code VARCHAR(16) NOT NULL UNIQUE,
    zone_code VARCHAR(8) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 包裹流转表
CREATE TABLE package_item (
    id BIGSERIAL PRIMARY KEY,
    tracking_number VARCHAR(64) NOT NULL,
    receiver_phone VARCHAR(11) NOT NULL,
    shelf_slot_id INT NOT NULL REFERENCES shelf_slot(id),
    pickup_code VARCHAR(6) NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'STORED', -- STORED(在库), PICKED(已取), OVERDUE(滞留)
    inbound_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    outbound_at TIMESTAMP WITH TIME ZONE
);

-- 核心约束：在库包裹不得共享同一货位（部分唯一索引）
CREATE UNIQUE INDEX uidx_active_shelf_slot 
ON package_item (shelf_slot_id) 
WHERE status = 'STORED';
```

---

### 核心用例伪代码：带货位防重与凭证核销

```pseudo
FUNCTION handle_package_inbound(tracking_num, phone, target_slot_id):
    BEGIN TRANSACTION
        // 1. 检查单号是否已在库
        existing = SELECT id FROM package_item 
                   WHERE tracking_number = tracking_num AND status = 'STORED'
        IF existing IS NOT NULL THEN
            ROLLBACK
            RETURN Error("该运单已在代收点在库，无法重复入库")
        END IF
        
        // 2. 检查并锁定货位状态
        slot = SELECT id, is_active FROM shelf_slot WHERE id = target_slot_id FOR UPDATE
        IF slot IS NULL OR slot.is_active == FALSE THEN
            ROLLBACK
            RETURN Error("无效货位")
        END IF
        
        // 3. 本地生成 6 位确定性校验码（结合时间戳与手机号取模，非外部依赖）
        code = GENERATE_OFFLINE_PIN(phone)
        
        // 4. 插入在库记录（若此时该货位被并发占用，数据库唯一索引将抛出异常）
        TRY:
            INSERT INTO package_item(tracking_number, receiver_phone, shelf_slot_id, pickup_code, status)
            VALUES (tracking_num, phone, target_slot_id, code, 'STORED')
            COMMIT TRANSACTION
            RETURN Success(pickup_code = code)
        CATCH UniqueConstraintViolation:
            ROLLBACK
            RETURN Error("货位已被并发占用，请重新选择货位")
END FUNCTION
```

---

### 核心实现草稿（Django 事务核销）

以下为核心业务草稿（基于 Django ORM），读者需结合自身异常体系扩展。

```python
# services.py (草稿示意，不超过40行)
from django.db import transaction, IntegrityError
from django.utils import timezone
from .models import PackageItem, ShelfSlot

class PackageService:
    @staticmethod
    def process_inbound(tracking_num: str, phone: str, slot_id: int) -> dict:
        try:
            with transaction.atomic():
                # 利用 PostgreSQL partial index 阻断重复绑定
                item = PackageItem.objects.create(
                    tracking_number=tracking_num,
                    receiver_phone=phone,
                    shelf_slot_id=slot_id,
                    pickup_code=PackageService._calc_pickup_code(phone),
                    status='STORED'
                )
                return {"code": 200, "pickup_code": item.pickup_code}
        except IntegrityError:
            return {"code": 409, "message": "货位冲突或单号在库重复"}

    @staticmethod
    def process_outbound(pickup_code: str, phone_tail: str) -> bool:
        with transaction.atomic():
            item = PackageItem.objects.select_for_update().filter(
                pickup_code=pickup_code,
                receiver_phone__endswith=phone_tail,
                status='STORED'
            ).first()
            if not item:
                return False
            item.status = 'PICKED'
            item.outbound_at = timezone.now()
            item.save(update_fields=['status', 'outbound_at'])
            return True
```

---

### 一个可反驳的技术判断

**毕设阶段的快递代收系统，完全不需要做取件短信发送功能，哪怕用免费测试配额也是负资产。**

收回该判断的唯一条件：导师在任务书中明确要求了硬件外设联动，且学院实验室能提供物理 GSM 短信猫串口模块进行本地收发实验。如果只是调用公网 HTTP 短信接口，它的技术含量在答辩时基本等同于零，却引入了鉴权过期、余额不足、外部网络中断等三大不可抗力故障点。

---

### 今晚可执行的收敛步骤

1. **清理任务书功能模块**：删掉「各大快递轨迹实时追踪」与「短信网关集成」，修改为「代收站内部货位周转」与「离线提货码核销」。
2. **构建货位字典表**：在数据库预先录入 30 到 50 个规范格式的物理货位（如 `A-01-01` 至 `B-03-05`）。
3. **本地基准验证**：在本地开发环境运行入库逻辑，连续插入两个绑定相同货位的在库记录，确保数据库第 2 次能够准确抛出冲突并返回受控的 409 状态码。

---

## 实践备忘

技术细节到这里可以告一段落。若你还卡在**题目能不能做完、栈怎么选、演示怎么兜底**，可以把公开的选题自检与案例结构当参考——自己写代码、自己改论文，资料只作对照。

![毕设项目推进指南封面](../../assets/cover-guide.jpg)

*从环境、模块拆分到答辩叙事，按清单推进更稳*

![毕设验收清单封面](../../assets/cover-checklist.jpg)

*上线/演示前用清单自检，少返工*

完整案例与选题自检：[www.bysj.site](https://www.bysj.site/) · [选题自检](https://www.bysj.site/free-topic-check.html)

仓库里只放设计草稿和伪代码，完整实现请对照站点案例自己完成。

