# 酒店预约系统

[![www.bysj.site](../../assets/og-cover.png)](https://www.bysj.site/)

> 对照草稿，不是可运行工程。完整案例见 [www.bysj.site](https://www.bysj.site/)

> 技术栈：Spring Boot + Vue + Elasticsearch
> 开题就锁 Spring Boot+Vue+ES 做酒店智能搜房，两周后空房在 Excel、占房靠微信留、入住无对照。先钉日房态真源、占房冻结窗、入住对照槽，再判一人八周能否交卷。

## 本目录文件

- `酒店预约_flow.pseudo`
- `OccupancyHoldService.java`
- `leftover_or_none.py`

## 说明

- 伪代码只描述主路径，表结构/状态机请自己落库实现。
- 禁止把本目录当作业直接提交。
- 选题边界与可演示清单： [www.bysj.site](https://www.bysj.site/)

### 站点封面（仓库本地 assets）

![选题结构](../../assets/cover-topic.jpg)

![Java / Spring Boot](../../assets/cover-java.jpg)

## 原文摘要

> 开题就锁 Spring Boot+Vue+ES 做酒店智能搜房，两周后空房在 Excel、占房靠微信留、入住无对照。先钉日房态真源、占房冻结窗、入住对照槽，再判一人八周能否交卷。
> 示例系统：酒店预约系统
> tags: 酒店预约, 毕设选题, 可行性评估, 房态日历, Spring Boot, GitHub草稿

仓库对照草稿，不是可运行工程。表、伪代码、Java/Python 片段只用来卡住边界；实现和论文自己写，禁止当作业成品交。

开题第三天任务书已经写上 Elasticsearch「智能搜房」。演示搜「海景大床」能出三条，点预订提示无房——空房数还在前台按日期填的 Excel 里。

## 先否决题目，再写技术栈

Spring Boot + Vue + ES 可以后填。先回答三问，答不上就把「智能搜房」从题目划掉。

1. 日房态谁说了算？前台表、渠道后台，还是你库里唯一的按日剩余？
2. 点预订到付定金之间，该夜凭什么不被第二人抢走？冻结多久、谁释放？
3. 入住拿什么对照预约单？口头房号，还是单号加证件后四位？

我的判断：酒店预约里搜索不是主链路。一人八周、又没有可改的 PMS 接口时，把 ES 写进开题等于给错误库存加一条更快的管道。你可以不同意——学院强制检索模块、且你能完全控制一份日房态 API 时，ES 可以挂查询，但 leftover 仍只能走日历表。

| 闸门 | 过了做什么 | 过不了降成 |
| --- | --- | --- |
| 日房态真源 | `occupancy_day` 为唯一剩余量 | 静态房型页 + 人工回访确认单 |
| 占房冻结窗 | 下单事务内扣减，超时释放 | 留言预约，系统不承诺留房 |
| 入住对照槽 | 入住必须绑定预约单 | 前台手填登记，系统只展示 |

条件数字：一人八周；本机 JDK 17 + Spring Boot 2.7；演示 1 家酒店、8 个房型、14 天日历。ES 7.x 若要用，放查询投影，不进开题必做。

## 按责任切模块，不要按四件套切

- `identity`：客人 / 前台 / 管理员
- `catalog`：酒店、房型、设施标签（以后再投影到搜索）
- `occupancy`：按日剩余 + 版本号
- `reservation`：预约状态机 + 冻结截止
- `stay`：入住/离店对照；无单不准改库存
- `search-index`（可选、后置）：只读投影，允许落后，禁止写 leftover

死胡同：第一周把房型 JSON 灌进本机 Docker ES 7.17 单节点，按「海景」「含早」聚合 20ms 内返回。停，是因为两次并发 POST 都读到 leftover=1，两单都 201。下次开题跳过索引，先做「同一房型同一住日」行锁或 `version` 更新。

## 最小表（示意，自己建库）

MySQL 8.0 单库；演示窗口 14 天；不接真实 OTA。

| 表 | 关键列 | 硬约束 |
| --- | --- | --- |
| occupancy_day | hotel_id, room_type_id, stay_date, leftover, version | 唯一键三项；leftover≥0 |
| reservation | guest_id, room_type_id, check_in, check_out, status, hold_until | 状态只走草稿/占房中/已确认/已入住/已取消/已关闭 |
| stay_check | reservation_id, id_tail, actual_in_at | 一单至多一条有效入住 |

禁跳边：占房中→已确认；已确认→已入住（对照槽写入后）；取消只从占房中或已确认来。已入住改回已确认，答辩会被问夜审后谁动的库存。ES document 不当 leftover。

## 核心用例：创建预约并占房

示意草稿，不是可跑片段。事务、鉴权、日期校验自己补。

```pseudo
function createReservation(guest, roomTypeId, inDate, outDate, now):
  nights = eachDate(inDate, outDate)  // 不含退房日
  if nights empty: reject
  begin tx
    rows = lockOccupancy(roomTypeId, nights)  // SELECT ... FOR UPDATE
    if any leftover < 1: rollback; reject "该夜已满"
    for r in rows:
      r.leftover -= 1
      r.version += 1
    res = insert reservation(status=HOLD, hold_until=now+15min)
    commit
  return res
```

释放：扫 `HOLD && hold_until < now`，对应夜 leftover+1。入住走 `stay_check`，对不上单号就不动日历。

开题前两周只做下面这串，做不完就降级题目：

1. 手填 14 天日历，写死 leftover，禁止 ES。
2. 单测：同一住日 leftover=1，并发两单只成功一单。
3. 超时释放能把 leftover 加回，演示可复现。
4. 入住接口必须带 reservation_id，失败不改房态。
5. 过了再投影房型到 ES；查询命中必须回源日历。

## 对照文件（各段草稿，自己实现）

`OccupancyHoldService.java` — 示意，不可粘进提交包。

```java
// 示意草稿，非可运行工程。锁与事务隔离级别自行定。
@Service
public class OccupancyHoldService {
  @Transactional
  public long hold(long guestId, long roomTypeId,
                   LocalDate in, LocalDate out, Instant now) {
    List<LocalDate> nights = in.datesUntil(out).toList();
    if (nights.isEmpty()) throw new IllegalArgumentException("empty stay");
    List<OccupancyDay> rows = occupancyRepo.lockDays(roomTypeId, nights);
    if (rows.size() != nights.size()) throw new IllegalStateException("calendar hole");
    for (OccupancyDay r : rows) {
      if (r.getLeftover() < 1) throw new IllegalStateException("sold out");
      r.setLeftover(r.getLeftover() - 1);
      r.setVersion(r.getVersion() + 1);
    }
    occupancyRepo.saveAll(rows);
    Reservation res = new Reservation();
    res.setGuestId(guestId);
    res.setRoomTypeId(roomTypeId);
    res.setCheckIn(in);
    res.setCheckOut(out);
    res.setStatus("HOLD");
    res.setHoldUntil(now.plusSeconds(15 * 60));
    return reservationRepo.save(res).getId();
  }
}
```

`occupancy_mapper.py` — 对照查询，不是 ORM 成品。

```python
# 示意草稿：按日剩余必须回源。禁止从 ES hits 读 leftover。
def leftover_or_none(conn, room_type_id, nights):
    sql = """
      SELECT stay_date, leftover, version
      FROM occupancy_day
      WHERE room_type_id=%s AND stay_date IN (%s)
      FOR UPDATE
    """
    rows = conn.execute(sql, room_type_id, nights).fetchall()
    if len(rows) != len(nights):
        return None  # 日历有洞，拒绝下单
    if any(r.leftover < 1 for r in rows):
        return None
    return rows
```

Vue 先走 REST 房型列表。搜索框等日历单测过了再接。开题不要写死「智能推荐附近酒店」——那是另一道真源题。

三闸过不了：题目降成「房型展示 + 预约申请单」，前台人工确认。仍可答辩，只是没有智能搜房。论文能写占房与库存同一事务、冻结超时、入住对照、状态禁跳；不能写「用 ES 解决超售」。超售是日历并发，不是分词。

---

## 写在最后

上面这条路径如果帮你把范围收小了，不妨把「选题边界 / 模块拆分 / 答辩怎么讲」也当成可复查的清单来用。我自己对照公开案例时，会顺手打开下面两张结构图做备忘。

![计算机毕设选题思路封面](../../assets/cover-topic.jpg)

*选题卡住时，先把题目边界和可演示路径想清楚*

![毕设项目推进指南封面](../../assets/cover-guide.jpg)

*从环境、模块拆分到答辩叙事，按清单推进更稳*

完整案例与选题自检：[www.bysj.site](https://www.bysj.site/) · [选题自检](https://www.bysj.site/free-topic-check.html)

仓库里只放设计草稿和伪代码，完整实现请对照站点案例自己完成。

