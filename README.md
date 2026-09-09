# bysj-lab-notes

计算机毕设系统设计草稿：每个 `projects/` 文件夹对应一个「XX 系统」伪代码对照，**不是可运行仓库**，请自己实现。

<p align="center">
  <a href="https://www.bysj.site/"><img src="assets/og-cover.png" alt="www.bysj.site 首页封面" width="720"/></a>
</p>

<p align="center">
  <a href="https://www.bysj.site/">www.bysj.site</a> ·
  <a href="https://www.bysj.site/free-topic-check.html">选题自检</a>
</p>

完整选题、案例结构与自检清单见 **[www.bysj.site](https://www.bysj.site/)**。

## 项目
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

仓库内 `assets/` 来自 [www.bysj.site](https://www.bysj.site/) 公开封面（首页 OG 与案例图），使用**本地相对路径**，避免 GitHub 外链裂图。

| 文件 | 说明 |
| --- | --- |
| `assets/og-cover.png` | 站点首页封面 |
| `assets/cover-topic.jpg` | 选题结构 |
| `assets/cover-guide.jpg` | 推进指南 |
| `assets/cover-checklist.jpg` | 验收清单 |
| `assets/cover-java.jpg` | Java / Spring Boot |
| `assets/cover-python.jpg` | Python 方向 |
