# 招聘信息发布系统

[![www.bysj.site](../../assets/og-cover.png)](https://www.bysj.site/)

> 对照草稿，不是可运行工程。完整案例见 [www.bysj.site](https://www.bysj.site/)

> 技术栈：Python Flask + Vue + MySQL
> 很多招聘毕设开题就堆大模型简历初筛与爬虫抓取，中期卡在显存爆满与字段解析错位。本文将系统收窄至结构化简历与投递状态单向流转，给出4张核心表、状态原子流转代码与接口预算，保障答辩演示稳定跑通。

## 本目录文件

- `招聘信息发布_flow.pseudo`
- `招聘信息发布_schema.sql`
- `update_application_status.py`
- `shots/20260909-202222_做招聘发布系统先把LLM匹配移出主链路_4张表与状态驱动的Flask最小实现_ui_site.jpg`
- `shots/20260909-202222_做招聘发布系统先把LLM匹配移出主链路_4张表与状态驱动的Flask最小实现_ui_3.jpg`
- `shots/20260909-202222_做招聘发布系统先把LLM匹配移出主链路_4张表与状态驱动的Flask最小实现_ui_2.jpg`
- `shots/20260909-202222_做招聘发布系统先把LLM匹配移出主链路_4张表与状态驱动的Flask最小实现_ui_1.jpg`
- `shots/20260909-202222_做招聘发布系统先把LLM匹配移出主链路_4张表与状态驱动的Flask最小实现_3.jpg`
- `shots/20260909-202222_做招聘发布系统先把LLM匹配移出主链路_4张表与状态驱动的Flask最小实现_2.jpg`
- `shots/20260909-202222_做招聘发布系统先把LLM匹配移出主链路_4张表与状态驱动的Flask最小实现_1.jpg`

## 说明

- 伪代码只描述主路径，表结构/状态机请自己落库实现。
- 禁止把本目录当作业直接提交。
- 选题边界与可演示清单： [www.bysj.site](https://www.bysj.site/)

### 站点封面（仓库本地 assets）

![选题结构](../../assets/cover-topic.jpg)

![Java / Spring Boot](../../assets/cover-java.jpg)

## 原文摘要

> 很多招聘毕设开题就堆大模型简历初筛与爬虫抓取，中期卡在显存爆满与字段解析错位。本文将系统收窄至结构化简历与投递状态单向流转，给出4张核心表、状态原子流转代码与接口预算，保障答辩演示稳定跑通。
> 示例系统：招聘信息发布系统
> tags: Python, Flask, Vue, 毕业设计, MySQL

### 第5周中期检查：卡在PDF解析与本地模型OOM

上周在实验室帮一个同学看招聘系统的中期演示。原本他打算在答辩席上展示一个亮点：求职者上传一段由真实PDF转换的简历，后端走开源大模型或抽取组件（PyMuPDF + 本地部署的MiniLM向量模型），自动匹配数据库里的招聘岗位（JD），并给出相符百分比。

![图：毕设无忧网站入口（www.bysj.site）](./shots/20260909-202222_做招聘发布系统先把LLM匹配移出主链路_4张表与状态驱动的Flask最小实现_ui_site.jpg)

*图：毕设无忧网站入口（www.bysj.site）*


![图：招聘信息发布系统详情办理页](./shots/20260909-202222_做招聘发布系统先把LLM匹配移出主链路_4张表与状态驱动的Flask最小实现_ui_3.jpg)

*图：招聘信息发布系统详情办理页*


![图：招聘信息发布系统业务列表页](./shots/20260909-202222_做招聘发布系统先把LLM匹配移出主链路_4张表与状态驱动的Flask最小实现_ui_2.jpg)

*图：招聘信息发布系统业务列表页*


![图：招聘信息发布系统工作台演示](./shots/20260909-202222_做招聘发布系统先把LLM匹配移出主链路_4张表与状态驱动的Flask最小实现_ui_1.jpg)

*图：招聘信息发布系统工作台演示*


![图：系统架构示意 · 核心业务最小数据模型（展示支撑招聘系统完整业务流转的最简表结构对象）](./shots/20260909-202222_做招聘发布系统先把LLM匹配移出主链路_4张表与状态驱动的Flask最小实现_3.jpg)

*图：系统架构示意 · 核心业务最小数据模型（展示支撑招聘系统完整业务流转的最简表结构对象）*


![图：落地路径示意 · 推荐的确定性流转链路（展示结构化表单与状态机驱动的低风险答辩方案）](./shots/20260909-202222_做招聘发布系统先把LLM匹配移出主链路_4张表与状态驱动的Flask最小实现_2.jpg)

*图：落地路径示意 · 推荐的确定性流转链路（展示结构化表单与状态机驱动的低风险答辩方案）*


![图：数据流示意 · 脆弱的非结构化解析主链路（展示模型抽取放入主干导致的显存溢出与反爬卡死）](./shots/20260909-202222_做招聘发布系统先把LLM匹配移出主链路_4张表与状态驱动的Flask最小实现_1.jpg)

*图：数据流示意 · 脆弱的非结构化解析主链路（展示模型抽取放入主干导致的显存溢出与反爬卡死）*


在答辩前两天的联调现场，系统直接崩在控制台：

```text
torch.cuda.OutOfMemoryError: CUDA out of memory. Tried to allocate 256.00 MiB (GPU 0; 4.00 GiB total capacity; 3.61 GiB already allocated)
[2026-03-22 14:32:01,892] ERROR in app: Exception on /api/resume/parse [POST]
fitz.FileDataError: cannot open broken document: .../temp_resume.pdf
```

问题接踵而至：
1. 学生笔记本显存只有 4GB，Flask 单进程启动后只要模型加载进显存，再开浏览器和 Vue 开发服务，系统就开始频繁把显存倒腾到虚拟内存，一次请求响应耗时 23 秒。
2. 找同班同学借来测试的 6 份简历里，有 2 份是用 Canva 导出的纯图片型 PDF，没有文本图层，提取出来的文本全为空串。
3. 他为了凑岗位数据，写了一个 Selenium 脚本爬取公开招聘网站，结果跑了不到 30 次请求就被目标站点封了本地 IP，数据库空空如也。

答辩评审老师翻了任务书，直接反问了三个问题：“如果你答辩断网，你调云端 API 还是本地跑？”“如果简历排版换成双栏，你的正则与提示词还能抽出期望薪资吗？”“一个招聘系统，核心到底是有序处理求职者的应聘流程，还是做一个不可控的文本抽取 Demo？”

这就是典型的选题边界失控。一上来就堆大模型初筛、自动化爬虫与全文检索，把毕业设计变成了一场环境依赖的赌博。

---

### 真实死胡同：为什么不要在招聘系统里硬塞非结构化解析

很多同学在写开题报告时，很容易把工业界的“智能招聘中台”直接当成自己八周内要完成的课设目标。

下表是招聘发布系统在选题边界上的典型反差：

| 功能维度 | 容易翻车的膨胀方案 | 推荐的落地边界 | 答辩时老师的考核点 |
| :--- | :--- | :--- | :--- |
| **岗位数据来源** | Selenium/Playwright 爬虫定时抓取第三方站点 | 管理员/企业端后台手动录入 + 初始化 SQL 脚本 | 数据表字段设计合理性、字典约束 |
| **简历处理形式** | 接收无限制 PDF，用 OCR/LLM 提取结构化数据 | 在前端提供标准化表单，直接录入字段存库 | 数据库字段规范、表单校验与防空机制 |
| **岗位匹配机制** | 文本向量化计算余弦相似度（LangChain+FAISS） | 显式维度过滤（期望城市 + 岗位类别 + 薪资区间） | SQL 索引命中、多条件动态拼接查询 |
| **流程推进方式** | WebSocket 实时双向聊天 + 视频面在线打卡 | 投递记录状态机单向流转（已投递/初筛/面试/录用） | 业务状态严密性、并发排他更新与幂等校验 |

在这个死胡同里，最先耗尽时间的永远不是业务代码，而是去调模型提示词的输出格式、处理无休止的 PDF 编码错误，以及修复爬虫挂掉后的空指针异常。

**一个判断：在本科毕业设计级别，招聘系统的核心资产是“岗位-简历-投递状态”的确定性流转，而不是不确定性极高的自然语言处理。** 除非课题就是“面向招聘文本的命名实体识别与匹配”，否则把非结构化抽取做进主干系统，只会稀释你在工程结构上的表现。

---

### 4张核心表：支撑完整业务流的最小数据模型

砍掉向量数据库和日志堆叠后，招聘系统的实体边界其实非常明确：企业（含招聘者）、求职者（简历）、岗位、投递记录。其余的收藏夹、评价、浏览历史，都属于有时间再补的次要装饰。

在 MySQL 8.0 下，满足答辩要求的最小表结构仅需以下 4 张：

```sql
-- 1. 用户基础表（简化角色区分：1=求职者, 2=HR, 9=管理员）
CREATE TABLE `sys_user` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(64) NOT NULL UNIQUE,
  `password_hash` VARCHAR(128) NOT NULL,
  `role_type` TINYINT NOT NULL DEFAULT 1,
  `real_name` VARCHAR(32) NOT NULL,
  `phone` VARCHAR(20) NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. 结构化简历表（一人一份基础简历，避免复杂的版本分叉）
CREATE TABLE `resume` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `user_id` BIGINT NOT NULL UNIQUE,
  `job_title` VARCHAR(64) NOT NULL COMMENT '期望职位',
  `expected_salary_min` INT NOT NULL DEFAULT 0 COMMENT '单位：千元',
  `expected_salary_max` INT NOT NULL DEFAULT 0,
  `city` VARCHAR(32) NOT NULL,
  `education` VARCHAR(16) NOT NULL COMMENT '本科/硕士/大专',
  `skills_summary` TEXT COMMENT '掌握技能简述',
  `experience` TEXT COMMENT '项目/工作经历',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_resume_city_title` (`city`, `job_title`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. 岗位发布表
CREATE TABLE `job_position` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `publisher_id` BIGINT NOT NULL COMMENT '关联sys_user.id',
  `title` VARCHAR(64) NOT NULL,
  `company_name` VARCHAR(64) NOT NULL,
  `city` VARCHAR(32) NOT NULL,
  `salary_min` INT NOT NULL DEFAULT 0,
  `salary_max` INT NOT NULL DEFAULT 0,
  `education_require` VARCHAR(16) NOT NULL,
  `description` TEXT NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '1:招聘中, 0:已关闭',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_job_query` (`status`, `city`, `salary_min`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. 投递流转记录表（核心状态机）
CREATE TABLE `job_application` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `job_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL COMMENT '求职者ID',
  `resume_snapshot` JSON NOT NULL COMMENT '投递时的简历快照',
  `status` TINYINT NOT NULL DEFAULT 10 COMMENT '10:已投递, 20:初筛通过, 30:面试中, 40:已录用, 90:已淘汰',
  `reject_reason` VARCHAR(255) DEFAULT '',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_job_user` (`job_id`, `user_id`),
  INDEX `idx_hr_job` (`job_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

注意这套表设计的两个细节：
* `job_application` 中设置了 `(job_id, user_id)` 的唯一索引，在数据库层面封死同一个求职者对同一岗位连点多次造成的重复数据。
* 增加了 `resume_snapshot`（简历快照 JSON 字段）。求职者在投递后如果修改了自己的基础简历，企业端看到的历史投递必须是投递那一刻的内容，不能跟着动态改变。这在答辩时是极高频的提问点。

---

### 核心逻辑：投递流水线的单向原子流转

整个系统的代码重心，应该放在状态机的有序演进上，而不是花哨的动画或复杂算法。

定义合法的状态跳转路径：
`10 (已投递) -> 20 (初筛通过) -> 30 (面试中) -> 40 (已录用)`
在任意阶段，企业 HR 都可以将其推向 `90 (已淘汰)`。但状态不可逆，不能从 `90` 逆跳回 `20`，也不能从 `10` 直接跳到 `40`。

以下是基于 Python Flask + SQLAlchemy 的状态流转实现（可直接运行并嵌入你的后端）：

```python
# app_service.py - 投递流转核心接口示意
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://root:123456@127.0.0.1:3306/job_db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# 状态常量定义
STATUS_SUBMITTED = 10
STATUS_PASSED_SCREEN = 20
STATUS_INTERVIEWING = 30
STATUS_OFFERED = 40
STATUS_REJECTED = 90

# 合法的状态跃迁映射表
VALID_TRANSITIONS = {
    STATUS_SUBMITTED: [STATUS_PASSED_SCREEN, STATUS_REJECTED],
    STATUS_PASSED_SCREEN: [STATUS_INTERVIEWING, STATUS_REJECTED],
    STATUS_INTERVIEWING: [STATUS_OFFERED, STATUS_REJECTED],
}

@app.route('/api/application/<int:app_id>/status', methods=['PUT'])
def update_application_status(app_id):
    data = request.get_json() or {}
    target_status = data.get('status')
    reject_reason = data.get('reject_reason', '').strip()

    # 1. 基础参数校验
    if not target_status or not isinstance(target_status, int):
        return jsonify({"code": 400, "msg": "无效的目标状态"}), 400

    # 2. 查询当前单据并加上行级排他锁，防止并发审批
    record = db.session.query(JobApplication).filter_by(id=app_id).with_for_update().first()
    if not record:
        return jsonify({"code": 404, "msg": "投递记录不存在"}), 404

    current_status = record.status
    allowed_next_states = VALID_TRANSITIONS.get(current_status, [])

    # 3. 校验跃迁是否合法
    if target_status not in allowed_next_states:
        return jsonify({
            "code": 422,
            "msg": f"状态流转非法：不可从 {current_status} 变更到 {target_status}"
        }), 422

    # 4. 淘汰必须填写理由
    if target_status == STATUS_REJECTED and not reject_reason:
        return jsonify({"code": 422, "msg": "淘汰操作必须附带原因说明"}), 422

    # 5. 执行原子流转
    record.status = target_status
    if target_status == STATUS_REJECTED:
        record.reject_reason = reject_reason
    
    record.updated_at = datetime.now()
    db.session.commit()

    return jsonify({"code": 200, "msg": "状态更新成功", "current_status": target_status})
```

这段代码在答辩时有很高的信息密度：你用了 `with_for_update()` 保证同一张单据不会被两个 HR 同时审批造成数据冲突；你用字典 `VALID_TRANSITIONS` 显式声明了业务规则，而不是在代码里写一堆混乱的 `if-else`。

---

### 接口与前端落地预算：按角色分配页面

答辩时最怕出现“一个页面塞满无用输入框，核心业务却要跳三四个界面”的情况。基于 Vue 3 + Element Plus，一个招聘系统的页面预算控制在 5 个核心页面完全够用：

1. **岗位广场页（求职者端）**：
   * 顶部：城市选择下拉框、薪资区间滑块、岗位类别单选。
   * 中间：卡片流展示岗位名、公司、薪资、发布时间。
   * 动作：点击卡片弹窗展示岗位详情，底部提供一个大按钮「一键投递」。
2. **在线简历编辑页（求职者端）**：
   * 纯结构化表单，包括基本信息、求职意向、技能标签（用 `el-tag` 输入）。
   * 提供「预览投递视图」，直接展示生成的 JSON 快照排版。
3. **我的投递看板（求职者端）**：
   * 按照 `已投递 / 待面试 / 已录用 / 已拒绝` 4 个标签页进行列表划分，清晰看清进度。
4. **企业岗位管理与收件箱（HR端）**：
   * 发布新岗位表单。
   * 投递简历列表：支持按投递状态筛选，表格右侧操作列提供「推进到下一轮」「淘汰」两个动作按钮。
5. **数据看板（管理员端）**：
   * 简单的指标统计（当日新增岗位数、投递总数、流转率转化漏斗）。

整个前后端交互由 6 个标准化 REST 接口支撑：
* `GET /api/jobs`（多条件动态过滤岗位）
* `POST /api/jobs`（发布新岗位）
* `GET /api/resume/my` 与 `PUT /api/resume/my`（读取与更新简历）
* `POST /api/application/apply`（执行投递，生成快照）
* `GET /api/application/list`（按角色获取投递清单）
* `PUT /api/application/<id>/status`（驱动状态跃迁）

只要把这 6 个接口调通，无论是在本地电脑上跑，还是导师临时抽查，系统都能在 3 分钟内完整演示“从岗位发布 -> 求职者投递 -> HR在后台审批推进 -> 求职者端状态变更”的完整过程。

---

### 方案选型结论与今晚的动作

在招聘信息发布系统的选型上，给出唯一推荐组合：**Python Flask + SQLAlchemy + MySQL 8.0 + Vue 3**。

什么时候你才可以往里面加 Redis、Celery 或者大模型？
只有在且仅在一种情况下：**你的数据库里真实灌入了 10 万条以上的公开数据集，且单表分页查询（OFFSET 10000）已经出现超过 800ms 的明显延迟，或者导师课题直接要求做特定领域 NLP 算法对比。** 如果整个系统只有几十条自编的测试数据，强行引入消息队列异步发邮件或加本地 Embedding，不仅答辩现场极易翻车，还会被评委一眼看穿是空壳拼凑。

**今晚可以立刻执行的动作：**
1. 把任务书和开题报告里所有带“智能解析 PDF”、“自动爬取全网数据”、“深度学习匹配”的句子全部删掉，改成“基于结构化维度的岗位检索与投递流转系统”。
2. 打开数据库连接工具，执行上面的 4 张基础表建表 SQL，先用手工方式在 `sys_user` 和 `job_position` 里各自灌入 5 条真实岗位数据。
3. 把投递状态机代码粘入后端项目，用 Postman 跑通一次合法跃迁与一次非法越级跃迁（如直接从 10 跳到 40），拿到 422 报错，确认后端校验生效。

