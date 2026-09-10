-- 1. 用户基础表（学生/导师/管理员）
CREATE TABLE `sys_user` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `work_no` VARCHAR(32) NOT NULL UNIQUE COMMENT '学号或工号',
  `real_name` VARCHAR(32) NOT NULL COMMENT '姓名',
  `role` VARCHAR(16) NOT NULL COMMENT 'STUDENT/TEACHER/ADMIN',
  `phone` VARCHAR(11) DEFAULT NULL,
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. 论文档案与选题分配表
CREATE TABLE `topic` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(128) NOT NULL COMMENT '论文题目',
  `student_id` BIGINT NOT NULL UNIQUE COMMENT '学生ID(一对一)',
  `advisor_id` BIGINT NOT NULL COMMENT '指导教师ID',
  `academic_year` VARCHAR(9) NOT NULL COMMENT '例如 2025-2026',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  INDEX `idx_advisor` (`advisor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. 阶段提交明细表（存储每个节点的物料与状态）
CREATE TABLE `milestone_submission` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `student_id` BIGINT NOT NULL,
  `phase_code` VARCHAR(16) NOT NULL COMMENT 'PROPOSAL/MID_TERM/FINAL_PAPER',
  `version_no` INT NOT NULL DEFAULT 1 COMMENT '第几次修改版本',
  `file_url` VARCHAR(255) NOT NULL COMMENT '阶段文档MinIO或本地相对路径',
  `plagiarism_rate` DECIMAL(4,2) DEFAULT NULL COMMENT '查重率百分比，如 12.50',
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0待提交 1待审核 2驳回 3通过',
  `submit_time` DATETIME DEFAULT NULL,
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_student_phase_version` (`student_id`, `phase_code`, `version_no`),
  INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. 导师评审记录台账（防篡改审计轨迹）
CREATE TABLE `review_log` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `submission_id` BIGINT NOT NULL COMMENT '关联阶段记录ID',
  `reviewer_id` BIGINT NOT NULL COMMENT '评审教师ID',
  `review_action` VARCHAR(16) NOT NULL COMMENT 'PASS / REJECT',
  `score` INT DEFAULT NULL COMMENT '阶段评分(百分制)',
  `comment` VARCHAR(500) NOT NULL COMMENT '评审意见',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_sub_id` (`submission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
