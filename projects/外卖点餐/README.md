# 外卖点餐系统

> 对照草稿，不是可运行工程。完整案例见 [www.bysj.site](https://www.bysj.site/)

> 技术栈：Spring Boot + Vue + Elasticsearch
> 开题就把 ES 接进下单，搜得到黄焖鸡却下不了单、打烊店仍可点。先钉菜单权威源、配送半径冻结、库存快照，再对照四栈看一人八周能不能交卷。

## 本目录文件

- `外卖点餐_flow.pseudo`
- `外卖点餐_flow_2.pseudo`
- `外卖点餐Service.java`

## 说明

- 伪代码只描述主路径，表结构/状态机请自己落库实现。
- 禁止把本目录当作业直接提交。
- 选题边界与可演示清单： [www.bysj.site](https://www.bysj.site/)

## 原文摘要

# 外卖点餐开题先拆搜索主链路：菜单权威源、半径冻结窗、下单库存快照

> 开题就把 ES 接进下单，搜得到黄焖鸡却下不了单、打烊店仍可点。先钉菜单权威源、配送半径冻结、库存快照，再对照四栈看一人八周能不能交卷。
> 示例系统：外卖点餐系统
> tags: 毕设选题, 可行性评估, 外卖点餐系统, SpringBoot, Elasticsearch, 模块拆分

开题第三天就把 Elasticsearch 接进 Spring Boot。题目写的是「智能外卖点餐」，栈锁定 Spring Boot + Vue + ES。商家菜单还在微信压缩图里，配送范围是口头「三公里」，库存字段没进表。第二周联调：搜得到「黄焖鸡」，下单接口 500；同一店两份菜单价差 4 元；21:10 店铺已打烊，搜索页仍显示可点。

这不是检索没调好。是选题边界没钉死，技术先堆上去了。

**我的判断：一人八周的外卖点餐毕设，Elasticsearch 不该出现在下单主链路。** 你可以不同意。判断不成立的条件很具体：你已有稳定的日更菜单流水、SKU 过万、论文贡献就是检索相关性，并且演示当天能重放同一份索引。本科常见规模是 1～3 家店、每店 40～80 个 SKU、数据手搓。这时 ES 只会让你在分词、映射和同步上烧掉两周，主链路仍然下不了单。

## 三闸门：过不了就别写智能搜索

先问三件事，再谈 Vue 页面和 ES 分词。

1. 菜单权威源是谁？店员改价以哪张表为准，微信图只许当附件。
2. 配送半径何时冻结？下单瞬间用哪份坐标、哪份半径，超时谁负责。
3. 库存以什么为快照？扣减发生在创建订单事务内，还是搜到有货就算有货。

三问里有一问答成「到时候再说」，这题对一人八周过宽。搜索可以后置成只读副本，甚至开题里写成「MySQL LIKE + 后续可替换」，不要写进下单事务。

| 闸门 | 过关标准（可写进开题） | 否决信号 |
| --- | --- | --- |
| 菜单权威源 | `sku` 表有 shop_id+sku_code 唯一键，价格只改这张表 | 菜单靠相册/Excel 覆盖，无变更时间 |
| 半径冻结窗 | 下单写入 user_lat/lng、shop_lat/lng、radius_m、frozen_at | 前端按直线距离自己算，服务端不存 |
| 下单库存快照 | 订单行记下 qty 与 stock_before，扣减与订单同事务 | 搜索聚合「有货」当库存 |

## 模块拆分（搜索不进下单）

按数据所有权拆，不按「前后端」拆。

- **catalog**：店铺、SKU、营业日历。唯一写入口。
- **geo**：店铺坐标、半径、冻结快照。只在下单读一次并落库。
- **order**：订单头、订单行、状态机。禁跳边。
- **search-replica（可选）**：从 catalog 异步投影，失败不影响下单。

数据流就一条：浏览（可走副本）→ 结算校验（必须走权威表）→ 创建订单（事务内扣库存）→ 状态推进。ES 若存在，只挂在浏览。

死胡同我走过：第二周用 Canal 每 30 秒把 `sku` 灌进 ES 7.17（单机、8G 内存开发机）。商家用 Excel 整表覆盖，主键漂移，映射字段从 12 个涨到 40 个，查询延迟从 20ms 晃到 800ms+。停手是因为演示主路径「加购物车」仍然读到旧价。下次直接跳过 CDC，开题写明搜索副本可空，主链路只打 MySQL。

## 最小表结构（对照清单，不是建库脚本）

```text
shop(id, name, lat, lng, radius_m, open_time, close_time, status)
sku(id, shop_id, sku_code, name, price_cent, stock_qty, updated_at)
  UNIQUE(shop_id, sku_code)
order_head(id, user_id, shop_id, status, user_lat, user_lng,
           radius_m, frozen_at, pay_cent, created_at)
order_item(id, order_id, sku_id, qty, price_cent, stock_before)
```

状态只许：`CREATED → PAID → ACCEPTED → DELIVERING → DONE`，或 `CREATED/PAID → CANCELED`。禁止 `CREATED → DONE`，禁止已取消再付款。这张禁跳边比任何「智能调度」都先写进论文第三章。

## 核心用例：创建订单（伪代码，示意草稿）

读者应自己实现事务与锁；下面不能当作业提交。

```pseudo
function create_order(user, shop_id, items, user_lat, user_lng, now):
  shop = catalog.get_shop(shop_id)          // 权威源
  if shop.status != OPEN: fail("店铺不可下单")
  if not within_hours(shop.open_time, shop.close_time, now): fail("非营业时间")
  dist = haversine(user_lat, user_lng, shop.lat, shop.lng)
  if dist > shop.radius_m: fail("超出配送半径")

  begin_tx:
    lock sku rows for update where id in items.sku_ids
    snapshot_radius = {user_lat, user_lng, shop.lat, shop.lng, shop.radius_m, now}
    lines = []
    pay = 0
    for it in items:
      sku = catalog.get_sku(shop_id, it.sku_code)
      if sku.stock_qty < it.qty: fail("库存不足")
      lines.append({sku, qty: it.qty, price: sku.price_cent, stock_before: sku.stock_qty})
      sku.stock_qty -= it.qty
      pay += sku.price_cent * it.qty
    order = insert order_head(CREATED, snapshot_radius, pay)
    insert order_item(lines)
  commit
  enqueue search_replica.invalidate(shop_id)  // 失败忽略
  return order
```

半径计算不要信任前端传来的 `inRange=true`。下面这段 Java 只是距离校验草稿，未处理椭球精度，不能当生产代码。

```java
// 示意草稿：赤道近似，半径与坐标必须写入订单行
static boolean inRadius(double uLat, double uLng, double sLat, double sLng, int radiusM) {
  double r = 6371000.0;
  double dLat = Math.toRadians(sLat - uLat);
  double dLng = Math.toRadians(sLng - uLng);
  double a = Math.sin(dLat/2)*Math.sin(dLat/2)
      + Math.cos(Math.toRadians(uLat))*Math.cos(Math.toRadians(sLat))
      * Math.sin(dLng/2)*Math.sin(dLng/2);
  double meters = 2 * r * Math.asin(Math.sqrt(a));
  return meters <= radiusM;
}
```

## 四周可行性（一人、课余，按 8 周倒推）

按顺序打分，不要并行「先把 ES 跑起来」。

1. 第 1 周只做 catalog + 营业日历 + 三张表，手填 2 家店共 60 个 SKU。能改价、能打烊。
2. 第 2 周只做创建订单伪代码落地：半径冻结、库存行锁、状态禁跳。演示脚本：超半径失败、超卖失败、打烊失败。
3. 第 3 周 Vue 结算页只读权威接口，不读搜索命中文档里的价格。
4. 第 4 周才决定搜索要不要做。60 个 SKU 用 MySQL `LIKE` 足够答辩；要写 ES，必须单独一节「只读副本」，并准备副本挂掉时主链路仍可下单。

| 栈 | 一人八周（课余约 10～12h/周） | 适合挂在哪一层 |
| --- | --- | --- |
| Spring Boot + MySQL | 主链路：下单事务、行锁、状态机 | catalog / order |
| Vue | 结算与失败码展示，不存价格 | 读权威 API |
| Elasticsearch | 可选副本；60 SKU 可整段删 | 浏览，禁止写库存 |
| 爬虫/微信菜单导入 | 默认移出开题 | 权威源未定时不要碰 |

论文图表按这个切：图 1 模块与数据流（搜索画虚线）；图 2 状态禁跳边；表 1 三次失败用例（半径/库存/营业时间）。没有这三张图，功能再多答辩也讲成「做了个淘宝」。

边界收紧后，题目可以叫「校园外卖点餐：带半径冻结与库存快照的下单系统」。智能推荐、骑手调度、多店满减叠券，全部降成「未实现，见展望」。展望能写，主链路不能靠它演示。

对照清单用完就停。按三闸门过一遍，过不了就换题或砍 ES，不要在同步管道里加功能。

---

## 相关资料

同类问题里，最常见的不是「不会写某段代码」，而是边界没钉死。下面两张图是公开资料里的结构示意，适合贴在笔记本旁边对照（非代写、不包过）。

![Java 方向项目封面](https://www.bysj.site/blog/img/cover-java.jpg)

*Java / Spring Boot 方向可参考站点案例结构*

![Python 方向项目封面](https://www.bysj.site/blog/img/cover-python.jpg)

*Python 数据分析 / 小系统方向同样适用*

完整案例与选题自检：[www.bysj.site](https://www.bysj.site/) · [选题自检](https://www.bysj.site/free-topic-check.html)

仓库里只放设计草稿和伪代码，完整实现请对照站点案例自己完成。

