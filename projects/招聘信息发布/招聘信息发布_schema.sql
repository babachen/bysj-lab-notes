-- 1. 用户基础表（简化角色区分：1=求职者, 2=HR, 9=管理员）
CREATE TABLE `sys_user` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(64) NOT NULL UNIQUE,
  `password_hash` VARCHAR(128) NOT NULL,
  `role_type` TINYINT NOT NULL DEFAULT 1,
  `real_name` VARCHAR(32) NOT NULL,
  `phone` VARCHAR(20) NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. 结构化简历表（一人一份基础简历，避免复杂的版本分叉）
CREATE TABLE `resume` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `user_id` BIGINT NOT NULL UNIQUE,
  `job_title` VARCHAR(64) NOT NULL COMMENT '期望职位',
  `expected_salary_min` INT NOT NULL DEFAULT 0 COMMENT '单位：千元',
  `expected_salary_max` INT NOT NULL DEFAULT 0,
  `city` VARCHAR(32) NOT NULL,
  `education` VARCHAR(16) NOT NULL COMMENT '本科/硕士/大专',
  `skills_summary` TEXT COMMENT '掌握技能简述',
  `experience` TEXT COMMENT '项目/工作经历',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_resume_city_title` (`city`, `job_title`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. 岗位发布表
CREATE TABLE `job_position` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `publisher_id` BIGINT NOT NULL COMMENT '关联sys_user.id',
  `title` VARCHAR(64) NOT NULL,
  `company_name` VARCHAR(64) NOT NULL,
  `city` VARCHAR(32) NOT NULL,
  `salary_min` INT NOT NULL DEFAULT 0,
  `salary_max` INT NOT NULL DEFAULT 0,
  `education_require` VARCHAR(16) NOT NULL,
  `description` TEXT NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '1:招聘中, 0:已关闭',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_job_query` (`status`, `city`, `salary_min`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. 投递流转记录表（核心状态机）
CREATE TABLE `job_application` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `job_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL COMMENT '求职者ID',
  `resume_snapshot` JSON NOT NULL COMMENT '投递时的简历快照',
  `status` TINYINT NOT NULL DEFAULT 10 COMMENT '10:已投递, 20:初筛通过, 30:面试中, 40:已录用, 90:已淘汰',
  `reject_reason` VARCHAR(255) DEFAULT '',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_job_user` (`job_id`, `user_id`),
  INDEX `idx_hr_job` (`job_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
