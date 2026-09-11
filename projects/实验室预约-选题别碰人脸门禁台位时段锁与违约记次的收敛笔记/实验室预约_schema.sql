-- 1. 实验室台位基础表
CREATE TABLE `lab_seat` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `room_no` VARCHAR(16) NOT NULL COMMENT '如: 计机南402',
  `seat_no` VARCHAR(16) NOT NULL COMMENT '如: A-01',
  `status` TINYINT DEFAULT 1 COMMENT '1可用 0维修中',
  UNIQUE KEY `uk_room_seat` (`room_no`, `seat_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. 预约订单表（靠唯一索引锁死时段）
CREATE TABLE `lab_reservation` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `user_id` BIGINT NOT NULL,
  `seat_id` BIGINT NOT NULL,
  `slot_date` DATE NOT NULL COMMENT '预约日期',
  `slot_index` TINYINT NOT NULL COMMENT '1:上午, 2:下午, 3:晚上',
  `checkin_code` VARCHAR(8) DEFAULT NULL COMMENT '6位随机签到码',
  `status` TINYINT DEFAULT 0 COMMENT '0待核销 1已签到 2已爽约 3已取消',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_seat_slot` (`seat_id`, `slot_date`, `slot_index`),
  KEY `idx_user_status` (`user_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. 违约失信记录表
CREATE TABLE `lab_punishment` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `user_id` BIGINT NOT NULL,
  `reason` VARCHAR(64) NOT NULL,
  `expire_time` DATETIME NOT NULL COMMENT '惩罚结束时间',
  KEY `idx_user_expire` (`user_id`, `expire_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
