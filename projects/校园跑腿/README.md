# 校园跑腿系统

[![www.bysj.site](../../assets/og-cover.png)](https://www.bysj.site/)

> 对照草稿，不是可运行工程。完整案例见 [www.bysj.site](https://www.bysj.site/)

> 技术栈：Django + Vue + PostgreSQL
> 许多校园跑腿毕设卡在校内路网缺失与接单并发冲突。本文用楼宇网格字典剔除高精地图路径计算，配合行级版本锁解决重复接单，给出最小表结构与接单草稿，守住单人开发边界。

## 本目录文件

- `校园跑腿_schema.sql`
- `校园跑腿_schema_2.sql`
- `校园跑腿_flow.pseudo`
- `TaskService.py`

## 说明

- 伪代码只描述主路径，表结构/状态机请自己落库实现。
- 禁止把本目录当作业直接提交。
- 选题边界与可演示清单： [www.bysj.site](https://www.bysj.site/)

### 站点封面（仓库本地 assets）

![选题结构](../../assets/cover-topic.jpg)

![Java / Spring Boot](../../assets/cover-java.jpg)

## 原文摘要

> 许多校园跑腿毕设卡在校内路网缺失与接单并发冲突。本文用楼宇网格字典剔除高精地图路径计算，配合行级版本锁解决重复接单，给出最小表结构与接单草稿，守住单人开发边界。
> 示例系统：校园跑腿系统
> tags: 毕业设计, 系统设计, Django, PostgreSQL, 校园跑腿

第三周系统联调现场，两台笔记本在局域网下跑跑腿订单。
外接的高德地图 Web 路径规划接口返回了 `INVALID_USER_KEY` 和空路径——校内宿舍区到第二食堂的小路在市政路网里根本不存在，页面直接白屏。
更尴尬的是，两边同时点击同一笔代取快递单，页面双双提示“接单成功”，数据库里订单的接单员字段被后写入的请求直接覆盖，前面的骑手被无声踢掉。

很多跑腿题一开题就写“基于遗传算法的最优路径规划”和“高精度 GPS 实时轨迹追踪”。
实际上，校内道路没有车行拓扑数据，市面地图 API 到了围墙内只会连直线；而在没有并发锁的情况下，连基础的抢单互斥都跑不通。

---

## 真实踩坑记录：校内路径计算的死胡同

为了在答辩演示里展示“高级感”，前期尝试自建校园路网图：

1. 用开源地图工具手动标定了校内 42 个路口节点和 67 条内部道路。
2. 在后端写了 Dijkstra 最短路径算法，试图按米计算配送费并给骑手规划路线。
3. 卡点出现在第 12 天：校内施工封闭了一条岔路，算法算出的路径直接穿过围墙；同时学生宿舍楼禁止外卖员上楼，所谓的“最后 100 米路线”根本无意义。
4. 结果是花了整整两周调试路网图，主业务里的“骑手取消违约金”、“取件码校验”一行没写。

果断放弃所谓的最优路径规划，直接砍掉全部路径计算代码。校园配送的本质是“楼宇组团”之间的接力，而不是市政公路上的货车导航。计价和分流只需要静态的楼宇分区网格。

---

## 可行性评估：动态测距与楼宇拓扑对照

做系统设计前，先把需求分为两套方案对照评估：

| 评估项 | 动态高精方案（易烂尾） | 楼宇网格方案（推荐） |
| :--- | :--- | :--- |
| **底层依赖** | 商业地图 Web API / 自建路网 GIS | 本地 PostgreSQL 楼宇拓扑字典 |
| **网络要求** | 强依赖外网连接与可用 Key | 完全离线本地运行，答辩断网不崩 |
| **计价模型** | 经纬度折线距离加权 | 分区基础费 + 跨区跨楼阶梯价 |
| **并发风险** | 接口耗时 800ms，放大抢单脏读 | 本地数据库单次原子更新，耗时 < 15ms |
| **代码复杂度** | 引入 GIS 库、坐标系转换、折线渲染 | 普通主外键与枚举状态流转 |

**唯一推荐选型：**
单体架构使用 **Django 4.2 + PostgreSQL 15 + Vue 3**。
不需要接入 Redis，也不要引入 Celery。状态流转与接单排他直接依赖 PostgreSQL 行级锁或版本号控制。

**切换到复杂方案的唯一条件：**
学校属于多校区超大园区（跨园区距离超 5 公里），且配送工具包含机动车辆需走市政道路。
只要配送范围在步行或电动车闭环校区内，坚决不上 GIS 计算引擎。

---

## 最小表结构设计

剔除所有经纬度坐标集合字段，把地理信息收敛为“分区编号 + 楼宇编号”。核心业务只保留两张关键表。

### 1. 楼宇拓扑表（campus_building）

```sql
CREATE TABLE campus_building (
    id SERIAL PRIMARY KEY,
    zone_code VARCHAR(16) NOT NULL,      -- 例如: DORM_NORTH (北区宿舍), CANTEEN (食堂区)
    building_name VARCHAR(64) NOT NULL,  -- 例如: 12号楼
    is_active BOOLEAN DEFAULT TRUE
);

-- 预置跨区计价权重示例：同一 zone 基础费 2 元，跨 zone 累加 1.5 元
```

### 2. 跑腿任务单表（errand_task）

核心在于使用 `status` 配合 `version` 实现排他控制，坚决不用无约束的直接 UPDATE。

```sql
CREATE TABLE errand_task (
    id BIGSERIAL PRIMARY KEY,
    task_no VARCHAR(32) UNIQUE NOT NULL,
    publisher_id BIGINT NOT NULL,
    runner_id BIGINT DEFAULT NULL,
    from_building_id INT REFERENCES campus_building(id),
    to_building_id INT REFERENCES campus_building(id),
    bounty_cents INT NOT NULL,            -- 赏金（单位：分，避免浮点数计算错误）
    verify_code VARCHAR(8) NOT NULL,      -- 交付核销码
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    version INT NOT NULL DEFAULT 0,       -- 乐观锁版本号
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_task_pool ON errand_task (status, from_building_id);
```

业务状态严格限定为单向图：`PENDING`（待接单） -> `ACCEPTED`（已接单） -> `ARRIVED`（已送达待核销） -> `FINISHED`（已完结）。
另外留一条分支：`PENDING` -> `CANCELLED`（已取消）。

---

## 核心用例：抢单原子互斥伪代码

在接单场景中，最容易出 bug 的是读写分离造成的“一单多人抢”。
必须把状态前置校验与版本号递增压进单条写操作。

```pseudo
FUNCTION accept_task(task_id, runner_id):
    // 1. 本地前置校验：接单人不能是发单人
    task = DB.query("SELECT publisher_id, status, version FROM errand_task WHERE id = ?", task_id)
    IF task IS NULL THEN RETURN ERROR("任务不存在")
    IF task.publisher_id == runner_id THEN RETURN ERROR("不能承接自己发布的订单")
    IF task.status != 'PENDING' THEN RETURN ERROR("手慢了，订单已被接取")

    // 2. 排他性更新（条件写）：利用单行写锁保证原子性
    affected_rows = DB.execute("""
        UPDATE errand_task 
        SET runner_id = :runner_id, 
            status = 'ACCEPTED', 
            version = version + 1 
        WHERE id = :task_id 
          AND status = 'PENDING' 
          AND version = :expected_version
    """, runner_id=runner_id, task_id=task_id, expected_version=task.version)

    // 3. 判定更新结果
    IF affected_rows == 0 THEN
        RETURN ERROR("并发冲突，接单失败")
    END IF

    RETURN SUCCESS("接单成功")
END FUNCTION
```

---

## 关键层实现草稿（Django Service 示范）

下面给出一份服务层草稿 `task_service.py`。注意这不是直接复制就能跑的完整工程，仅用于展示如何用 Django ORM 处理边界。

```python
# task_service.py (对照草稿，禁止直接当成全套工程)
from django.db import transaction
from django.core.exceptions import ValidationError
from .models import ErrandTask

class TaskService:
    @staticmethod
    def grab_task(task_id: int, runner_id: int) -> bool:
        """
        核心抢单逻辑：行级版本控制，防止超卖与重复认领
        """
        with transaction.atomic():
            # 使用 select_for_update 锁定当前行，阻止并发事务脏读
            try:
                task = ErrandTask.objects.select_for_update().get(id=task_id)
            except ErrandTask.DoesNotExist:
                raise ValidationError("订单不存在")

            if task.publisher_id == runner_id:
                raise ValidationError("无法承接自己发布的订单")

            if task.status != ErrandTask.Status.PENDING:
                raise ValidationError("该任务已被接单或已失效")

            # 状态更新
            task.runner_id = runner_id
            task.status = ErrandTask.Status.ACCEPTED
            task.version += 1
            task.save(update_fields=['runner_id', 'status', 'version'])
            return True

    @staticmethod
    def complete_delivery(task_id: int, runner_id: int, input_code: str) -> bool:
        """
        核销校验：仅持单骑手与正确验证码可核销
        """
        task = ErrandTask.objects.filter(id=task_id, runner_id=runner_id).first()
        if not task or task.status != ErrandTask.Status.ACCEPTED:
            raise ValidationError("无效的核销请求")

        if task.verify_code != input_code.strip():
            raise ValidationError("取件核销码错误")

        task.status = ErrandTask.Status.FINISHED
        task.save(update_fields=['status'])
        return True
```

---

## 测试基线：并发抢单验证步骤

在本地单机环境下，无需额外配置测试集群，按以下步骤即可检验并发控制是否有效：

1. **制造测试数据**：在本地数据库手动插入一条 `status='PENDING'`、`version=0` 的待接单记录。
2. **编写测试脚本**：用 Python 标准库 `concurrent.futures` 启动 20 个工作线程，向接单接口同时发送请求（携带不同的 `runner_id`）。
3. **验收合格标准**：
   - 控制台应有且仅有 1 个线程打印 `接单成功 (HTTP 200)`。
   - 其余 19 个线程捕获到业务异常并返回提示 `HTTP 400 (手慢了或并发冲突)`。
   - 检查数据库该记录，`runner_id` 必须为那个成功线程的值，`version` 严格等于 1。

如果在 20 并发下出现两条成功日志或数据库字段错乱，说明事务锁或条件更新失效，不要继续往下写前端界面。

---

## 今晚就能做的收敛动作

别再去申请第三方的地图开发者 Key，也别在开题报告里写“基于深度学习的送达时间预估”。

1. 打开任务书，把“校内路线导航与实时定位系统”改成“基于楼宇分区的任务流转系统”。
2. 清理掉工程里全部 GIS 相关的依赖包，在数据库里把起点和终点改成具体的楼宇外键。
3. 先把上面的接单 Service 和核销码逻辑写出来，用命令行开两个终端并发测试一次接单。

跑通这套确定性的单表状态控制，毕设的主干就已经立住了。

---

## 实践备忘

技术细节到这里可以告一段落。若你还卡在**题目能不能做完、栈怎么选、演示怎么兜底**，可以把公开的选题自检与案例结构当参考——自己写代码、自己改论文，资料只作对照。

![计算机毕设选题思路封面](../../assets/cover-topic.jpg)

*选题卡住时，先把题目边界和可演示路径想清楚*

![毕设项目推进指南封面](../../assets/cover-guide.jpg)

*从环境、模块拆分到答辩叙事，按清单推进更稳*

完整案例与选题自检：[www.bysj.site](https://www.bysj.site/) · [选题自检](https://www.bysj.site/free-topic-check.html)

仓库里只放设计草稿和伪代码，完整实现请对照站点案例自己完成。

