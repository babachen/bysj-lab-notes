-- 医生时段排班与号源配额表
CREATE TABLE `doctor_schedule` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `doctor_id` BIGINT NOT NULL,
  `work_date` DATE NOT NULL,
  `time_slot` TINYINT NOT NULL COMMENT '1:上午 2:下午',
  `total_quota` INT NOT NULL DEFAULT 10,
  `used_quota` INT NOT NULL DEFAULT 0,
  `version` INT NOT NULL DEFAULT 0,
  UNIQUE KEY `uk_doctor_slot` (`doctor_id`, `work_date`, `time_slot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 预约挂号单据表
CREATE TABLE `appointment_order` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `order_no` VARCHAR(32) NOT NULL UNIQUE,
  `pet_chip_id` VARCHAR(64) NOT NULL COMMENT '宠物芯片号',
  `doctor_id` BIGINT NOT NULL,
  `schedule_id` BIGINT NOT NULL,
  `status` TINYINT NOT NULL COMMENT '1:已预约 2:已接诊 3:已取消 4:已完结',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 就诊病历与处方明细表
CREATE TABLE `medical_record` (
  `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `appointment_id` BIGINT NOT NULL UNIQUE,
  `diagnosis_result` VARCHAR(500) NOT NULL,
  `treatment_plan` TEXT NOT NULL,
  `created_by` BIGINT NOT NULL COMMENT '接诊医生ID',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
