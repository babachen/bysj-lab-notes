-- 岗位表：包含状态流转控制
CREATE TABLE `job_post` (
  `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
  `company_id` BIGINT NOT NULL COMMENT '发布企业ID',
  `title` VARCHAR(64) NOT NULL COMMENT '岗位名称',
  `category` VARCHAR(32) NOT NULL COMMENT '职位类别',
  `salary_min` INT NOT NULL COMMENT '最低月薪(千)',
  `salary_max` INT NOT NULL COMMENT '最高月薪(千)',
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0-待审核 1-已发布 2-已下架 3-驳回',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_cat_status` (`category`, `status`),
  INDEX `idx_company` (`company_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 投递记录表：承载投递时刻的不可变快照
CREATE TABLE `job_application` (
  `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
  `job_id` BIGINT NOT NULL COMMENT '关联岗位ID',
  `student_id` BIGINT NOT NULL COMMENT '求职者用户ID',
  `job_snapshot` JSON NOT NULL COMMENT '投递时岗位核心数据快照',
  `resume_snapshot` JSON NOT NULL COMMENT '投递时简历数据快照',
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0-已投递 1-已查阅 2-通知面试 3-不合适',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_job_student` (`job_id`, `student_id`),
  INDEX `idx_student` (`student_id`),
  INDEX `idx_job` (`job_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
