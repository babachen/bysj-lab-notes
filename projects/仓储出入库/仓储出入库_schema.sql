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
