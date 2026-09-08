-- 老人核心档案表
CREATE TABLE `elder_profile` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `id_card_hash` VARCHAR(64) NOT NULL COMMENT '身份证哈希，脱敏索引',
  `real_name` VARCHAR(32) NOT NULL,
  `age` INT NOT NULL,
  `grid_code` VARCHAR(16) NOT NULL COMMENT '社区网格编码，如 01-03-A',
  `care_level` TINYINT NOT NULL DEFAULT 1 COMMENT '自理等级: 1自理 2半失能 3失能',
  `emergency_phone` VARCHAR(11) NOT NULL COMMENT '紧急联络人电话',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_grid` (`grid_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 养老服务预约与核销单
CREATE TABLE `care_order` (
  `order_no` VARCHAR(32) NOT NULL,
  `elder_id` BIGINT NOT NULL,
  `service_type` TINYINT NOT NULL COMMENT '1助餐 2助洁 3上门理发 4助医',
  `reserve_date` DATE NOT NULL COMMENT '服务预约日期',
  `time_slot` TINYINT NOT NULL COMMENT '1上午 2下午',
  `order_status` TINYINT NOT NULL DEFAULT 1 COMMENT '1待服务 2已核销 3已取消 4已逾期',
  `staff_id` BIGINT DEFAULT NULL COMMENT '履约服务人员ID',
  `verify_code` VARCHAR(6) NOT NULL COMMENT '6位核销码',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`order_no`),
  UNIQUE KEY `uk_verify_code` (`verify_code`),
  KEY `idx_elder_date` (`elder_id`, `reserve_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
