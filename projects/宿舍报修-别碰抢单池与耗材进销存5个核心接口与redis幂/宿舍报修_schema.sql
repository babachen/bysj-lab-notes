-- 1. 工单主表：严格控制状态枚举值
CREATE TABLE `repair_order` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_no` VARCHAR(32) NOT NULL COMMENT '业务单号(年月日+递增流水)',
  `student_id` BIGINT NOT NULL COMMENT '报修学生ID',
  `building_no` VARCHAR(16) NOT NULL COMMENT '楼栋如: 3号楼',
  `room_no` VARCHAR(16) NOT NULL COMMENT '宿舍号如: 402',
  `category` VARCHAR(32) NOT NULL COMMENT '类别: 水暖/电路/泥瓦/门窗',
  `description` VARCHAR(500) NOT NULL COMMENT '故障详情',
  `image_url` VARCHAR(255) DEFAULT NULL COMMENT '现场照片',
  `worker_id` BIGINT DEFAULT NULL COMMENT '被指派维修工ID',
  `status` TINYINT NOT NULL DEFAULT 10 COMMENT '10待派工, 20待维修, 30维修中, 40已完成, 50已评价',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_student_status` (`student_id`, `status`),
  KEY `idx_worker_status` (`worker_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='报修工单表';

-- 2. 节点日志表：答辩时展示流程轨迹的关键，替代复杂IM系统
CREATE TABLE `repair_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `order_id` BIGINT NOT NULL COMMENT '关联主表ID',
  `operator_id` BIGINT NOT NULL COMMENT '操作人ID',
  `operator_role` VARCHAR(16) NOT NULL COMMENT '角色: STUDENT/ADMIN/WORKER',
  `action` VARCHAR(32) NOT NULL COMMENT '动作: 提交/指派/接单/修复/评价',
  `remark` VARCHAR(255) DEFAULT NULL COMMENT '操作备注',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工单流转日志表';

-- 3. 维修工与网格分区表
CREATE TABLE `repair_worker` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(32) NOT NULL COMMENT '师傅姓名',
  `phone` VARCHAR(11) NOT NULL COMMENT '联系电话',
  `category` VARCHAR(32) NOT NULL COMMENT '负责工种',
  `assigned_zone` VARCHAR(64) NOT NULL COMMENT '负责片区如: 1-4号楼',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '1正常接单, 0休假',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='维修人员网格表';
