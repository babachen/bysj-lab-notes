# bysj-lab-notes

计算机毕设系统设计草稿：每个 `projects/` 文件夹对应一个「XX 系统」伪代码对照，**不是可运行仓库**，请自己实现。

<p align="center">
  <a href="https://www.bysj888.com/"><img src="assets/og-cover.png" alt="毕设无忧 bysj888.com" width="720"/></a>
</p>

<p align="center">
  <b>方法站</b>
  <a href="https://www.bysj888.com/">www.bysj888.com</a> ·
  <a href="https://www.bysj888.com/choke-points/">卡点速查</a> ·
  <a href="https://www.bysj888.com/topics/">40 题</a> ·
  <a href="https://www.bysj888.com/free-topic-check">选题自测</a>
  <br/>
  <b>案例预览</b>
  <a href="https://app.bysj.site/">app.bysj.site</a> ·
  <a href="https://www.bysj888.com/feed.xml">RSS</a>
</p>

完整选题、开题/答辩清单与卡点长文见 **[www.bysj888.com](https://www.bysj888.com/)**。  
卡在微服务 / 工期 / 查重 / 答辩时，直接打开 **[卡点速查](https://www.bysj888.com/choke-points/)**。

## 高频卡点（外链）
- [导师要微服务怎么回](https://www.bysj888.com/blog/no-microservices-for-thesis)
- [只剩 6 周怎么做](https://www.bysj888.com/blog/six-weeks-graduation-plan)
- [是不是你做的怎么答](https://www.bysj888.com/blog/prove-you-built-it)
- [查重高了怎么改](https://www.bysj888.com/blog/thesis-plagiarism-rewrite)
- [开题被打回怎么改](https://www.bysj888.com/blog/proposal-rejected-fix)
- [冲突检测怎么写](https://www.bysj888.com/blog/booking-conflict-check)

## 项目
- [外卖点餐系统](projects/外卖点餐-把可行性钉在订单快照模块边界最小表与审核流程/) — Spring Boot + Vue + Elasticsearch · 外卖毕设常卡在支付、骑手定位和搜索联调。本文用商家审核、价格快照、订单状
- [在线问诊辅助系统](projects/在线问诊辅助-先砍掉诊断与实时通信spring-boot-单库/) — Spring Boot + Vue + MySQL · 在线问诊题目容易滑向AI诊断、视频问诊和支付链路，最终难以验收。本文用角
- [快递代收管理系统](projects/快递代收管理-先用件流转和货位容量审查毕设边界/) — Django + Vue + PostgreSQL · 快递代收题目容易滑向短信、运单接口和智能柜联动。本文用件流转、货位容量与
- [社区团购系统](projects/社区团购-先算演示边界spring-boot-四表事务草稿/) — Spring Boot + Vue + MySQL · 社区团购毕设容易被团长、配送、退款和实时库存拖大。本文从选题边界出发，收
- [实验室预约系统](projects/实验室预约-选题别碰人脸门禁台位时段锁与违约记次的收敛笔记/) — Spring Boot + 小程序 + Redis · 多数实验室预约毕设卡在人脸门禁硬件联调与跨天排期死锁。本文砍掉实体门禁与
- [宿舍报修系统](projects/宿舍报修-别碰抢单池与耗材进销存5个核心接口与redis幂/) — Spring Boot + 小程序 + Redis · 多数报修系统毕设在中期崩在抢单并发锁与耗材负库存上。本文剔除抢单大厅与进
- [农业物联网监测系统](projects/农业物联网监测-农业物联网-先砍田间硬件网关模拟上报时序降采样与/) — Django + Vue + PostgreSQL · 多数农业物联网毕设死于树莓派传感器离线、校园网MQTT断连与现场插线翻车
- [毕业论文进度管理系统](projects/毕业论文进度管理-毕业论文进度-剔除在线协同与查重api四节点状态/) — Spring Boot + Vue + MySQL · 很多做进度管理毕设的学生开题就塞实时协作与第三方查重接口，中期卡在并发编
- [快递代收管理系统](projects/快递代收管理-快递代收别接硬件柜与短信网关6位取件码防碰与入库/) — Django + Vue + PostgreSQL · 很多快递代收毕设开题就写智能硬件柜联动与真实短信下发，中期卡在短信模板未
- [招聘信息发布系统](projects/招聘信息发布/) — Python Flask + Vue + MySQL · 很多招聘毕设开题就堆大模型简历初筛与爬虫抓取，中期卡在显存爆满与字段解析
- [宠物医院管理系统](projects/宠物医院管理/) — Spring Boot + Vue + MySQL · 很多宠物医院毕设卡在宠物鼻纹图像识别与WebRTC实时问诊。本文砍掉不可
- [宿舍报修系统](projects/宿舍报修/) — Spring Boot + 小程序 + Redis · 宿舍报修毕设常因硬塞师傅实时轨迹与WebSocket聊天，导致本地内存耗
- [社区养老服务系统](projects/社区养老服务/) — Spring Boot + 小程序 + Redis · 很多社区养老毕设卡在穿戴设备蓝牙丢包、跌倒检测误报与多端抢单冲突。本文把
- [仓储出入库系统](projects/仓储出入库/) — Python Flask + Vue + MySQL · 仓储毕设常因堆砌RFID硬件联动与立体库装箱算法导致单线程阻塞或表单击穿
- [景点门票预约系统](projects/景点门票预约/) — Spring Boot + Vue + Elasticsearch · 景点预约毕设常陷入高并发秒杀与ES集群死循环。本文通过真实内存撑爆死胡同
- [快递代收管理系统](projects/快递代收管理/) — Django + Vue + PostgreSQL · 多数快递代收毕设卡在商业开放平台资质审核与短信API封禁。本文剔除公网运
- [校园跑腿系统](projects/校园跑腿/) — Django + Vue + PostgreSQL · 许多校园跑腿毕设卡在校内路网缺失与接单并发冲突。本文用楼宇网格字典剔除高
- [招聘信息发布系统](projects/招聘信息发布/) — Python Flask + Vue + MySQL · 很多招聘毕设卡在简历OCR解析、爬虫封禁与复杂推荐算法。本文将系统边界收
- [酒店预约系统](projects/酒店预约/) — Spring Boot + Vue + Elasticsearch · 开题就锁 Spring Boot+Vue+ES 做酒店智能搜房，两周后空
- [外卖点餐系统](projects/外卖点餐/) — Spring Boot + Vue + Elasticsearch · 开题就把 ES 接进下单，搜得到黄焖鸡却下不了单、打烊店仍可点。先钉菜单

## 笔记

- [宿舍报修系统设计笔记：房间三元组键、工单禁跳边与完工对照槽](notes/2026-09-02-宿舍报修系统设计笔记房间三元组键工单禁跳边与完工对照槽.md)
- [社区团购系统：把审核流先画成伪代码](notes/2026-09-02-社区团购系统把审核流先画成伪代码.md)

## 关于图片

仓库内 `assets/` 来自公开封面（首页 OG 与案例图），使用**本地相对路径**，避免 GitHub 外链裂图。

| 文件 | 说明 |
| --- | --- |
| `assets/og-cover.png` | 站点首页封面 |
| `assets/cover-topic.jpg` | 选题结构 |
| `assets/cover-guide.jpg` | 推进指南 |
| `assets/cover-checklist.jpg` | 验收清单 |
| `assets/cover-java.jpg` | Java / Spring Boot |
| `assets/cover-python.jpg` | Python 方向 |

完整案例见 [www.bysj.site](https://www.bysj.site/)
