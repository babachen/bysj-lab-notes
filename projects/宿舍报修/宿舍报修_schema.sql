-- 1. 宿舍房源物理映射表
CREATE TABLE `dorm_room` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `building_no` varchar(16) NOT NULL COMMENT '楼栋号 如：12栋',
  `unit_no` varchar(16) DEFAULT NULL COMMENT '单元号',
  `room_no` varchar(16) NOT NULL COMMENT '房间号 如：402',
  `bed_count` int(2) DEFAULT 4 COMMENT '床位数',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_room` (`building_no`, `room_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. 报修分类表
CREATE TABLE `repair_category` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `category_name` varchar(32) NOT NULL COMMENT '类别：水暖/电路/门窗/家具',
  `priority_level` tinyint(1) DEFAULT 2 COMMENT '优先级：1紧急 2常规',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. 核心报修工单表
CREATE TABLE `repair_order` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `order_no` varchar(32) NOT NULL COMMENT '业务流水号',
  `student_id` bigint(20) NOT NULL COMMENT '报修人ID',
  `dorm_id` bigint(20) NOT NULL COMMENT '宿舍关联ID',
  `category_id` bigint(20) NOT NULL COMMENT '分类ID',
  `description` varchar(500) NOT NULL COMMENT '故障描述',
  `image_urls` varchar(1024) DEFAULT NULL COMMENT '以英文逗号分隔的本地图片相对路径',
  `status` tinyint(2) NOT NULL DEFAULT 10 COMMENT '状态: 10待派工 20维修中 30待验收 40已结单',
  `worker_id` bigint(20) DEFAULT NULL COMMENT '指派维修工ID',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_student` (`student_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. 工单流转操作日志表（状态机跳跃痕迹）
CREATE TABLE `repair_order_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `order_id` bigint(20) NOT NULL COMMENT '工单主键',
  `pre_status` tinyint(2) NOT NULL COMMENT '变更前状态',
  `post_status` tinyint(2) NOT NULL COMMENT '变更后状态',
  `operator_id` bigint(20) NOT NULL COMMENT '操作人ID',
  `remark` varchar(255) DEFAULT NULL COMMENT '流转批注或验收评价',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
