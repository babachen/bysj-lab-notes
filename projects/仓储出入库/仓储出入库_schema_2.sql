CREATE TABLE `wms_location` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `area_code` VARCHAR(16) NOT NULL COMMENT '库区，如 A区/冷藏区',
  `shelf_code` VARCHAR(16) NOT NULL COMMENT '货架及层号，如 01-03',
  `max_capacity` INT NOT NULL DEFAULT 1000 COMMENT '货位最大容量',
  `current_capacity` INT NOT NULL DEFAULT 0 COMMENT '当前存放数量'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
