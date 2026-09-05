# 招聘信息发布系统

[![www.bysj.site](../../assets/og-cover.png)](https://www.bysj.site/)

> 对照草稿，不是可运行工程。完整案例见 [www.bysj.site](https://www.bysj.site/)

> 技术栈：Python Flask + Vue + MySQL
> 很多招聘毕设卡在简历OCR解析、爬虫封禁与复杂推荐算法。本文将系统边界收缩至企业审核闭环与投递快照，给出模块拆分、最小表结构及投递核心草稿，省去冗余中间件，保障单人演示可行性。

## 本目录文件

- `招聘信息发布_schema.sql`
- `招聘信息发布_flow.pseudo`
- `JobService.py`

## 说明

- 伪代码只描述主路径，表结构/状态机请自己落库实现。
- 禁止把本目录当作业直接提交。
- 选题边界与可演示清单： [www.bysj.site](https://www.bysj.site/)

### 站点封面（仓库本地 assets）

![选题结构](../../assets/cover-topic.jpg)

![Java / Spring Boot](../../assets/cover-java.jpg)

## 原文摘要

> 很多招聘毕设卡在简历OCR解析、爬虫封禁与复杂推荐算法。本文将系统边界收缩至企业审核闭环与投递快照，给出模块拆分、最小表结构及投递核心草稿，省去冗余中间件，保障单人演示可行性。
> 示例系统：招聘信息发布系统
> tags: 毕业设计, Python, Flask, 系统设计, 数据库设计

### 开题第3周的答辩现场

开题答辩第3周，导师在评审表上划了两道红线，直接提了两个问题：

1. 「你说岗位靠爬虫定时抓取，答辩当天演示如果目标网站改版或者把你 IP 封了，你现场看空白列表？」
2. 「学生投递岗位后，如果企业隔天把月薪从 15k 改成 8k 甚至直接删帖，学生在投递记录里看到的数据以哪个为准？」

很多同学在开题时把招聘系统想成「BOSS直聘 + 大模型简历解析 + 协同过滤推荐」，在任务书里写满自然语言处理、分布式爬虫和即时通讯。实际情况是：第2周卡在本地 PDF 解析库 `poppler` 和 `pdfminer` 的环境依赖；第3周爬虫遭遇反爬验证码；第4周由于缺少企业审核状态流转，系统被导师指出存在虚假发布漏洞。

做毕业设计的首要原则是建立「闭环确定性」。把不可控的外部依赖剔除，将系统收敛为可控的单体工程。

---

### 真实死胡同与可行性评估

在动手写代码前，我们对比了原计划的虚高功能与可落地的工程实现：

| 模块 | 盲目堆砌的方案（死胡同） | 收敛后的工程基线（唯一推荐） | 答辩核验重点 |
| :--- | :--- | :--- | :--- |
| **岗位来源** | 编写 Scrapy 爬虫抓取外部招聘网 | 企业注册后后台录入，经管理员审核发布 | 岗位发布与审核的状态流转逻辑 |
| **简历处理** | 上传 PDF/Word 并做 OCR 字段提取 | 求职者在线填写结构化表单（字段入库） | 表单校验、必填项约束与持久化 |
| **投递链路** | 仅存 `job_id` 与 `user_id` 外键 | 投递时生成岗位与简历的只读快照 | 岗位信息变更后的历史单据一致性 |
| **岗位推荐** | 协同过滤算法或调用大模型 API | 城市 + 职位类别 + 薪资区间的组合过滤 | SQL 联合索引查询效率与边界值处理 |

**意外的技术反例**：投递记录绝不能简单依赖外键关联。如果直接设计为 `SELECT * FROM job WHERE id = application.job_id`，一旦企业 HR 修改岗位名称、薪资或物理删除岗位，求职者查看历史投递时就会报空指针或数据失真。投递动作本质上是一份不可变合同，必须包含快照机制。

---

### 模块拆分与 5 个核心写接口预算

整个系统的核心链路仅需覆盖三个角色（求职者、企业HR、管理员）。为了保证两周内能完成联调，严格约束写接口数量：

1. `POST /api/v1/jobs`：企业提交新岗位（初始状态：待审核）。
2. `POST /api/v1/jobs/{id}/audit`：管理员审批岗位（流转为：已发布/已驳回）。
3. `POST /api/v1/resumes`：求职者保存结构化在线简历。
4. `POST /api/v1/applications`：求职者投递岗位（核心：冻结快照，写入状态机初始态）。
5. `POST /api/v1/applications/{id}/status`：企业推进候选人状态（待查看 → 已查阅 → 约面试 → 不合适）。

其余业务全由标准只读列表（分页、筛选）支撑，不需要引入消息队列或搜索引擎。

---

### 最小表结构设计（MySQL）

落实上述闭环，仅需两张核心实体表（省略通用用户表）。

```sql
-- 岗位表：包含状态流转控制
CREATE TABLE `job_post` (
  `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
  `company_id` BIGINT NOT NULL COMMENT '发布企业ID',
  `title` VARCHAR(64) NOT NULL COMMENT '岗位名称',
  `category` VARCHAR(32) NOT NULL COMMENT '职位类别',
  `salary_min` INT NOT NULL COMMENT '最低月薪(千)',
  `salary_max` INT NOT NULL COMMENT '最高月薪(千)',
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0-待审核 1-已发布 2-已下架 3-驳回',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_cat_status` (`category`, `status`),
  INDEX `idx_company` (`company_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 投递记录表：承载投递时刻的不可变快照
CREATE TABLE `job_application` (
  `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
  `job_id` BIGINT NOT NULL COMMENT '关联岗位ID',
  `student_id` BIGINT NOT NULL COMMENT '求职者用户ID',
  `job_snapshot` JSON NOT NULL COMMENT '投递时岗位核心数据快照',
  `resume_snapshot` JSON NOT NULL COMMENT '投递时简历数据快照',
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0-已投递 1-已查阅 2-通知面试 3-不合适',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_job_student` (`job_id`, `student_id`),
  INDEX `idx_student` (`student_id`),
  INDEX `idx_job` (`job_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

### 核心用例伪代码：求职者投递控制

该用例必须保证幂等、状态校验与快照落库的原子性：

```pseudo
FUNCTION apply_job(student_id, job_id):
    // 1. 状态前置检查
    job = query_job_by_id(job_id)
    IF job IS NULL OR job.status != 1 THEN
        RETURN error("岗位不存在或未在招聘中")
    END IF

    resume = query_resume_by_student(student_id)
    IF resume IS NULL OR resume.is_complete == false THEN
        RETURN error("请先完善在线简历")
    END IF

    // 2. 防重复投递校验
    existing = query_application(job_id, student_id)
    IF existing IS NOT NULL THEN
        RETURN error("您已投递过该岗位，请勿重复操作")
    END IF

    // 3. 构造不可变快照
    job_snap = freeze_json(job.title, job.salary_min, job.salary_max, job.company_name)
    resume_snap = freeze_json(resume.name, resume.education, resume.skills_text)

    // 4. 落库并捕获唯一索引冲突
    TRY:
        insert_application(job_id, student_id, job_snap, resume_snap, status=0)
        RETURN success("投递成功")
    CATCH UniqueConstraintViolation:
        RETURN error("并发投递冲突，请稍后刷新重试")
END FUNCTION
```

---

### 关键实现草稿（Python Flask 示意）

以下代码仅为核心业务逻辑对照草稿，不可直接用于生产，供实现业务层时参考状态判断与事务收敛。

```python
# services/job_service.py (代码示意草稿，约 35 行)
from datetime import datetime
import json
from models import db, JobPost, JobApplication, OnlineResume

class JobService:
    @staticmethod
    def submit_application(student_id: int, job_id: int):
        # 1. 验证岗位是否处于可投状态（已通过审核且未下架）
        job = JobPost.query.filter_by(id=job_id, status=1).first()
        if not job:
            return False, "岗位不存在或未开放投递"
        
        # 2. 获取求职者当前有效在线简历
        resume = OnlineResume.query.filter_by(user_id=student_id).first()
        if not resume or not resume.is_complete:
            return False, "在线简历未完善"
            
        # 3. 封装只读快照数据
        job_snap = json.dumps({"title": job.title, "salary": f"{job.salary_min}-{job.salary_max}k"})
        resume_snap = json.dumps({"name": resume.real_name, "contact": resume.phone, "detail": resume.content})
        
        # 4. 创建投递记录
        app = JobApplication(
            job_id=job.id,
            student_id=student_id,
            job_snapshot=job_snap,
            resume_snapshot=resume_snap,
            status=0,
            created_at=datetime.utcnow()
        )
        try:
            db.session.add(app)
            db.session.commit()
            return True, "投递成功"
        except Exception:
            db.session.rollback()
            return False, "已投递过该岗位，请勿重复操作"
```

---

### 技术选型推荐与切换条件

* **唯一推荐基准**：Python 3.10 + Flask 2.x + MySQL 8.0 + Vue 3（单页应用）。
  * 理由：全系统无高并发写入，Flask 相比 Django 更轻量，不附带多余的管理后台配置包袱；状态机直接用 MySQL 行锁和唯一索引兜底，排障路径最短。
* **何时才允许切换/升级**：
  1. 只有当导师明确要求演示「几十万量级岗位全文分词检索」，且学院服务器能分配 4G 以上空闲内存时，才考虑引入 Elasticsearch；否则 MySQL 8.0 的内置全文索引或联合索引完全足够支撑。
  2. 只有当要求投递成功后发送真实短信/邮件通知时，才引入 Redis + Celery 异步任务；否则所有流转操作全部同步处理。

### 今晚的最小执行步骤

1. 打开开题任务书，将「网络爬虫采集」和「自然语言处理简历提取」两行描述删掉，修改为「企业认证审核工作流」与「投递不可变快照机制」。
2. 在本地 MySQL 数据库中运行上面的建表 DDL，确认 `uk_job_student` 唯一索引有效。
3. 先写测试用例验证投递接口：连续发起两次相同投递请求，确认第二次请求命中唯一约束并返回拦截提示。

---

## 相关资料

同类问题里，最常见的不是「不会写某段代码」，而是边界没钉死。下面两张图是公开资料里的结构示意，适合贴在笔记本旁边对照（非代写、不包过）。

![毕设验收清单封面](../../assets/cover-checklist.jpg)

*上线/演示前用清单自检，少返工*

![Java 方向项目封面](../../assets/cover-java.jpg)

*Java / Spring Boot 方向可参考站点案例结构*

完整案例与选题自检：[www.bysj.site](https://www.bysj.site/) · [选题自检](https://www.bysj.site/free-topic-check.html)

仓库里只放设计草稿和伪代码，完整实现请对照站点案例自己完成。

