# 仓储出入库系统

[![www.bysj.site](../../assets/og-cover.png)](https://www.bysj.site/)

> 对照草稿，不是可运行工程。完整案例见 [www.bysj.site](https://www.bysj.site/)

> 技术栈：Python Flask + Vue + MySQL
> 仓储毕设常因堆砌RFID硬件联动与立体库装箱算法导致单线程阻塞或表单击穿。本文收敛至货位二段码与单库行级锁，给出4张核心表与出入库防超卖接口，保障演示环境稳定流转。

## 本目录文件

- `仓储出入库_schema.sql`
- `仓储出入库_schema_2.sql`
- `仓储出入库_schema_3.sql`
- `confirm_outbound.py`

## 说明

- 伪代码只描述主路径，表结构/状态机请自己落库实现。
- 禁止把本目录当作业直接提交。
- 选题边界与可演示清单： [www.bysj.site](https://www.bysj.site/)

### 站点封面（仓库本地 assets）

![选题结构](../../assets/cover-topic.jpg)

![Java / Spring Boot](../../assets/cover-java.jpg)

## 原文摘要

> 仓储毕设常因堆砌RFID硬件联动与立体库装箱算法导致单线程阻塞或表单击穿。本文收敛至货位二段码与单库行级锁，给出4张核心表与出入库防超卖接口，保障演示环境稳定流转。
> 示例系统：仓储出入库系统
> tags: Python, Flask, Vue, 毕业设计, MySQL

## 第4周联调现场：扫码枪连击打穿库存

![图：仓储出入库系统工作台演示](/api/blog-tasks/media/20260908-102058_仓储出入库系统拿掉3D装箱与RFID_货位二段码与行锁核销的Flask实现_ui_1.jpg)

*图：仓储出入库系统工作台演示*


![图：系统架构示意 · 仓储演示核心数据表关联（梳理物料货位与出入库单据间的外键引用关系）](/api/blog-tasks/media/20260908-102058_仓储出入库系统拿掉3D装箱与RFID_货位二段码与行锁核销的Flask实现_1.jpg)

*图：系统架构示意 · 仓储演示核心数据表关联（梳理物料货位与出入库单据间的外键引用关系）*


开题答辩时不少同学把系统写成「基于物联网与智能算法的现代立体仓储系统」，任务书里赫然列着「RFID射频识别标签直读」和「基于遗传算法的货物三维立体装箱优化」。

到了第4周本地联调，借来的USB外接扫码枪插上笔记本，在Vue编写的入库表单里一扫，扫码枪模拟键盘高速输入一串条形码并附带回车事件。前端没有做防抖，同时触发了两次提交请求。后端Flask直接走无事务保护的更新，物料库存直接跳变，第二笔出库在多线程并发测试下一并放行，MySQL里的可用库存出现了 `-3` 的负数。

另一个卡点在立体装箱。为了让页面看起来像立体仓库，有些同学试图在后端用Python贪心启发式算法计算每个纸箱在货架上的空间三维坐标 $(x, y, z)$。在本地单核2G虚拟机的测试环境下，物料数量累加到50件时，装箱碰撞检测递归直接让Flask主线程阻塞卡顿超过12秒，前端页面直接爆出 `504 Gateway Timeout`。

硬件通信调不通，算法算力撑不住。做毕设需要先给仓储系统做边界裁剪。

## 真实WMS与毕设系统的边界对照

![图：仓储出入库系统业务列表页](/api/blog-tasks/media/20260908-102058_仓储出入库系统拿掉3D装箱与RFID_货位二段码与行锁核销的Flask实现_ui_2.jpg)

*图：仓储出入库系统业务列表页*


![图：请求调用链 · 行级排他锁出库核销链路（展示出库核销中防超卖的数据库行锁抢占与扣减顺序）](/api/blog-tasks/media/20260908-102058_仓储出入库系统拿掉3D装箱与RFID_货位二段码与行锁核销的Flask实现_2.jpg)

*图：请求调用链 · 行级排他锁出库核销链路（展示出库核销中防超卖的数据库行锁抢占与扣减顺序）*


真实工业场景中的WMS（仓储管理系统）依赖传送带PLC、叉车调度平板、RFID天线以及多货位动态移库机制。作为单人完成的毕业设计，核心考核点不是硬件驱动能力，而是**单据状态机的流转、货位映射的准确性以及库存扣减的数据一致性**。

必须先确认哪些模块该砍，哪些逻辑该保：

| 功能模块 | 工业级WMS实现 | 毕设可行性方案 | 舍弃原因与风险 |
| :--- | :--- | :--- | :--- |
| 物料识别 | RFID通道门批量感应 / 工业扫码枪串口协议 | 前端表单直接检索物料编号 / 虚拟扫码输入框 | 串口通信驱动跨平台报错多，答辩现场无法还原物理硬件 |
| 货位管理 | 三维立体坐标 / 自动穿梭车路径规划 | 静态二段码（库区编号-货架层号）字典映射 | 3D空间碰撞算法在Python无显卡加速下极易超时卡死 |
| 出库流转 | 波次拣选 / 分拣线动态拆包 / 路径最短计算 | 人工创建出库单 $\rightarrow$ 审核 $\rightarrow$ 扣减库存两步流转 | 算法解释成本过高，无法自圆其说且容易被导师追问边界条件 |
| 库存扣减 | 分布式锁 / 消息队列异步削峰 | MySQL单事务 + `FOR UPDATE` 行级排他锁 | 单机演示根本无高并发，引入中间件徒增联调与汇报故障率 |

做毕设仓储系统不需要碰动态移库与按批次自动拆零，收敛成「整单核销」就足够支撑业务完整度。但这项判断在一种情况下需主动收回：如果任务书题目明确带有「医药冷链」或「食品保质期预警」，则必须在物料表保留 `batch_no`（批次号）与 `expire_date`（过期时间）字段，实现严格的先进先出（FIFO）查询。

## 支撑演示的4张核心表结构

![图：仓储出入库系统详情办理页](/api/blog-tasks/media/20260908-102058_仓储出入库系统拿掉3D装箱与RFID_货位二段码与行锁核销的Flask实现_ui_3.jpg)

*图：仓储出入库系统详情办理页*


![图：落地路径示意 · 货位二段码轻量映射流（展示砍掉3D装箱后二段码对物理仓位的映射路径）](/api/blog-tasks/media/20260908-102058_仓储出入库系统拿掉3D装箱与RFID_货位二段码与行锁核销的Flask实现_3.jpg)

*图：落地路径示意 · 货位二段码轻量映射流（展示砍掉3D装箱后二段码对物理仓位的映射路径）*


系统只需聚焦四个实体：物料基础信息、货位字典、入库单据、出库单据。很多同学把库存单独做成一张表，导致每次出入库都要在「单据表、明细表、库存表」三者之间做极其复杂的同步，极易出现明细加总与库存总数对不齐的问题。

推荐将库存总量直接收敛在物料基础表中，辅以货位关联字段，最小核心结构如下。

### 1. 物料基础表（wms_material）
记录物料静态属性与即时库存。
```sql
CREATE TABLE `wms_material` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `material_code` VARCHAR(32) NOT NULL UNIQUE COMMENT '物料编码',
  `name` VARCHAR(64) NOT NULL COMMENT '物料名称',
  `spec` VARCHAR(64) COMMENT '规格型号',
  `unit` VARCHAR(16) DEFAULT '件' COMMENT '计量单位',
  `stock_qty` INT NOT NULL DEFAULT 0 COMMENT '物理库存总量',
  `frozen_qty` INT NOT NULL DEFAULT 0 COMMENT '出库冻结库存',
  `location_id` INT NOT NULL COMMENT '默认存放货位ID',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```
可用库存永远通过动态计算得出：`available_qty = stock_qty - frozen_qty`，严禁在数据库里单独建一个可被手动篡改的 `available_stock` 字段。

### 2. 货位字典表（wms_location）
替代虚无缥缈的3D坐标系统，使用二段码表达空间。
```sql
CREATE TABLE `wms_location` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `area_code` VARCHAR(16) NOT NULL COMMENT '库区，如 A区/冷藏区',
  `shelf_code` VARCHAR(16) NOT NULL COMMENT '货架及层号，如 01-03',
  `max_capacity` INT NOT NULL DEFAULT 1000 COMMENT '货位最大容量',
  `current_capacity` INT NOT NULL DEFAULT 0 COMMENT '当前存放数量'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```
页面展示时拼接成 `A-01-03`，既符合工业编码规范，又省去了前端Canvas或Three.js的庞大渲染逻辑。

### 3. 出库申请与明细表（wms_outbound & wms_outbound_detail）
单据必须走主子表设计，主表管状态机，子表管具体物料和扣减数量。
```sql
CREATE TABLE `wms_outbound` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_no` VARCHAR(32) NOT NULL UNIQUE COMMENT '出库单号',
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0-草稿, 1-已锁定/待复核, 2-已出库/已核销, 3-已作废',
  `operator` VARCHAR(32) NOT NULL COMMENT '制单人',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `wms_outbound_detail` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `outbound_id` INT NOT NULL COMMENT '出库单ID',
  `material_id` INT NOT NULL COMMENT '物料ID',
  `quantity` INT NOT NULL COMMENT '申请出库数量'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## 关键接口：基于行级排他锁的出库核销

![图：毕设无忧网站入口（www.bysj.site）](/api/blog-tasks/media/20260908-102058_仓储出入库系统拿掉3D装箱与RFID_货位二段码与行锁核销的Flask实现_ui_site.jpg)

*图：毕设无忧网站入口（www.bysj.site）*


仓储系统最怕演示现场由于鼠标多点了一下，或者不同浏览器同时点击同一物料出库，导致可用库存变成负数。在Flask中不要在内存里做校验，必须依靠MySQL的单行排他锁 `with_for_update()`。

出库核销必须分拆为两个动作：
1. **锁定单据并增加冻结库存**：创建出库单后，将物料表的 `frozen_qty` 加上申请数量，防止其他单据把这批物料抢走。
2. **物理核销并清除冻结**：现场理货完成，点击核销，`stock_qty` 与 `frozen_qty` 联动扣除，状态流转为已出库。

以下是经过简化的可运行核心逻辑：

```python
# app/routes/outbound.py
from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models import Material, OutboundOrder, OutboundDetail

outbound_bp = Blueprint('outbound', __name__)

@outbound_bp.route('/api/outbound/confirm', methods=['POST'])
def confirm_outbound():
    data = request.get_json() or {}
    order_id = data.get('order_id')
    
    if not order_id:
        return jsonify({'code': 400, 'msg': '缺少单据ID'}), 400

    try:
        # 开启显式事务控制
        with db.session.begin_nested():
            order = OutboundOrder.query.filter_by(id=order_id).with_for_update().first()
            if not order or order.status != 1:
                return jsonify({'code': 400, 'msg': '单据状态非法或未处于锁定状态'}), 400
            
            details = OutboundDetail.query.filter_by(outbound_id=order.id).all()
            
            for item in details:
                # 锁定对应的物料记录行，避免并发篡改
                mat = Material.query.filter_by(id=item.material_id).with_for_update().first()
                
                if mat.stock_qty < item.quantity:
                    raise ValueError(f'物料 {mat.material_code} 实际库存不足')
                if mat.frozen_qty < item.quantity:
                    raise ValueError(f'物料 {mat.material_code} 冻结库存异常')
                
                # 实扣物理库存与解除冻结
                mat.stock_qty -= item.quantity
                mat.frozen_qty -= item.quantity
            
            # 状态流转为已出库
            order.status = 2
            
        db.session.commit()
        return jsonify({'code': 200, 'msg': '出库核销完成'})
        
    except ValueError as val_err:
        db.session.rollback()
        return jsonify({'code': 422, 'msg': str(val_err)}), 422
    except Exception as e:
        db.session.rollback()
        return jsonify({'code': 500, 'msg': '系统异常，操作已回滚'}), 500
```

通过该接口，即使两个操作员同时核销包含相同物料的单据，后到的请求在 `with_for_update()` 处会等待锁释放；拿到锁后重新读取的数据已是更新后的数值，直接触发校验抛出异常，杜绝脏写。

## 关键页面交互与演示路径设计

答辩评审老师不会盯着三千行代码一行一行读，他们判定系统是否真实运转，靠的是**数据闭环**。演示必须按照一个不可逆的物理事件顺序进行：

1. **物料字典页面**：展示某种物料（例如：工业轴承 6204），当前初始物理库存为 100，冻结库存为 0，可用库存为 100。
2. **创建出库单（草稿状态）**：申请出库该轴承 30 套，保存后单据状态为「草稿」，物料库存数据不发生任何变动。
3. **单据锁定/审核**：点击审核，物料列表中该轴承的物理库存依然是 100，但冻结库存变为 30，此时可用库存动态变为 70。演示再开一个隐身窗口创建 80 套的出库单，系统立即提示可用库存不足阻断提交。
4. **执行物理核销**：回到原单据点击出库核销，刷新物料列表，物理库存跳变为 70，冻结库存归 0，单据状态更新为「已出库」。

四步做完，一套完备的单据生命周期就被完整印证，既没有硬件通信掉线的风险，也没有伪造假数据的痕迹。

## 两个常见实现死胡同与排查清单

在毕业设计代码收敛过程中，有两处极其耗费时间但对答辩毫无贡献的死胡同，必须直接跳过。

第一个死胡同是**试图在前端Vue里用虚拟列表展示三维货架空间**。有些开源项目用 Three.js 做了一个华丽的3D模型，但模型加载依赖数兆大小的静态模型资源。在答辩现场教室较差的投屏或网络环境下，极易出现模型贴图丢失、Canvas黑屏的情况。答辩老师追问一句「你这个货架受力形变怎么计算的」，直接当场语塞。改用 Element-Plus 简单的卡片组件，按货区聚合分组展示货位标签即可。

第二个死胡同是**在单据主表上用字符串拼接存储明细**。部分同学为了图省事，不建 `wms_outbound_detail` 子表，把所有要出库的商品ID与数量拼成一个 JSON 字符串（例如 `[{"id":1,"qty":10}]`）直接存进出库单的主表字段里。到了统计报表阶段，需要计算「本月出库总量前5的物料」时，直接陷入需要在MySQL里用正则提取字符串的泥潭。严格建明细子表，关联查询只需一条 `GROUP BY material_id` 即可完成统计。

今天晚上如果准备动工，先核对数据库是否满足上述4张表设计。建好表结构后，先不要写界面，用 Postman 调通一次带有状态锁定的出库事务。只要出库扣减逻辑闭环，毕设系统的地基就已经稳固了。

