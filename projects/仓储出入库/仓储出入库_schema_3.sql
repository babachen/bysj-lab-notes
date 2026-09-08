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
